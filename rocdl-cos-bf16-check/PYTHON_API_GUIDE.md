# MLIR Python API vs Bash Tools - 对比指南

## 概述

该项目提供了两种编译 ROCDL IR 到 AMDGPU 汇编的方法：

| 方法 | 脚本 | 优点 | 缺点 |
|------|------|------|------|
| **Bash + CLI 工具** | `compile.sh` / `compile_f32.sh` | 简单直接、文本流程清晰、易调试 | 需要外部工具、难以嵌入大型Python应用 |
| **Python API** | `compile_with_python.py` | 可编程、易集成、变量控制灵活 | 需要理解MLIR Python binding、pass管理复杂 |

---

## 方法1：Bash + CLI 工具（原始方案）

### 编译流程

```
   test_cos_f32.mlir (文本MLIR)
          ↓
   mlir-translate --mlir-to-llvmir
          ↓
   test_cos_f32.ll (LLVM IR)
          ↓
   llc -mcpu=gfx942
          ↓
   test_cos_f32.asm (AMDGPU汇编)
```

### 使用方式

```bash
# F32 编译（成功）
./compile_f32.sh

# BF16 编译（失败 - 不支持的指令）
./compile.sh
```

### 优点
✓ 最小化依赖 - 仅需 llvm-project/mlir_install 中的工具
✓ 易于调试 - 每一步结果都是文本文件，可直接检查
✓ 透明的 MLIR 源代码 - .mlir 文件是可读的文本
✓ 标准工具链 - mlir-translate 和 llc 是官方 LLVM 工具

### 缺点
✗ 难以集成 - 需要调用外部命令、处理文件I/O
✗ 不灵活 - 每次改参数都需要修改脚本或命令行
✗ 多次磁盘访问 - 中间文件必须写入磁盘

---

## 方法2：Python API（编程方案）

### 编译流程

```python
# 在Python中使用MLIR绑定
mlir_text ← "module { ... }"
         ↓
ir.Module.parse(mlir_text)  # Python API
         ↓
passmanager.run()           # Python API（可选）
         ↓
str(module) → .mlir文件
         ↓
mlir-translate --mlir-to-llvmir
         ↓
llc -mcpu=gfx942
         ↓
.asm 汇编文件
```

### 使用方式

```bash
# F32 编译
python3 compile_with_python.py f32 gfx942

# BF16 编译
python3 compile_with_python.py bf16 gfx942

# 默认参数（f32 + gfx942）
python3 compile_with_python.py
```

### 在大型应用中集成

```python
import sys
sys.path.insert(0, '/root/tingqli/llvm-project/mlir_install/python_packages')

from mlir_core.mlir import ir
from compile_with_python import get_mlir_source, load_module_via_python_api

# 在你的Python应用中
dtype = "f32"
mlir_source = get_mlir_source(dtype)
module = load_module_via_python_api(mlir_source)

# 或直接构造MLIR IR...
print(str(module))
```

### 优点
✓ 完全可编程 - 在Python应用中直接使用
✓ 灵活构造 - 可在运行时生成 MLIR（不仅仅是文本解析）
✓ 变量控制 - 轻松改参数、类型、架构等
✓ 集成友好 - 无需外部命令调用

### 缺点
✗ 依赖复杂 - 需要理解 MLIR Python binding
✗ 调试困难 - IR 构造错误较难追踪
✗ Pass 管理有限 - Python binding 中的 pass 管理不如 CLI 工具完整
✗ 仍需要 llc - 最后的LLVM IR→ASM步骤仍需要外部工具

---

## 关键发现

### 共同点
- 两种方法都在 **llc 阶段** 遇到 BF16 不支持的错误
- 错误信息相同：`AMDGPUISD::COS_HW # ... bf16`
- 证明问题在于 AMDGPU ISA 本身没有 `v_cos_bf16` 指令

### F32 工作输出

两种方法均生成相同的汇编指令：

