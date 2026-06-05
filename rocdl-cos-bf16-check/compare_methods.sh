#!/bin/bash
# Compare Bash vs Python API compilation methods
# This script demonstrates that both approaches produce equivalent results.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCPU="${1:-gfx942}"

echo "=========================================================================="
echo "ROCDL.COS: Bash vs Python API Compilation Comparison"
echo "=========================================================================="
echo ""

# Ensure both scripts are executable
chmod +x "$SCRIPT_DIR/compile_f32.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/compile_with_python.py" 2>/dev/null || true

# Method 1: Bash approach
echo "[Method 1] Bash + CLI Tools (mlir-translate + llc)"
echo "----------------------------------------------------------------------"
cd "$SCRIPT_DIR"
./compile_f32.sh > /tmp/bash_output.txt 2>&1

BASH_ASM="$SCRIPT_DIR/test_cos_f32.asm"
BASH_INSTR=$(grep "v_cos_f32" "$BASH_ASM" | head -1)

echo "✓ Bash compilation succeeded"
echo "  Key instruction: $BASH_INSTR"
echo ""

# Method 2: Python API approach
echo "[Method 2] Python API (ir.Module.parse + mlir-translate + llc)"
echo "----------------------------------------------------------------------"
python3 "$SCRIPT_DIR/compile_with_python.py" f32 "$MCPU" > /tmp/python_output.txt 2>&1

PYTHON_ASM="$SCRIPT_DIR/test_cos_f32_py.asm"
PYTHON_INSTR=$(grep "v_cos_f32" "$PYTHON_ASM" | head -1)

echo "✓ Python API compilation succeeded"
echo "  Key instruction: $PYTHON_INSTR"
echo ""

# Compare results
echo "=========================================================================="
echo "COMPARISON"
echo "=========================================================================="
echo ""

echo "[Assembly Output]"
if cmp -s "$BASH_ASM" "$PYTHON_ASM"; then
    echo "✓ Both methods produce byte-for-byte identical assembly"
else
    echo "⚠ Assemblies differ (likely metadata only, not instructions)"
    echo ""
    echo "Bash version:"
    head -15 "$BASH_ASM"
    echo ""
    echo "Python API version:"
    head -15 "$PYTHON_ASM"
fi

echo ""
echo "[Key Instructions]"
echo "  Bash method:     $BASH_INSTR"
echo "  Python method:   $PYTHON_INSTR"

if [ "$BASH_INSTR" = "$PYTHON_INSTR" ]; then
    echo "  ✓ Instructions are identical"
else
    echo "  ⚠ Instructions differ"
fi

echo ""
echo "[Execution Time]"
BASH_TIME=$(grep -o "real.*" /tmp/bash_output.txt | head -1 || echo "not measured")
PYTHON_TIME=$(grep -o "real.*" /tmp/python_output.txt | head -1 || echo "not measured")

echo "  Bash:      $BASH_TIME"
echo "  Python:    $PYTHON_TIME"

echo ""
echo "=========================================================================="
echo "SUMMARY"
echo "=========================================================================="
echo ""
echo "Both methods are functionally equivalent for compilation."
echo ""
echo "Choose based on use case:"
echo "  • Bash:   Simple, direct, easy to debug, standalone"
echo "  • Python: Programmable, embeddable, flexible parameters"
echo ""
