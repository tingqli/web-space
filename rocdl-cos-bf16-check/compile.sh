#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MLIR_INSTALL="/root/tingqli/llvm-project/mlir_install"
MLIR_TRANSLATE="${MLIR_INSTALL}/bin/mlir-translate"
LLC="${MLIR_INSTALL}/bin/llc"

echo "========================================"
echo "ROCDL.COS BF16 Support Verification"
echo "========================================"
echo ""
echo "MLIR_INSTALL: $MLIR_INSTALL"
echo ""

# Step 1: Translate to LLVM IR
echo "[Step 1] Translating MLIR to LLVM IR..."
"$MLIR_TRANSLATE" \
    --mlir-to-llvmir \
    "$SCRIPT_DIR/test_cos_bf16.mlir" \
    -o "$SCRIPT_DIR/test_cos_bf16.ll" 2>&1

echo "✓ Successfully translated to LLVM IR"

# Step 2: Compile to assembly
echo ""
echo "[Step 2] Compiling LLVM IR to AMDGPU assembly (gfx942)..."
"$LLC" \
    -mtriple=amdgcn-amd-amdhsa \
    -mcpu=gfx942 \
    "$SCRIPT_DIR/test_cos_bf16.ll" \
    -o "$SCRIPT_DIR/test_cos_bf16.asm" 2>&1

echo "✓ Successfully compiled to assembly"

# Step 3: Analysis
echo ""
echo "========================================"
echo "Analysis & Results"
echo "========================================"
echo ""

echo "[Check 1] BF16 type in LLVM IR?"
if grep -q "bf16" "$SCRIPT_DIR/test_cos_bf16.ll"; then
    echo "✓ Yes - BF16 type found"
else
    echo "✗ No - BF16 not found (likely converted)"
fi

echo ""
echo "[Check 2] amdgcn_cos intrinsic?"
if grep -q "amdgcn_cos\|amdgcn.cos" "$SCRIPT_DIR/test_cos_bf16.ll"; then
    echo "✓ Yes - Found amdgcn_cos intrinsic"
    grep "amdgcn_cos" "$SCRIPT_DIR/test_cos_bf16.ll"
else
    echo "✗ No - No amdgcn_cos intrinsic"
fi

echo ""
echo "[Check 3] Assembly instructions?"
if grep -q "v_cos_f32" "$SCRIPT_DIR/test_cos_bf16.asm"; then
    echo "✓ v_cos_f32 found"
fi
if grep -q "v_cos_f16" "$SCRIPT_DIR/test_cos_bf16.asm"; then
    echo "✓ v_cos_f16 found"
fi
if grep -q "v_cvt_f32_bf8\|v_cvt_.*_bf" "$SCRIPT_DIR/test_cos_bf16.asm"; then
    echo "⚠ BF16 conversion found (BF16 not natively supported for cos)"
fi

echo ""
echo "========================================"
echo "Generated Files"
echo "========================================"
ls -lh "$SCRIPT_DIR"/test_cos_bf16.* 2>/dev/null | awk '{print $9, "(" $5 ")"}'

echo ""
echo "[LLVM IR - test_cos_bf16.ll]"
echo "---"
cat "$SCRIPT_DIR/test_cos_bf16.ll"

echo ""
echo "[Assembly - test_cos_bf16.asm]"
echo "---"
cat "$SCRIPT_DIR/test_cos_bf16.asm"
