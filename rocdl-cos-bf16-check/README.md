# rocdl.cos Type Support Verification

Minimal project to verify which float types are supported for `rocdl.cos` on AMDGPU (gfx942/MI300X), using mlir_install.

## Quick Start

### Test BF16 (Expected to Fail)
```bash
chmod +x compile.sh && ./compile.sh
```
**Result**: LLVM ERROR - Cannot select instruction for bf16
```
LLVM ERROR: Cannot select: t9: bf16 = AMDGPUISD::COS_HW
```

### Test F32 (Expected to Succeed)
```bash
chmod +x compile_f32.sh && ./compile_f32.sh
```
**Result**: Successfully generates `v_cos_f32_e32` instruction

## Key Findings

| Type | Works? | Notes |
|------|--------|-------|
| f32 | ✓ Yes | Standard floating-point |
| f16 | ✓ Yes | Half-precision supported |
| **bf16** | ✗ **No** | **Not supported by AMDGPU ISA** |

## How It Works

The compilation process goes through 3 stages:

1. **MLIR → LLVM IR** (✓ Always works)
   - ROCDL accepts bf16 due to generic `LLVM_AnyFloat` type constraint
   - Generates: `call bf16 @llvm.amdgcn.cos(bf16 %arg0)`

2. **LLVM IR → AMDGPU Assembly** (✗ Fails for bf16)
   - Backend attempts to find instruction pattern
   - `v_cos_f32` exists, `v_cos_bf16` does NOT exist
   - Code generation aborts

## Files

- **test_cos_bf16.mlir** - BF16 test (valid MLIR, fails at codegen)
- **test_cos_f32.mlir** - F32 test (works end-to-end)
- **compile.sh** - Test BF16 compilation
- **compile_f32.sh** - Test F32 compilation (reference)
- **ANALYSIS.md** - Detailed technical analysis
- **TEST_RESULTS.md** - Failure breakdown and workarounds

## Workaround: BF16 Cos via F32 Conversion

If you need bf16 cos:

```mlir
%f32_val = llvm.fpext %bf16_val : bf16 to f32
%cos_f32 = rocdl.cos %f32_val f32 -> f32
%result = llvm.fptrunc %cos_f32 : f32 to bf16
```

This performs:
1. bf16→f32 conversion (hardware instruction)
2. cos on f32 (v_cos_f32)
3. f32→bf16 conversion (hardware instruction)

## Generated Assembly Examples

### F32 (Working)
```asm
v_cos_f32_e32 v0, v0    ; Direct cosine on f32
s_setpc_b64 s[30:31]
```

### BF16 (Failing - Never Reaches This)
```
LLVM ERROR: Cannot select instruction
(compilation terminates)
```

## Why BF16 Fails

- ROCDL dialect in MLIR accepts all `LLVM_AnyFloat` types (generic)
- LLVM IR intrinsic `llvm.amdgcn.cos` declares return type as `anyfloat` (generic)
- AMDGPU ISA specification only defines:
  - `v_cos_f32` (single precision)
  - `v_cos_f16` (half precision)
  - **No bf16 variant**
- Codegen fails when trying to select (find matching) instruction

This is an ISA limitation, not a software bug.

## References

- mlir-translate: `/root/tingqli/llvm-project/mlir_install/bin/mlir-translate`
- llc: `/root/tingqli/llvm-project/mlir_install/bin/llc`
- ROCDL ops: `mlir_install/include/mlir/Dialect/LLVMIR/ROCDLOps.td`
- Intrinsics: `mlir_install/include/llvm/IR/IntrinsicsAMDGPU.td`

## Conclusion

**Use f32 for rocdl.cos. BF16 is not supported by AMDGPU hardware.**
