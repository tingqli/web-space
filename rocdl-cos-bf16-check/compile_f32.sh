#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MLIR_INSTALL="/root/tingqli/llvm-project/mlir_install"
MLIR_TRANSLATE="${MLIR_INSTALL}/bin/mlir-translate"
LLC="${MLIR_INSTALL}/bin/llc"

echo "========================================"
echo "ROCDL.COS F32 Working Example"
echo "========================================"
echo ""

# Translate to LLVM IR
echo "[Step 1] Translating test_cos_f32.mlir → LLVM IR..."
"$MLIR_TRANSLATE" \
    --mlir-to-llvmir \
    "$SCRIPT_DIR/test_cos_f32.mlir" \
    -o "$SCRIPT_DIR/test_cos_f32.ll" 2>&1

echo "✓ Successfully translated"

# Compile to assembly
echo ""
echo "[Step 2] Compiling LLVM IR → AMDGPU assembly (gfx942)..."
"$LLC" \
    -mtriple=amdgcn-amd-amdhsa \
    -mcpu=gfx942 \
    "$SCRIPT_DIR/test_cos_f32.ll" \
    -o "$SCRIPT_DIR/test_cos_f32.asm" 2>&1

echo "✓ Successfully compiled!"

echo ""
echo "========================================"
echo "Results"
echo "========================================"
echo ""

echo "[LLVM IR - test_cos_f32.ll]"
echo "---"
cat "$SCRIPT_DIR/test_cos_f32.ll"

echo ""
echo "[Assembly - test_cos_f32.asm]"
echo "---"
cat "$SCRIPT_DIR/test_cos_f32.asm"

echo ""
echo "Key instruction for f32 cos:"
grep -n "v_cos_f32" "$SCRIPT_DIR/test_cos_f32.asm" || echo "Not found (might be inlined)"