```asm
v_cos_f32_e32 v0, v0

; 目标：gfx942 (MI300X)
; 寄存器使用：1 VGPR
; 指令计数：3 (s_waitcnt, v_cos_f32_e32, s_setpc_b64)
```

### BF16 失败输出

```
LLVM ERROR: Cannot select: t9: bf16 = AMDGPUISD::COS_HW
In function: test_cos_bf16
```

---

## 何时使用哪种方法？

### 使用 Bash 方案（CLI）
- ✓ 快速一次性编译
- ✓ 教学/演示目的
- ✓ 需要完整透明度的调试
- ✓ 不依赖特定的 Python 环境

### 使用 Python 方案（API）
- ✓ 集成到大型编译框架
- ✓ 需要动态生成 IR 的应用
- ✓ 参数化编译（类型、架构动态选择）
- ✓ 构建自动化工具链
- ✓ 想要编程控制 MLIR IR 的构造和转换

---

## 拓展可能性

### 基于 Python API 的拓展

1. **动态 IR 生成**（无需文本MLIR）

```python
from mlir_core.mlir import ir
from mlir_core.mlir.dialects import llvm, rocdl

# 完全在Python中构造IR，无需文本
module = ir.Module.create()
# ... 使用 InsertionPoint 和 dialect ops 构造
```

2. **批量编译**

```python
for dtype in ["f32", "bf16", "f64"]:
    for mcpu in ["gfx90a", "gfx942"]:
        module = load_module_via_python_api(get_mlir_source(dtype))
        compile_mlir_to_asm(module, dtype, mcpu)
```

3. **集成到 FlyDSL 编译链**

Python API 使得将 ROCDL 编译作为更大编译流程的一部分成为可能。

4. **自定义 pass pipeline**

使用Python API的PassManager（需要更多调研）或通过 CLI fallback。

---

## 文件清单

### 原始方案（Bash）
- `test_cos_f32.mlir` - F32 测试用例
- `test_cos_bf16.mlir` - BF16 测试用例
- `compile.sh` - BF16 编译脚本（失败）
- `compile_f32.sh` - F32 编译脚本（成功）

### Python API 方案
- `compile_with_python.py` - 统一的 Python 编译脚本
- 输出：`test_cos_{f32,bf16}_py.mlir` - 降级后的 IR
- 输出：`test_cos_{f32,bf16}_py.asm` - 汇编代码

### 文档
- `README.md` - 快速开始
- `ANALYSIS.md` - 技术分析
- `TEST_RESULTS.md` - 测试结果和错误分析
- `PROJECT_SUMMARY.md` - 项目总结
- `PYTHON_API_GUIDE.md` - 本文档

---

## 注意事项

1. **dlopen 和库路径**：
   - Python API 需要 MLIR 的 C++ 共享库
   - LD_LIBRARY_PATH 可能需要设置（通常由 mlir_install 的 setup 处理）

2. **Pass 管理限制**：
   - Python binding 中的 PassManager 功能有限
   - 复杂的 pass pipeline 可能需要 CLI fallback（如脚本所示）

3. **方言注册**：
   - 导入 `from mlir_core.mlir.dialects import rocdl, llvm` 会自动注册方言
   - 无需手动调用 `register_dialect()`

4. **文本 MLIR 格式**：
   ```mlir
   # 正确格式（支持）
   %result = rocdl.cos %arg0 f32 -> f32
   
   # 错误格式（不支持）
   %result = rocdl.cos %arg0 : f32 -> f32  # 缺少操作数类型
   ```

---

## 总结

这两种方法提供了不同的收益：

| 特性 | Bash | Python |
|------|------|--------|
| 快速开始 | ★★★★★ | ★★☆☆☆ |
| 易于理解 | ★★★★★ | ★★★☆☆ |
| 集成能力 | ★☆☆☆☆ | ★★★★★ |
| 调试支持 | ★★★★☆ | ★★★☆☆ |
| 灵活性 | ★★☆☆☆ | ★★★★☆ |

对于本项目的验证目的，**Bash 方案** 已足够。
若要集成到更大的系统中，**Python API** 更合适。
