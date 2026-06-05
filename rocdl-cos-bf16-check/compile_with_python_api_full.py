#!/usr/bin/env python3
"""
ROCDL.COS Compilation 尽量通过 MLIR Python API
================================================

这个脚本展示如何完全使用 Python binding 完成编译：
1. 用 ir.Module.parse() 解析 MLIR
2. 用 PassManager 运行完整的 pass pipeline
3. 使用 Python binding 导出 LLVM IR，并调用 llc 生成程序代码（无需外部 mlir-translate）

更高级的方法：
- 使用 PassManager.parse() 来构建完整的 pass pipeline
- 调用 pm.run() 直接在内存中执行降级
- 避免中间文件 I/O

关键发现：
- Python binding 可以加载和运行大多数 pass
- 结合官方 pass（见 Passes.td）可用 convert-rocdl-to-llvm 完成主转换
- 可通过 Python binding 的 LLVM 翻译接口直接导出 LLVM IR，跳过 mlir-translate
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

try:
    from mlir_core.mlir._mlir_libs._mlirDialectsLLVM import translate_module_to_llvmir
except ImportError:
    translate_module_to_llvmir = None


def get_mlir_source(dtype: str) -> str:
    """Get MLIR source code for ROCDL.COS kernel."""
    mlir_text = f"""module {{
  llvm.func @test_cos_{dtype}(%arg0: {dtype}) -> {dtype} {{
    %result = rocdl.cos %arg0 {dtype} -> {dtype}
    llvm.return %result : {dtype}
  }}
}}"""
    return mlir_text


def parse_module_and_lower(mlir_text: str) -> str:
    """
    Parse MLIR text and run lowering pipeline entirely in Python.
    
    关键：PassManager 需要在 Context 的 scope 中运行。
    """
    ctx = ir.Context()
    with ctx:
        module = ir.Module.parse(mlir_text)
        
        # Run pass pipeline in context
        print("  ℹ Running pass pipeline via Python API PassManager.parse()...")
        try:
            pipeline_str = (
                "builtin.module("
                "convert-rocdl-to-llvm,"        # 将 ROCDL ops 转换为 LLVM
                "convert-scf-to-cf,"            # SCF → CF
                "convert-cf-to-llvm,"           # CF → LLVM
                "reconcile-unrealized-casts,"   # 清理转换
                "canonicalize"                  # 规范化
                ")"
            )
            
            pm = passmanager.PassManager.parse(pipeline_str)
            pm.enable_verifier(False)
            pm.run(module.operation)
            
            print("    ✓ Pass pipeline executed successfully (entirely in Python)")
            
        except Exception as e:
            print(f"    ⚠ Error in pass pipeline: {e}")
            print("    ℹ Continuing with partially lowered IR...")
        
        # Return lowered MLIR text while still in context (so it's valid)
        return str(module)


def extract_llvm_ir_text(lowered_ir: str) -> str:
    """
    Export LLVM IR text from lowered MLIR by Python binding.
    """
    if translate_module_to_llvmir is None:
        raise RuntimeError("translate_module_to_llvmir is unavailable in current MLIR Python binding")

    ctx = ir.Context()
    with ctx:
        module = ir.Module.parse(lowered_ir)
        return translate_module_to_llvmir(module.operation)


def llvm_ir_to_asm(llvm_ir_text: str, mcpu: str = "gfx942") -> str:
    """
    将 LLVM IR 直接编译为汇编。
    
    流程：
    1. 将 LLVM IR 文本通过 stdin 传给 llc
    2. 调用 llc (LLVM 编译器) 生成汇编
    3. 注意：代码生成阶段仍由 LLVM 后端完成

    这里不再使用 mlir-translate。
    """
    mlir_install = MLIR_INSTALL

    llc = os.path.join(mlir_install, "bin", "llc")

    with tempfile.NamedTemporaryFile(mode="w", suffix=".asm", delete=False) as asm_f:
        asm_file = asm_f.name

    try:
        print(f"  [1/1] LLVM IR → ASM (llc, -mcpu={mcpu})...")
        cmd_llc = [
            llc,
            "-mtriple=amdgcn-amd-amdhsa",
            f"-mcpu={mcpu}",
            "-filetype=asm",
            "-",
            "-o",
            asm_file,
        ]
        result = subprocess.run(cmd_llc, input=llvm_ir_text, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"    ✗ llc failed: {result.stderr}")
            raise RuntimeError("llc failed")
        print("    ✓ Success")

        with open(asm_file, "r", encoding="utf-8") as f:
            return f.read()

    finally:
        if os.path.exists(asm_file):
            os.remove(asm_file)


def display_results(asm_text: str, dtype: str):
    """Display results."""
    print("")
    print("=" * 70)
    print("RESULTS")
    print("=" * 70)
    print("")
    
    print("[AMDGPU Assembly]")
    print("-" * 70)
    lines = asm_text.split("\n")
    for i, line in enumerate(lines[:50], 1):
        print(f"{i:3d}: {line}")
    if len(lines) > 50:
        print(f"... ({len(lines) - 50} more lines)")
    
    print("")
    print("Key instruction:")
    print("-" * 70)
    found = False
    for line in lines:
        if "v_cos_f32" in line or "v_cos_bf16" in line:
            print(f"  {line.strip()}")
            found = True
    if not found:
        print("  (no direct instruction found)")


def main():
    """Main entry point."""
    dtype = sys.argv[1] if len(sys.argv) > 1 else "f32"
    mcpu = sys.argv[2] if len(sys.argv) > 2 else "gfx942"
    
    if dtype not in ("bf16", "f32"):
        print("Usage: compile_with_python_api_full.py [bf16|f32] [gfx942|gfx90a]")
        sys.exit(1)
    
    print("=" * 70)
    print("ROCDL.COS Compilation: Python API + llc (no mlir-translate)")
    print("=" * 70)
    print("")
    
    # Step 1: Parse MLIR via Python API
    print("[Step 1] Parse MLIR via Python API...")
    mlir_source = get_mlir_source(dtype)
    print("✓ MLIR source created")
    
    try:
        lowered_ir = parse_module_and_lower(mlir_source)
        print("✓ Module parsed and lowered")
    except Exception as e:
        print(f"✗ Parse/lower failed: {e}")
        sys.exit(1)
    
    # Step 2: Export LLVM IR via Python binding
    print("")
    print("[Step 2] Export LLVM IR via Python binding...")
    try:
        llvm_ir = extract_llvm_ir_text(lowered_ir)
        print(f"✓ Exported {len(llvm_ir)} bytes of LLVM IR")
    except Exception as e:
        print(f"✗ LLVM IR export failed: {e}")
        sys.exit(1)
    
    # Step 3: Compile to assembly (llc codegen)
    print("")
    print("[Step 3] Compile to AMDGPU assembly...")
    try:
        asm_text = llvm_ir_to_asm(llvm_ir, mcpu=mcpu)
        print("✓ Assembly generated")
    except Exception as e:
        print(f"✗ Failed: {e}")
        sys.exit(1)
    
    display_results(asm_text, dtype)


if __name__ == "__main__":
    main()
