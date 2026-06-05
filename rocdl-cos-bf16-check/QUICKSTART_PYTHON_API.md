# ROCDL Compilation: Python API 使用指南

## 快速开始

### 方法 A：使用 Python API（推荐用于集成）

```bash
cd /root/tingqli/web-space/rocdl-cos-bf16-check

# F32 编译（成功）
python3 compile_with_python.py f32 gfx942

# BF16 编译（失败 - 展示不支持）
python3 compile_with_python.py bf16 gfx942

# 默认参数（f32 + gfx942）
python3 compile_with_python.py
```

### 方法 B：使用 Bash 脚本（快速和简洁）

```bash
cd /root/tingqli/web-space/rocdl-cos-bf16-check

# F32 仅编译
./compile_f32.sh

# BF16 编译
./compile.sh
```

### 方法 C：对比两种方法

```bash
bash compare_methods.sh gfx942
```

---

## Python API 详解

### 核心思想

相比直接使用 CLI 工具（`mlir-translate` 和 `llc`），Python API 让你可以：

1. **在 Python 中解析 MLIR**
   ```python
   from mlir_core.mlir import ir
   
   mlir_text = "module { ... }"
   module = ir.Module.parse(mlir_text)
   ```

2. **运行 MLIR pass pipeline**
   ```python
   from mlir_core.mlir import passmanager
   
   pm = passmanager.PassManager.parse("builtin.module(...)")
   pm.run(module)
   ```

3. **获取修改后的 IR**
   ```python
   lowered_ir = str(module)
   ```

### 脚本结构

[compile_with_python.py](compile_with_python.py) 的关键函数：

```python
# 1. 生成 MLIR 源代码
mlir_source = get_mlir_source(dtype="f32")

# 2. 用 Python API 解析
module = load_module_via_python_api(mlir_source)

# 3. 运行 pass（可选）
run_pass_pipeline(module)

# 4. 获取 IR 文本
lowered_ir_text = module_to_llvm_ir_text(module)

# 5. 保存和编译
save_mlir_to_file(lowered_ir_text, "output.mlir")
compile_mlir_to_asm("output.mlir", "output.asm", mcpu="gfx942")
```

---

## 在自己的代码中使用

### 基本模板

```python
import sys
import os
sys.path.insert(0, "/root/tingqli/llvm-project/mlir_install/python_packages")

from mlir_core.mlir import ir
from mlir_core.mlir.dialects import rocdl, llvm

# 创建或加载 MLIR 模块
mlir_text = """
module {
  llvm.func @kernel(%arg0: f32) -> f32 {
    %0 = rocdl.cos %arg0 f32 -> f32
    llvm.return %0 : f32
  }
}
"""

# 解析
ctx = ir.Context()
with ctx:
    module = ir.Module.parse(mlir_text)
    print("✓ Module parsed")
    print(module)
    
    # 可以在这里进行转换...
    # 获取字符串表示
    ir_str = str(module)
```

### 集成到 FlyDSL

Python API 可以集成到 FlyDSL 的编译流程中：

```python
# 在 FlyDSL 编译器中
from mlir_core.mlir import ir, passmanager

def compile_rocdl_kernel(mlir_text, mcpu="gfx942"):
    """将 ROCDL IR 编译到汇编"""
    module = ir.Module.parse(mlir_text)
    
    # 运行 pass pipeline
    pm = passmanager.PassManager.parse("builtin.module(convert-rocdl-to-llvm)")
    pm.run(module)
    
    # 在你的编译流程中返回
    return str(module)
```

---

## 环境配置

### 前置条件

```bash
# 已建立的 mlir_install
export MLIR_INSTALL=/root/tingqli/llvm-project/mlir_install

# Python 搜索路径
export PYTHONPATH="${MLIR_INSTALL}/python_packages:${PYTHONPATH}"

# 库路径（如果需要）
export LD_LIBRARY_PATH="${MLIR_INSTALL}/lib:${LD_LIBRARY_PATH}"
```

### 验证

```bash
python3 -c "
import sys
sys.path.insert(0, '/root/tingqli/llvm-project/mlir_install/python_packages')
from mlir_core.mlir import ir
from mlir_core.mlir.dialects import rocdl, llvm
print('✓ MLIR Python bindings available')
"
```

---

## 常见问题

### Q1: 为什么 Python API 还要调用 `mlir-translate`？

**A:** Python binding 中的 `PassManager` 管理不够完整，无法直接生成 LLVM IR。通过 CLI 工具可以确保完整的 lowering 流程。

### Q2: BF16 为什么总是失败？

**A:** gfx942 硬件 (MI300X) 没有 `v_cos_bf16` 指令。错误发生在 llc 的 DAG→ISA 阶段，即使用 Python API 也无法绕过。

### Q3: pass pipeline 中的警告是什么？

**A:** PassManager 初始化方式在 Python binding 中有限制。脚本采用了 fallback 方式（通过 CLI 工具+文本 MLIR），这是标准做法。

### Q4: 如何动态生成 MLIR 而不是文本解析？

**A:** 可以用 `InsertionPoint` 和 dialect operation classes：

```python
with ir.InsertionPoint(module.body):
    func = llvm.FuncOp(...)  # 创建函数
    # ... 添加更多操作
```

这需要了解 MLIR dialect 的 Python binding（相对复杂）。

### Q5: 生成的汇编为什么多次运行不同？

**A:** 不应该不同。如果观察到差异，可能是：
- 临时文件缓存问题 → 删除 `.pyc` 和临时文件
- 编译器版本差异 → 确保使用同一个 mlir_install
- 并行化问题 → 某些 pass 可能不确定性 → 用 `-O0` 或 `-Os`

---

## 对比总结

| 维度 | Bash 脚本 | Python API |
|------|---------|-----------|
| **学习曲线** | 低 | 中 |
| **集成难度** | 高 | 低 |
| **调试能力** | 强（文本中间产物） | 弱（需要打印调试） |
| **参数灵活性** | 中 | 高 |
| **错误处理** | 简单 | 复杂 |
| **单文件脚本** | ✓ | ✓ |
| **大型应用** | ✗ | ✓ |
| **性能** | 相同 |  相同 |

---

## 输出文件

### Python API 编译生成

- `test_cos_f32_py.mlir` - 降级后的 MLIR IR
- `test_cos_f32_py.asm` - 最终 AMDGPU 汇编
- `test_cos_bf16_py.mlir` - BF16 版本（用于诊断）
- `test_cos_bf16_py.asm` - 编译失败日志

### 与原始脚本对比

- `test_cos_f32.mlir` vs `test_cos_f32_py.mlir`（应该等价）
- `test_cos_f32.asm` vs `test_cos_f32_py.asm`（应该相同）

运行 `compare_methods.sh` 验证。

---

## 下一步

1. **拓展到其他操作**：试试 `rocdl.sin`, `rocdl.sqrt`, 等
2. **批量编译**：为多个参数组合编译
3. **集成到 FlyDSL**：在 FlyDSL 的 ROCDL pass 中使用
4. **自定义 lowering**：编写自定义 MLIR pass（需要 C++ 知识）

---

## 参考资源

- [MLIR Python Bindings Doc](https://mlir.llvm.org/docs/Bindings/Python/)
- [ROCDL Dialect](https://mlir.llvm.org/docs/Dialects/ROCDL/)
- [FlyDSL Kernel Authoring](../../docs/kernel_authoring_guide.md)
- [Project Analysis](ANALYSIS.md)
- [Test Results](TEST_RESULTS.md)

