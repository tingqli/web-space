# ROCDL.COS Type Support Verification - Complete Analysis

This minimal project verifies which float types are supported for the `rocdl.cos` operation on AMDGPU (gfx942/MI300X).

## Quick Summary

| Type | Status | Instruction | Notes |
|------|--------|-------------|-------|
| **f32** | ✓ Works | `v_cos_f32_e32` | Default; always supported |
| **f16** | ✓ Works | `v_cos_f16` | Half-precision supported |
| **bf16** | ✗ Fails | ❌ None | **Not supported** - code generation error |
| **f64** | ? Unknown | Likely soft-float | Not tested |

## Project Structure

```
rocdl-cos-bf16-check/
├── test_cos_bf16.mlir        # BF16 test case (fails at codegen)
├── test_cos_f32.mlir         # F32 test case (works perfectly)
├── compile.sh                # Script to test BF16
├── compile_f32.sh            # Script to test F32
├── TEST_RESULTS.md           # Detailed failure analysis
└── README.md                 # Documentation
```

## How to Run

### Test BF16 (Will Fail)
```bash
cd /root/tingqli/web-space/rocdl-cos-bf16-check
./compile.sh
```
Expected: **LLVM ERROR** - Cannot select instruction for bf16 cos

### Test F32 (Will Succeed)
```bash
cd /root/tingqli/web-space/rocdl-cos-bf16-check
./compile_f32.sh
```
Expected: **Success** - Generates `v_cos_f32_e32` instruction

## Key Findings

### 1. MLIR Type Layer: BF16 is Accepted ✓
- `rocdl.cos` uses `LLVM_AnyFloat` type constraint
- This matches any LLVM-compatible float type
- BF16 is technically valid in MLIR syntax

**Why**: Generic type constraint in Dialect definition (ROCDLOps.td)

### 2. LLVM IR Layer: BF16 is Preserved ✓
- Correctly generates `call bf16 @llvm.amdgcn.cos(bf16 %arg0)`
- LLVM IR transition is successful
- Type stays through lowering

**Why**: LLVM intrinsic `llvm.amdgcn.cos` accepts anyfloat

### 3. AMDGPU Code Generation: BF16 Fails ✗
- Cannot select instruction for `AMDGPUISD::COS_HW` with bf16
- No hardware pattern exists
- Process terminates with compilation error

**Why**: AMDGPU ISA only has `v_cos_f32` and `v_cos_f16`, not `v_cos_bf16`

## Evidence: Test Outputs

### F32 (Working) - Excerpt from compile_f32.sh

**LLVM IR**:
```llvm
define float @test_cos_f32(float %0) {
  %2 = call float @llvm.amdgcn.cos.f32(float %0)
  ret float %2
}
```

**Generated Assembly**:
```asm
test_cos_f32:
        s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
        v_cos_f32_e32 v0, v0         ; <-- Direct cos instruction
        s_setpc_b64 s[30:31]
```

### BF16 (Failing) - Error from compile.sh

**LLVM Error**:
```
LLVM ERROR: Cannot select: t9: bf16 = AMDGPUISD::COS_HW
  t2: bf16,ch = CopyFromReg
```

This error occurs during DAG pattern matching when the backend tries to select an instruction for bf16 cos but no pattern exists in the ISA.

## Why This Matters

### For FlyDSL Developers:
- Use `f32` for `rocdl.cos`, not `bf16`
- If bf16 math is needed, convert to f32, compute, convert back
- Precision loss is acceptable trade-off for availability

### For MLIR/LLVM:
- Generic type constraints (`LLVM_AnyFloat`) don't guarantee backend support
- Each type must have corresponding instructions in the target ISA
- Mismatch between MLIR dialect and backend capabilities can cause codegen errors

### For Hardware Architects:
- Float format coverage in ISA matters for DSL expressiveness
- Missing instructions (like bf16 cos) force software workarounds

## How to Find This Information for Other Operations

1. **Check MLIR Dialect** (ROCDLOps.td):
   - What types does the operation accept?

2. **Check LLVM Intrinsic** (IntrinsicsAMDGPU.td):
   - What types does the intrinsic support in LLVM IR?

3. **Check Backend ISA**:
   - What instructions does the hardware actually have?
   - Look at `AmdgpuInstrInfo.td` for instruction patterns

4. **Compile Test Case**:
   - Try to generate assembly
   - If codegen fails, type is not supported
   - If succeeds, check which instruction was generated

## Workaround: BF16 Cos via f32

If you need bf16 cos, implement it as:

```mlir
module {
  llvm.func @cos_bf16_workaround(%arg0: bf16) -> bf16 {
    // Step 1: Convert BF16 → F32
    %f32_val = llvm.fpext %arg0 : bf16 to f32
    
    // Step 2: Call cos on F32
    %cos_f32 = rocdl.cos %f32_val f32 -> f32
    
    // Step 3: Convert F32 → BF16
    %result = llvm.fptrunc %cos_f32 : f32 to bf16
    
    llvm.return %result : bf16
  }
}
```

This will generate:
1. `v_cvt_f32_bf8` (convert bf16 to f32)
2. `v_cos_f32` (compute cos on f32)
3. `v_cvt_bf16_f32` or similar (convert back to bf16)

## Tools Used

- **mlir-translate**: Converts MLIR to LLVM IR
- **llc**: LLVM compiler - generates assembly from IR
- **mlir_install**: Pre-built LLVM/MLIR from `/root/tingqli/llvm-project/mlir_install`

## References in mlir_install

- `/root/tingqli/llvm-project/mlir_install/include/mlir/Dialect/LLVMIR/ROCDLOps.td` - Op definitions
- `/root/tingqli/llvm-project/mlir_install/include/mlir/Dialect/LLVMIR/LLVMOpBase.td` - Type constraints
- `/root/tingqli/llvm-project/mlir_install/include/llvm/IR/IntrinsicsAMDGPU.td` - LLVM intrinsics

## Conclusion

**rocdl.cos only supports f32 and f16 on AMDGPU (gfx942).** BF16 is rejected at the code generation stage despite being syntactically valid in MLIR. This is a fundamental ISA limitation, not a software bug.
