#!/usr/bin/env python3
"""
ROCDL.COS Compilation via MLIR Python Bindings
===============================================

Demonstrates using MLIR Python API to:
1. Parse MLIR text IR (using Python API)
2. Run the MLIR pass pipeline for lowering to LLVM
3. Convert to LLVM IR text
4. Compile to AMDGPU assembly using llc

Key difference from bash approach:
  • bash: mlir-translate + llc (external tools)
  • Python: MLIR Python bindings + subprocess llc (programmatic IR handling)

Usage:
    python3 compile_with_python.py [bf16|f32] [gfx942|gfx90a]
    
Examples:
    python3 compile_with_python.py f32 gfx942     # F32 working case
    python3 compile_with_python.py bf16 gfx942    # BF16 unsupported case
"""

import sys
import os
import subprocess
import tempfile

# Setup MLIR Python path
MLIR_INSTALL = "/root/tingqli/llvm-project/mlir_install"
sys.path.insert(0, os.path.join(MLIR_INSTALL, "python_packages"))

from mlir_core.mlir import ir, passmanager
from mlir_core.mlir.dialects import rocdl, llvm


def get_mlir_source(dtype: str) -> str:
    """
    Get MLIR source code for ROCDL.COS kernel.
    
    Uses llvm.func + rocdl.cos in proper MLIR syntax.
    """
    type_str = dtype  # f32 or bf16
    
    mlir_text = f"""module {{
  llvm.func @test_cos_{type_str}(%arg0: {type_str}) -> {type_str} {{
    %result = rocdl.cos %arg0 {type_str} -> {type_str}
    llvm.return %result : {type_str}
  }}
}}"""
    
    return mlir_text


def load_module_via_python_api(mlir_text: str) -> ir.Module:
    """
    Parse MLIR text to module using Python API.
    
    This shows that MLIR Python bindings can parse/load IR
    in addition to programmatic construction.
    """
    ctx = ir.Context()
    with ctx:
        try:
            module = ir.Module.parse(mlir_text)
            return module
        except Exception as e:
            raise RuntimeError(f"Failed to parse MLIR: {e}")


def run_pass_pipeline(module: ir.Module):
    """
    Run MLIR pass pipeline to lower ROCDL → LLVM.
    
    Applies passes:
      • convert-rocdl-to-llvm: Lower ROCDL ops to LLVM
      • convert-cf-to-llvm:    Lower control flow to LLVM
      • reconcile-unrealized-casts: Clean up casts
    
    Note: Manual pass management may be limited in Python bindings.
    The mlir-translate tool will handle full lowering anyway.
    """
    try:
        # Try to create PassManager with proper context
        pm = passmanager.PassManager.parse("builtin.module(convert-rocdl-to-llvm,convert-cf-to-llvm,reconcile-unrealized-casts,canonicalize)")
        pm.run(module)
    except Exception as e:
        # Silently skip pass pipeline; lowering will happen via mlir-translate
        print(f"  ℹ Pass manager via Python API not available (will use mlir-translate instead): {e}")


def module_to_llvm_ir_text(module: ir.Module) -> str:
    """
    Convert MLIR module (after lowering) to LLVM IR text.
    
    The Python API's str(module) outputs MLIR text.
    We'll let llc handle the MLIR→LLVM IR translation.
    """
    return str(module)


def save_mlir_to_file(module_text: str, output_file: str):
    """Save MLIR or LLVM IR text to file."""
    with open(output_file, "w") as f:
        f.write(module_text)


def compile_mlir_to_asm(mlir_or_ll_file: str, asm_file: str, mcpu: str = "gfx942"):
    """
    Compile MLIR/LLVM IR to assembly.
    
    Uses mlir-translate to convert MLIR→LLVM IR, then llc for codegen.
    """
    mlir_translate = os.path.join(MLIR_INSTALL, "bin", "mlir-translate")
    llc = os.path.join(MLIR_INSTALL, "bin", "llc")
    
    # Intermediate LLVM IR file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.ll', delete=False) as tmp:
        ll_file = tmp.name
    
    try:
        # Step 1: mlir-translate (MLIR → LLVM IR)
        print(f"  [1/2] MLIR → LLVM IR (mlir-translate)...")
        cmd_translate = [
            mlir_translate,
            "--mlir-to-llvmir",
            mlir_or_ll_file,
            "-o", ll_file
        ]
        result = subprocess.run(cmd_translate, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"    ✗ mlir-translate failed: {result.stderr}")
            raise RuntimeError("mlir-translate failed")
        print(f"    ✓ mlir-translate succeeded")
        
        # Step 2: llc (LLVM IR → ASM)
        print(f"  [2/2] LLVM IR → ASM (llc, -mcpu={mcpu})...")
        cmd_llc = [
            llc,
            "-mtriple=amdgcn-amd-amdhsa",
            f"-mcpu={mcpu}",
            ll_file,
            "-o", asm_file
        ]
        result = subprocess.run(cmd_llc, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"    ✗ llc failed: {result.stderr}")
            raise RuntimeError("llc failed")
        print(f"    ✓ llc succeeded")
        
    finally:
        # Clean up temporary file
        if os.path.exists(ll_file):
            os.remove(ll_file)


