# LLVM AMDGPU后端行号编码 - 总结与快速查阅

## 📋 目录

1. **核心概念速记** - 5分钟快速学习
2. **编码参数速查表** - 常见值参考
3. **代码实现快速查阅** - 源文件位置
4. **问题诊断指南** - 常见问题排查
5. **外部资源链接** - DWARF标准和相关文档

---

## 核心概念速记

### 行号信息的三层架构

```
Layer 1: LLVM IR (高级)
  ├─ !DILocation 元数据
  ├─ 包含: line, column, scope, inlinedAt
  └─ 示例: !DILocation(line: 42, column: 5, scope: !scope)

Layer 2: Machine Code (中间)
  ├─ DebugLoc 调试位置对象
  ├─ 关联到 MachineInstr
  └─ 由IR转换而来

Layer 3: DWARF (低级，二进制)
  ├─ MCDwarfLoc / MCDwarfLineEntry
  ├─ 编码到 .debug_line 二进制段
  └─ 使用 LEB128 和特殊操码
```

### 两个关键机制

#### 机制1: 特殊操码 (Special Opcodes)

```
格式: 单个字节 (13-255)
用途: 同时编码行增量 + 地址增量

编码示例:
  opcode = 13 + (line_delta - (-5)) + (addr_delta * 14)
           = 13 + (line_delta + 5) + (addr_delta * 14)

约束:
  - 行增量 ∈ [-5, 8]     (14个值)
  - 地址增量 ∈ [0, 17]    (特殊操码225-255共17个值)
  - 超出范围使用标准操码 (DW_LNS_advance_line, DW_LNS_advance_pc)
```

**空间效率**: 单字节特殊操码 < 两字节 `const_add_pc` < 可变长 `advance_pc`

#### 机制2: Inline关系链

```
表示方法: DIE树 + 属性链接

关键属性:
  - DW_AT_abstract_origin: 指向被inline函数的原型
  - DW_AT_call_line/file/column: 调用点位置
  - inlinedAt (IR层): 递归指向外层调用点
  - discriminator: 区分同行多个inline

结构:
  Abstract Instance (函数定义，无地址范围)
          ↑
          | DW_AT_abstract_origin
          |
  Inlined Subroutine (每次inline产生一个)
          ↑
          | inlinedAt (IR层)
          | DW_AT_call_line (DWARF层)
          |
  Caller Function Scope
```

---

## 编码参数速查表

### 标准参数集 (AMDGPU, LLVM标准)

| 参数 | 值 | 含义 | 范围 |
|------|-----|------|------|
| `DWARF2LineOpcodeBase` | 13 | 特殊操码起点 | [13, 255] |
| `DWARF2LineBase` | -5 | 行增量最小值 | [-5, 8] |
| `DWARF2LineRange` | 14 | 行增量范围 | 单个特殊操码表示14个值 |
| `MaxSpecialAddrDelta` | 17 | 最大地址增量 | 计算: (255-13)/14=17 |

**验证公式**:
```
opcode_min = 13 + ((-5) - (-5)) + (0 * 14) = 13     ✓
opcode_max = 13 + (8 - (-5)) + (17 * 14) = 255     ✓
line_range = 8 - (-5) + 1 = 14                      ✓
```

### 地址增量计算

```
物理地址增量 (bytes) → 指令为单位的增量

地址缩放因子 (ScaleAddrDelta):
  通常 = 1 (AMDGPU HSACO为字节寻址)
  
InsnLength:
  AMDGPU MI308X/MI300X: 4字节 (双发射VLIW)
  
计算:
  AddrDelta_scaled = AddrDelta / InsnLength
```

---

## 代码实现快速查阅

### 源文件追踪

```
用户代码 (.c/.cpp)
    ↓ clang -g
LLVM IR (.ll)
    ├─ 包含 !DILocation 元数据
    └─ 位置: 源文件末尾的 !0, !1, ... 标签

    ↓ llc (LLVM compiler)
MachineInstr
    ├─ 包含 DebugLoc
    └─ 位置: MachineInstr::debugLoc 成员

    ↓ AsmPrinter::emitInstruction()
MCDwarfLoc
    ├─ 位置: lib/MC/MCDwarf.h
    └─ 创建: DwarfDebug::beginInstruction()

    ↓ MCDwarfLineTable::emitOne()
.debug_line段 (二进制)
    ├─ 位置: llvm/lib/MC/MCDwarf.cpp:178
    └─ 编码: MCDwarfLineAddr::encode()

    ↓ llc -g (生成object)
.o 对象文件 (ELF/COFF)
    ├─ 包含 .debug_line, .debug_info, .debug_ranges 段
    └─ 查看: llvm-dwarfdump --debug-line output.o
```

