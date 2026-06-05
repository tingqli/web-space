# ROCDL.COS BF16 Support Test Results

## Summary

**BF16 is NOT supported for `rocdl.cos` on this backend (gfx942/MI300X)**

While the MLIR layer accepts BF16 due to the generic `LLVM_AnyFloat` type constraint, the AMDGPU code generator (DAG ISel) cannot generate an instruction for bf16 cos operations.

## Test Case

```mlir
module {
  llvm.func @test_cos_bf16(%arg0: bf16) -> bf16 {
    %result = rocdl.cos %arg0 bf16 -> bf16
    llvm.return %result : bf16
  }
}
```

## Compilation Output

### Step 1: MLIR → LLVM IR
✓ **Success** - MLIR translates to LLVM IR without error

Generated LLVM IR includes:
- BF16 type in function signature
- `call bf16 @llvm.amdgcn.cos(bf16 %arg0)` intrinsic

### Step 2: LLVM IR → AMDGPU Assembly  
✗ **FAILED** - Code generation cannot select instruction for BF16 cos

Error message:
```
LLVM ERROR: Cannot select: t9: bf16 = AMDGPUISD::COS_HW
  t2: bf16,ch = CopyFromReg
```

## Root Cause Analysis

### Layer 1: MLIR ROCDL Type System ✓
- `rocdl.cos` defined with `ROCDL_Math_IntrOp` template
- Arguments typed as `LLVM_AnyFloat` (which includes bf16)
- **Result**: MLIR syntax is valid, type checker passes

**Location**: `/root/tingqli/llvm-project/mlir_install/include/mlir/Dialect/LLVMIR/ROCDLOps.td:2981-3002`

### Layer 2: MLIR → LLVM Lowering ✓
- Converts `rocdl.cos` to `llvm.call amdgcn_cos` intrinsic
- Preserves BF16 type through lowering
- **Result**: LLVM IR is generated successfully

**Location**: `/root/tingqli/llvm-project/mlir_install/include/mlir/Dialect/LLVMIR/ROCDLConversions.inc:1-4`

### Layer 3: LLVM IR → AMDGPU Selection ✗
- Backend attempts to select `AMDGPUISD::COS_HW` for bf16
- **No instruction pattern exists** for bf16 cos in the ISA
- Requires pattern matching in `AmdgpuInstrInfo.td`
- **Result**: Code generation fails

**Expected patterns that would work**: 
- `v_cos_f32 v_reg, v_reg` (f32 only)
- `v_cos_f16 v_reg, v_reg` (f16 only)
- No `v_cos_bf8` or `v_cos_bf16` equivalent

## Supported Types for rocdl.cos

Based on this test and AMDGPU ISA:

| Type | Support | Instruction |
|------|---------|-------------|
| f32 | ✓ Yes | v_cos_f32 |
| f16 | ✓ Yes | v_cos_f16 |
| bf16 | ✗ **No** | ❌ Not available |
| f64 | ? | (likely requires fdiv/mul soft-float) |

## Workaround

If bf16 cos is needed, convert to f32, compute, then convert back:

```mlir
module {
  llvm.func @test_cos_bf16_workaround(%arg0: bf16) -> bf16 {
    // bf16 -> f32
    %f32_val = arith.extf %arg0 : bf16 to f32
    
    // Compute cos in f32
    %cos_f32 = rocdl.cos %f32_val f32 -> f32
    
    // f32 -> bf16
    %result = arith.truncf %cos_f32 : f32 to bf16
    
    llvm.return %result : bf16
  }
}
```

This approach:
1. Uses `v_cvt_f32_bf8` or similar conversion (hardware supported)
2. Uses `v_cos_f32` (standard instruction)
3. Uses reverse conversion back to bf16
4. Involves precision loss but is the only way to get bf16 cos

## Key Finding

**The discrepancy exists because**:

- ROCDL dialect in MLIR uses `LLVM_AnyFloat` as a permissive type constraint
- This constraint includes all LLVM-compatible float types (f16, bf16, f32, f64, fp128 ext)
- But not all float types have corresponding hardware instructions on AMDGPU
- AMDGPU only has cos for f32 and f16, with bf16 being math-in-software-only

**Why isn't this caught earlier?**
- The type constraint is correct per LLVM dialect semantics
- The intrinsic mapping (`llvm.amdgcn.cos`) accepts `anyfloat` per LLVM IR spec
- The limitation is backend-specific (AMDGPU ISA doesn't have bf16 cos)

## Recommendations

1. **For kernel writers**: Use f32 cos, not bf16 cos
2. **For MLIR dialect designers**: Consider adding bf16-specific trait or separate operation
3. **For LLVM backend**: Could add bf16 cos via conversion + f32 compute + reverse conversion automatically

## Generated Files

- `test_cos_bf16.mlir` - Input test case (syntax valid)
- `test_cos_bf16.ll` - Lowered LLVM IR (successfully generated)
- `test_cos_bf16.asm` - Assembly output (generation failed)

Run: `./compile.sh`