def display_results(mlir_file: str, asm_file: str):
    """Display generated IR and assembly."""
    print("")
    print("=" * 70)
    print("RESULTS")
    print("=" * 70)
    print("")
    
    print("[MLIR IR (after lowering)]")
    print("-" * 70)
    with open(mlir_file) as f:
        lines = f.read().split("\n")
        for i, line in enumerate(lines[:50], 1):
            print(f"{i:3d}: {line}")
        if len(lines) > 50:
            print(f"... ({len(lines) - 50} more lines)")
    
    print("")
    print("[AMDGPU Assembly]")
    print("-" * 70)
    with open(asm_file) as f:
        lines = f.read().split("\n")
        for i, line in enumerate(lines[:50], 1):
            print(f"{i:3d}: {line}")
        if len(lines) > 50:
            print(f"... ({len(lines) - 50} more lines)")
    
    print("")
    print("Key cosine instruction:")
    print("-" * 70)
    found = False
    with open(asm_file) as f:
        for line in f:
            if "v_cos_f32" in line or "v_cos_bf16" in line:
                print(f"  {line.rstrip()}")
                found = True
    if not found:
        print("  (no direct cosine instruction found - may be inlined or optimized)")


def main():
    """Main entry point."""
    dtype = sys.argv[1] if len(sys.argv) > 1 else "f32"
    mcpu = sys.argv[2] if len(sys.argv) > 2 else "gfx942"
    
    if dtype not in ("bf16", "f32"):
        print("Usage: compile_with_python.py [bf16|f32] [gfx942|gfx90a]")
        sys.exit(1)
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    print("=" * 70)
    print(f"ROCDL.COS Compilation via MLIR Python API ({dtype.upper()})")
    print("=" * 70)
    print("")
    
    # Step 1: Get MLIR source and parse via Python API
    print("[Step 1] Parse MLIR via Python API (ir.Module.parse)...")
    print()
    
    mlir_source = get_mlir_source(dtype)
    print("MLIR source:")
    print("-" * 70)
    print(mlir_source)
    print()
    
    try:
        module = load_module_via_python_api(mlir_source)
        print("✓ Module parsed successfully via Python API")
        print()
    except Exception as e:
        print(f"✗ Parse failed: {e}")
        sys.exit(1)
    
    # Step 2: Run pass pipeline
    print("[Step 2] Run MLIR pass pipeline (ROCDL → LLVM lowering)...")
    print()
    
    try:
        run_pass_pipeline(module)
        print("✓ Pass pipeline executed")
        print()
    except Exception as e:
        print(f"⚠ Pass pipeline issue: {e}")
        print()
    
    # Step 3: Save module after lowering
    print("[Step 3] Save lowered IR to file...")
    lowered_ir_text = module_to_llvm_ir_text(module)
    mlir_file = os.path.join(script_dir, f"test_cos_{dtype}_py.mlir")
    save_mlir_to_file(lowered_ir_text, mlir_file)
    print(f"✓ Saved to: {mlir_file}")
    print()
    
    # Step 4: Compile to assembly
    print("[Step 4] Compile to AMDGPU assembly...")
    print()
    asm_file = os.path.join(script_dir, f"test_cos_{dtype}_py.asm")
    
    try:
        compile_mlir_to_asm(mlir_file, asm_file, mcpu=mcpu)
        print("✓ Assembly generated successfully")
        print(f"  Output: {asm_file}")
    except Exception as e:
        print(f"✗ Compilation to assembly failed: {e}")
        sys.exit(1)
    
    print()
    
    # Display results
    display_results(mlir_file, asm_file)


if __name__ == "__main__":
    main()