### 关键函数速查

| 函数 | 文件 | 行号范围 | 职责 |
|------|------|---------|------|
| `MCDwarfLineTable::emitOne` | MCDwarf.cpp | 178-307 | 遍历行表项，发出操码 |
| `MCDwarfLineAddr::encode` | MCDwarf.cpp | 748-843 | 核心编码算法 |
| `MCAsmStreamer::emitDwarfAdvanceLineAddr` | MCAsmStreamer.cpp | 2687-2725 | 流式输出调试信息 |
| `DwarfDebug::beginInstruction` | DwarfDebug.cpp | - | 收集MachineInstr的调试信息 |
| `AMDGPUAsmPrinter::emitInstruction` | AMDGPUAsmPrinter.cpp | - | AMDGPU特定的汇编打印 |

---

## 问题诊断指南

### Q1: 如何验证行号编码是否正确?

```bash
# Step 1: 生成带调试信息的object
clang -g -O2 test.c -o test.o

# Step 2: 查看行表
llvm-dwarfdump --debug-line test.o | head -50

# Step 3: 检查输出格式
# 应该看到:
#   file_names[  1]:
#     name: "test.c"
#   line_number_program:
#     [0x00000000]  Special opcode ...
```

### Q2: inline信息没有在调用栈中显示

**可能原因**:
1. 编译优化级别太低 (-O1 可能不inline)
2. 调试信息中缺少DW_AT_abstract_origin
3. 调试器不支持inline显示

**检查方法**:
```bash
# 查看是否有inlined_subroutine DIE
llvm-dwarfdump --debug-info test.o | grep -A5 "DW_TAG_inlined_subroutine"

# 查看是否有DW_AT_abstract_origin属性
llvm-dwarfdump --debug-info test.o | grep "DW_AT_abstract_origin"
```

### Q3: 地址到行号的映射失效

**检查清单**:
```cpp
1. DebugLoc是否正确附加到MachineInstr?
   if (!MI.getDebugLoc())
     llvm::errs() << "Missing DebugLoc!\n";

2. DILocation元数据是否存在?
   检查IR中!DILocation标签

3. 文件编号是否正确?
   第一个文件编号应为1 (DWARF4) 或0 (DWARF5)

4. 行号是否在有效范围?
   行号应 > 0
```

### Q4: 特殊操码编码失败

**症状**: 使用了DW_LNS_advance_line而不是特殊操码

**原因分析**:
```cpp
// 行增量超出范围
if (line_delta < DWARF2LineBase || 
    line_delta > DWARF2LineBase + DWARF2LineRange - 1) {
  // 必须使用DW_LNS_advance_line + SLEB128
}

// 组合后超范围
if ((line_delta - base) + (addr_delta * range) > 255) {
  // 必须拆分为多个操码
}
```

**优化建议**:
- 避免单行跨越大量地址 → 编译器优化调整
- 使用linker-level调试信息 (DWARF 4+)

---

## 外部资源

### DWARF标准

| 文档 | 用途 | 获取 |
|-----|------|------|
| DWARF 3 Spec | Line Table完整定义 | dwarfstd.org |
| DWARF 4 Spec | 新增discriminator等 | dwarfstd.org |
| DWARF 5 Spec | line_str, new formats | dwarfstd.org |

### LLVM文档

```
LLVM源树中:
  docs/SourceLevelDebugging.rst     # 源码级调试概述
  docs/Debugging.rst                 # 开发者调试指南
```

### AMD GPU相关

```
ROCm官方文档:
  https://rocmdocs.amd.com/
  
AMDGPU LLVM后端:
  llvm/lib/Target/AMDGPU/
  
FlyDSL (高性能核函数DSL):
  https://rocm.github.io/FlyDSL
```

---

## 实战速记

### 查看汇编中的调试信息

```bash
# 方法1: llvm-dwarfdump (推荐)
llvm-dwarfdump --debug-line output.o

# 方法2: objdump
objdump --dwarf=line output.o

# 方法3: readelf
readelf --debug-dump=line output.o
```

### 生成带调试信息的IR

