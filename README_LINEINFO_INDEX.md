# LLVM AMDGPU后端行号编码 - 文档索引

## 🎯 快速开始

### 我想要...

#### 🚀 5分钟快速上手
→ 开始 [快速参考指南 - 核心概念速记](#关键文档)

#### 📚 完整深度理解
→ 依序阅读:
1. [总结分析文档](#关键文档) - 全面系统的技术分析
2. [代码实现参考](#关键文档) - 源代码级别的实现细节
3. [Inline与调用栈](#关键文档) - 复杂的inline机制

#### 🔧 排查具体问题
→ 查看 [快速参考指南](#关键文档) 的"问题诊断指南"部分

#### 💻 查看源代码
→ 参考 [代码实现参考](#关键文档) 的"源文件追踪"和"关键函数速查"

---

## 关键文档

### 📖 1. 总结分析文档
**文件**: `AMDGPU_ASM_LINEINFO_ANALYSIS.md`

**内容**:
- 📋 执行摘要
- 1️⃣ DILocation调试信息处理流程
- 2️⃣ 汇编文件中行号信息的编码格式（**DWARF Line Table规范**）
- 3️⃣ 行号编码的核心算法（**MCDwarfLineAddr::encode实现**）
- 4️⃣ Inline关系和Call Stack表示（**DIE树结构**）
- 5️⃣ .ll IR与汇编的映射关系
- 6️⃣ AMDGPU后端特定实现
- 7️⃣ DWARF规范与AMDGPU的适配
- 8️⃣ 实际示例和诊断指南

**适合人群**: 需要全面了解行号编码机制的开发者

**关键输出**: DWARF特殊操码参数、编码公式、Inline属性

---

### 🔍 2. 代码实现参考
**文件**: `AMDGPU_LINEINFO_CODE_REFERENCE.md`

**内容**:
- 📂 源文件追踪和快速查阅
- 1️⃣ MCDwarfLoc数据结构详解
- 2️⃣ MCDwarfLineEntry - 行表项
- 3️⃣ MCDwarfLineTableParams - 编码参数
- 4️⃣ 行号编码算法 - **完整源码注释版本**
- 5️⃣ 行表生成 - **MCDwarfLineTable::emitOne详解**
- 6️⃣ 标准操码定义
- 7️⃣ LEB128编码实现
- 8️⃣ AMDGPU特定实现
- 9️⃣ 实际编码示例（计算过程）
- 🔟 调试技巧和Python验证脚本

**适合人群**: 需要深入代码级别理解的开发者、需要修改编码算法的工程师

**关键输出**: 源代码位置、函数调用链、具体编码步骤

---

### 🔗 3. Inline与调用栈详解
**文件**: `AMDGPU_INLINE_CALLSTACK.md`

**内容**:
- 1️⃣ Inline在LLVM IR中的表示 (**DILocation.inlinedAt**)
- 2️⃣ DIE(Debug Information Entry)树结构 (**abstract instance vs concrete instance**)
- 3️⃣ 关键属性详解 (DW_AT_abstract_origin, DW_AT_call_*, discriminator)
- 4️⃣ 调用栈重建算法 (**伪代码实现**)
- 5️⃣ Discriminator - 区分同行多个inline实例
- 6️⃣ **完整C代码示例** - 从源到DWARF的映射
- 7️⃣ GDB/调试器的使用方式
- 8️⃣ DWARF5增强特性
- 9️⃣ 对照汇总表

**适合人群**: 需要理解inline机制、调试inline代码、或实现inline支持的开发者

**关键输出**: DIE树结构、调用栈重建过程、inline关系编码方式

---

### ⚡ 4. 快速参考指南
**文件**: `AMDGPU_LINEINFO_QUICK_REFERENCE.md`

**内容**:
- 📋 核心概念速记（三层架构、两个关键机制）
- 📊 编码参数速查表（标准参数、地址增量计算）
- 🔎 代码实现快速查阅（源文件追踪、关键函数）
- 🐛 问题诊断指南（Q&A格式）
- 🔗 外部资源链接
- 💡 实战速记和常见值速查
- 📋 调试工具快速命令参考
- 📈 总结对比表

**适合人群**: 快速查询、问题诊断、常见操作的所有开发者

**适用场景**: 遇到问题时的第一参考、快速查询参数值、命令行工具使用

---

## 📊 文档使用矩阵

| 需求 | 文档1 | 文档2 | 文档3 | 文档4 |
|------|------|------|------|------|
| 理解行号编码原理 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐ |
| 查询源代码位置 | ⭐ | ⭐⭐⭐⭐ | ⭐ | ⭐⭐ |
| 学习inline机制 | ⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| 排查编码问题 | ⭐⭐⭐ | ⭐⭐ | ⭐ | ⭐⭐⭐⭐ |
| 快速查询参数 | ⭐ | ⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ |
| 实战代码修改 | ⭐⭐ | ⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐ |
| 理解调用栈 | ⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| 调试工具使用 | ⭐ | ⭐⭐ | ⭐ | ⭐⭐⭐⭐ |

---

## 🔍 主题索引

### 数据结构与类定义

| 主题 | 文档 | 位置 |
|-----|------|------|
| MCDwarfLoc定义 | 文档2 | 第1部分 |
| MCDwarfLineEntry | 文档2 | 第2部分 |
| MCDwarfLineTableParams | 文档2 | 第3部分 |
| DILocation (IR) | 文档3 | 第1部分 |
| DIE树结构 | 文档3 | 第2部分 |

### 算法与编码

| 主题 | 文档 | 位置 |
|-----|------|------|
| 特殊操码公式 | 文档1+文档4 | 第2+核心概念 |
| MCDwarfLineAddr::encode | 文档2 | 第4部分 |
| emitOne算法 | 文档2 | 第5部分 |
| 调用栈重建 | 文档3 | 第4部分 |
| Discriminator编码 | 文档3 | 第5部分 |

### DWARF细节

| 主题 | 文档 | 位置 |
|-----|------|------|
| Line Table规范 | 文档1 | 第2部分 |
| 标准操码 | 文档2 | 第6部分 |
| 扩展操码 | 文档1 | 第2.3 |
| LEB128编码 | 文档2 | 第7部分 |
| DWARF版本差异 | 文档1+文档3 | 第7+第8部分 |

### 实现细节

| 主题 | 文档 | 位置 |
|-----|------|------|
| AMDGPU特定 | 文档1+文档2 | 第6部分 |
| 源文件追踪 | 文档2+文档4 | 快速查阅+实战 |
| 关键函数 | 文档2+文档4 | 第4,5部分+速查 |
| 编译流程 | 文档1 | 第5部分 |

### 问题诊断

| 问题 | 文档 | 位置 |
|------|------|------|
| 行号编码验证 | 文档4 | 诊断Q1 |
| Inline不显示 | 文档3+文档4 | 第7部分+诊断Q2 |
| 地址映射失效 | 文档4 | 诊断Q3 |
| 操码编码失败 | 文档4 | 诊断Q4 |

---

## 🎓 学习路径示例

### 路径A: 从零开始深度学习（时间：2-3小时）

1. **启动** (5分钟)
   - 快速参考文档 → 核心概念速记
   - 了解三层架构和两个关键机制

2. **基础** (30分钟)
   - 快速参考文档 → 编码参数速查表
   - 总结分析文档 → 第1-2部分
   - 理解MCDwarfLoc和编码参数

3. **深化** (1小时)
   - 代码实现参考 → 第1-5部分
   - 快速参考文档 → 代码快速查阅
   - 跟踪源代码实现

4. **Inline** (30分钟)
   - Inline详解文档 → 第1-3部分
   - 总结分析文档 → 第4部分
   - 理解DIE树结构

5. **实践** (30分钟)
   - 快速参考文档 → 快速命令参考
   - 实际编译并观察llvm-dwarfdump输出
   - 验证学习成果

---

### 路径B: 现学现用（时间：20分钟）

1. **确认问题** (5分钟)
   - 快速参考文档 → 问题诊断指南

2. **查询参数** (5分钟)
   - 快速参考文档 → 编码参数速查表

3. **查看实现** (5分钟)
   - 代码实现参考 → 关键函数速查
   - 按需查看特定源文件

4. **验证** (5分钟)
   - 快速参考文档 → 实战速记
   - 运行诊断命令

---

### 路径C: 修改代码（时间：1-2小时）

1. **理解现状** (20分钟)
   - 代码实现参考 → 第1-3部分
   - 了解MCDwarfLoc和参数

2. **找到代码** (15分钟)
   - 代码实现参考 → 源文件追踪
   - 使用ide查看MCDwarf.cpp

3. **详细学习** (30分钟)
   - 代码实现参考 → 第4-5部分
   - 逐行阅读MCDwarfLineAddr::encode()

4. **实验验证** (30分钟)
   - 快速参考文档 → 实战速记
   - 编写Python验证脚本
   - 编译测试代码

5. **修改实现** (20分钟)
   - 按需修改源代码
   - 重新编译验证

---

## 📁 文档地理位置

所有文档存储在:
```
/root/tingqli/web-space/
├── AMDGPU_ASM_LINEINFO_ANALYSIS.md          (文档1 - 总结分析)
├── AMDGPU_LINEINFO_CODE_REFERENCE.md        (文档2 - 代码参考)
├── AMDGPU_INLINE_CALLSTACK.md               (文档3 - Inline详解)
├── AMDGPU_LINEINFO_QUICK_REFERENCE.md       (文档4 - 快速参考)
└── README_index.md                          (本索引文档)
```

直接在VS Code中打开或使用:
```bash
cd /root/tingqli/web-space
ls AMDGPU*.md
```

---

## 🔗 相关LLVM源文件速查

### 核心实现文件

```
llvm/include/llvm/MC/MCDwarf.h
└─ 定义: MCDwarfLoc, MCDwarfLineEntry, MCDwarfLineTableParams
   行数: ~700行

llvm/lib/MC/MCDwarf.cpp
├─ MCDwarfLineTable::emitOne()        [第178行]
├─ MCDwarfLineAddr::encode()          [第748行]
└─ MCDwarfLineTable::emit()           [第304行]
   行数: ~2000行

llvm/lib/MC/MCAsmStreamer.cpp
└─ MCAsmStreamer::emitDwarfAdvanceLineAddr() [第2687行]

llvm/lib/Target/AMDGPU/AMDGPUAsmPrinter.cpp
└─ AMDGPU特定实现 (继承自AsmPrinter)

llvm/lib/CodeGen/AsmPrinter/DwarfDebug.cpp
└─ 调试信息收集和DIE生成
```

### 头文件参考

```
llvm/include/llvm/BinaryFormat/Dwarf.h
└─ DWARF操码定义 (DW_LNS_*, DW_LNE_*)

llvm/include/llvm/IR/DebugInfo.h
└─ DILocation, DISubprogram等元数据定义
```

---

## 💡 常见查询快捷方式

### 我想知道...的源代码位置

| 想查询... | 参考 | 搜索词 |
|-----------|------|--------|
| MCDwarfLoc初始化 | 文档2第1部分 | "MCDwarfLoc construct" |
| 特殊操码计算 | 文档2第4部分 | "Opcode = Temp +" |
| 行表生成 | 文档2第5部分 | "MCDwarfLineTable::emitOne" |
| DWARF操码值 | 文档2第6部分 | "DW_LNS_*" |
| Inline支持 | 文档3第3部分 | "DW_AT_abstract_origin" |

### 我想要...的编码示例

| 想学... | 参考 | 章节 |
|--------|------|------|
| 特殊操码编码 | 文档2第9部分 | "场景: 简单的两行程序" |
| 大地址增量 | 文档2第9部分 | "场景: 大地址增量" |
| C到DWARF映射 | 文档3第6部分 | "完整示例" |
| 调用栈重建 | 文档3第4部分 | "Python伪代码" |

---

## 🌐 外部资源链接

### 官方文档
- DWARF标准: https://dwarfstd.org/
- LLVM官网: https://llvm.org/
- LLVM IR手册: https://llvm.org/docs/LangRef/

### FlyDSL资源
- FlyDSL文档: https://rocm.github.io/FlyDSL
- CLAUDE.md: /root/tingqli/FlyDSL/CLAUDE.md

### 相关技能
- 见FlyDSL项目的`.claude/skills/`目录下关于kernel调试等的文档

---

## 📞 获取帮助

### 快速诊断

遇到问题时:
1. 查看快速参考文档的"问题诊断指南"
2. 运行建议的诊断命令
3. 根据输出查找相关章节

### 提出问题

在提问时，请包含:
1. 使用的LLVM版本 (`llc --version`)
2. 编译命令
3. `llvm-dwarfdump`的输出
4. 期望的行为vs实际行为

---

## 版本历史

| 版本 | 日期 | 内容 |
|------|------|------|
| 1.0 | 2026-06-05 | 初始版本，包含4份详细文档 |

---

## 文档维护

**最后更新**: 2026年6月5日

**涵盖范围**:
- LLVM 15.x - 18.x (当前主流版本)
- DWARF 3, 4, 5
- AMDGPU MI308X, MI300X, MI350等GPU
- 按照FlyDSL项目的CLAUDE.md指南编写

**注意**: 某些实现细节可能因LLVM版本而异，使用时请参考特定版本的源代码。