```bash
# 保留源代码位置信息
clang -g -emit-llvm -c test.c -o test.ll

# 查看!DILocation标签
grep "!DILocation\\|!DISubprogram" test.ll
```

### 追踪编码过程

```cpp
// 在llc中启用调试输出 (需编译LLVM时启用)
LLVM_DEBUG(llvm::dbgs() << "LineDelta=" << LineDelta 
                        << " AddrDelta=" << AddrDelta << "\n");

// 或使用GDB单步跟踪MCDwarfLineAddr::encode()
gdb --args llc -g test.ll
```

---

## 常见值速查

### DWARF版本选择

```
DWARF 3 (默认):
  ✓ 基础特性
  ✗ 无discriminator
  ✗ 无inline call site info

DWARF 4 (推荐):
  ✓ discriminator支持
  ✓ call_* 属性
  ✓ 向后兼容
  
DWARF 5 (最新):
  ✓ 更好的压缩
  ✓ line_str共享字符串
  ✗ 调试器支持不完善
```

### 行增量范围速算

```
特殊操码能表示的行增量数量: DWARF2LineRange = 14

范围: [LineBase, LineBase + LineRange - 1]
      = [-5, -5 + 14 - 1]
      = [-5, 8]

包含值: -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8 (14个)

超出范围例子:
  line_delta = -6 → 需要 DW_LNS_advance_line
  line_delta = 9  → 需要 DW_LNS_advance_line
```

---

## 调试工具快速命令参考

```bash
# 完整DWARF信息显示
llvm-dwarfdump --all output.o

# 仅显示行表
llvm-dwarfdump --debug-line output.o

# 仅显示调试信息条目(DIE)
llvm-dwarfdump --debug-info output.o

# 显示地址范围 (用于inline)
llvm-dwarfdump --debug-ranges output.o

# 查找特定函数的信息
llvm-dwarfdump --debug-info output.o | grep -A20 "_Z10inline_add"

# 验证行表有效性
llvm-dwarfdump --verify output.o
```

---

## 总结对比表

| 方面 | DWARF 3 | DWARF 4 | DWARF 5 |
|-----|---------|---------|---------|
| Line Table基础 | ✓ | ✓ | ✓ |
| Discriminator | ✗ | ✓ | ✓ |
| Call Site Info | ✗ | ✓ | ✓ |
| 地址范围扩展 | ✓ | ✓ | ✓ |
| Range List优化 | ✗ | ✗ | ✓ |
| 字符串表共享 | ✗ | ✗ | ✓ |
| Backward Compat | N/A | ✓ | ○ |

---

## 下一步学习

1. **理论深化**:
   - 阅读DWARF规范第6章 (Line Number Information)
   - 阅读代码: MCDwarf.cpp和DwarfDebug.cpp

2. **实践操作**:
   - 编译简单C程序，使用llvm-dwarfdump观察输出
   - 修改源代码行号，观察编码变化
   - 使用GDB在inline函数中单步

3. **问题排查**:
   - 遇到调试信息丢失：检查编译参数 (-g -O2)
   - 遇到inline不显示：检查DW_TAG_inlined_subroutine
   - 遇到地址映射错误：验证MCDwarfLoc填充

---

## 图表速记

### 特殊操码编码决策树

```
LineDelta == INT64_MAX?
├─ YES → 生成序列结束操码
└─ NO → 
   Temp = LineDelta - LineBase (-5)
   ├─ Temp >= LineRange? OR Temp + OpcodeBase > 255?
   │  ├─ YES → 发出 DW_LNS_advance_line + SLEB128(LineDelta)
   │  └─ NO → 继续
   │
   ├─ LineDelta == 0 && AddrDelta == 0?
   │  ├─ YES → 发出 DW_LNS_copy
   │  └─ NO → 继续
   │
   ├─ 尝试单个特殊操码
   │  opcode = Temp + AddrDelta * LineRange
   │  ├─ opcode <= 255?
   │  │  ├─ YES → 发出 <opcode>
   │  │  └─ NO → 继续
   │
   ├─ 尝试 const_add_pc优化
   │  opcode = Temp + (AddrDelta - MaxSpecialAddrDelta) * LineRange
   │  ├─ opcode <= 255?
   │  │  ├─ YES → 发出 [DW_LNS_const_add_pc, opcode]
   │  │  └─ NO → 继续
   │
   └─ 使用 DW_LNS_advance_pc
      发出 [DW_LNS_advance_pc, ULEB128(AddrDelta), Temp]
```

