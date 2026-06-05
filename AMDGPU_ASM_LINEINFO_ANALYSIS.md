# LLVM AMDGPU后端汇编中的行号信息编码分析

## 执行摘要

LLVM AMDGPU后端在生成汇编代码时，通过**DWARF行表(Line Table)机制**编码行号信息。这些信息不直接出现在`.s`汇编文件中，而是通过以下两个通道传递：

1. **生成`.debug_line`段**：在编译时生成DWARF调试信息
2. **通过`.loc`伪指令**：在汇编源中标记关键位置（主要用于AIX等平台）

---

## 1. DILocation调试信息处理流程

### 1.1 高层架构

```
IR中的DILocation
    ↓
MachineInstr中的DebugLoc (机器指令级调试信息)
    ↓
AsmPrinter收集MCDwarfLoc信息
    ↓
MCDwarfLineTable编码为DWARF line table
    ↓
.debug_line段（二进制调试信息）
```

### 1.2 关键数据结构

#### MCDwarfLoc结构体
位置: `llvm/include/llvm/MC/MCDwarf.h`

```cpp
class MCDwarfLoc {
  uint32_t FileNum;           // 文件编号（1-based在DWARF4, 0-based在DWARF5）
  uint32_t Line;              // 源代码行号
  uint16_t Column;            // 列号
  uint8_t Flags;              // IS_STMT, BASIC_BLOCK, PROLOGUE_END, EPILOGUE_BEGIN
  uint8_t Isa;                // 指令集架构编号
  uint32_t Discriminator;     // DWARF4+: 用于区分同一行的多个逻辑实例（内联）
};
```

**标志定义**:
```cpp
#define DWARF2_FLAG_IS_STMT        (1 << 0)  // 是语句的开始
#define DWARF2_FLAG_BASIC_BLOCK    (1 << 1)  // 是基本块的开始
#define DWARF2_FLAG_PROLOGUE_END   (1 << 2)  // prolog结束
#define DWARF2_FLAG_EPILOGUE_BEGIN (1 << 3)  // epilog开始
```

#### MCDwarfLineEntry
```cpp
class MCDwarfLineEntry : public MCDwarfLoc {
  MCSymbol *Label;                    // 对应的代码标签（地址）
  MCSymbol *LineStreamLabel;          // 行流标签（用于DWO分割调试信息）
  SMLoc StreamLabelDefLoc;            // 标签定义位置
  bool IsEndEntry;                    // 是否为序列结束标记
};
```

---

## 2. 汇编文件中行号信息的编码格式

### 2.1 DWARF Line Table编码规范

DWARF Line Table使用**变长编码**和**特殊操码**来表示源代码位置与机器代码地址的映射。

#### 编码参数（在MCDwarfLineTableParams中定义）
```cpp
struct MCDwarfLineTableParams {
  uint8_t DWARF2LineOpcodeBase = 13;      // 特殊操码的基值
  int8_t DWARF2LineBase = -5;             // 行偏移的最小值
  uint8_t DWARF2LineRange = 14;           // 行偏移的范围
};
```

**含义**:
- 操码0-12是标准操码（如`DW_LNS_copy`, `DW_LNS_advance_pc`等）
- 操码13-255是特殊操码，可同时编码行增量和地址增量

### 2.2 特殊操码的编码公式

```
operand_count = (opcode - DWARF2LineOpcodeBase) / DWARF2LineRange
line_increment = (opcode - DWARF2LineOpcodeBase) % DWARF2LineRange + DWARF2LineBase
address_increment = operand_count  // 以DWARF2_LINE_MIN_INSN_LENGTH为单位
```

**反向**（编码时）:
```
opcode = DWARF2LineOpcodeBase + (line_delta - DWARF2LineBase) + 
         (address_delta * DWARF2LineRange)
```

**限制**: 
- 特殊操码只能表示范围内的行增量和地址增量
- 行增量范围: `[DWARF2LineBase, DWARF2LineBase + DWARF2LineRange - 1]` = `[-5, 8]`
- 若超出范围，使用标准操码 `DW_LNS_advance_line` (SLEB128编码)

### 2.3 重要的标准操码

| 操码 | 名称 | 参数 | 用途 |
|------|------|------|------|
| 1 | `DW_LNS_copy` | 无 | 产生当前line matrix的副本 |
| 2 | `DW_LNS_advance_pc` | ULEB128 | 增加address |
| 3 | `DW_LNS_advance_line` | SLEB128 | 增加line |
| 4 | `DW_LNS_set_file` | ULEB128 | 设置当前文件编号 |
| 5 | `DW_LNS_set_column` | ULEB128 | 设置当前列号 |
| 6 | `DW_LNS_negate_stmt` | 无 | 切换is_stmt标志 |
| 7 | `DW_LNS_set_basic_block` | 无 | 标记基本块开始 |
| 8 | `DW_LNS_const_add_pc` | 无 | 增加最大特殊操码地址 |
| 9 | `DW_LNS_fixed_advance_pc` | u16 | 增加固定地址 |
| 10 | `DW_LNS_set_prologue_end` | 无 | (DWARF3+) |
| 11 | `DW_LNS_set_epilogue_begin` | 无 | (DWARF3+) |
| 12 | `DW_LNS_set_isa` | ULEB128 | (DWARF3+) 设置ISA |

### 2.4 扩展操码（Extended Opcodes）

```
DW_LNE_* 操码需要前缀: DW_LNS_extended_op + ULEB128(size) + DW_LNE_*

主要扩展操码:
- DW_LNE_end_sequence:      结束当前行表序列
- DW_LNE_set_address:       设置绝对地址
- DW_LNE_define_file:       定义文件（DWARF2）
- DW_LNE_set_discriminator: (DWARF4+) 设置discriminator值
```

---

## 3. 行号编码的核心算法

### 3.1 MCDwarfLineAddr::encode实现

位置: `llvm/lib/MC/MCDwarf.cpp:775`

```cpp
void MCDwarfLineAddr::encode(MCContext &Context, MCDwarfLineTableParams Params,
                             int64_t LineDelta, uint64_t AddrDelta,
                             SmallVectorImpl<char> &Out) {
  // 步骤1: 特殊处理end_sequence信号 (LineDelta == INT64_MAX)
  if (LineDelta == INT64_MAX) {
    // 产生end_sequence扩展操码
    return;
  }

  // 步骤2: 检查行增量是否在特殊操码范围内
  Temp = LineDelta - Params.DWARF2LineBase;
  if (Temp >= Params.DWARF2LineRange || 
      Temp + Params.DWARF2LineOpcodeBase > 255) {
    // 行增量超出范围，使用DW_LNS_advance_line
    Out.push_back(dwarf::DW_LNS_advance_line);
    appendLEB128<LEB128Sign::Signed>(Out, LineDelta);
    LineDelta = 0;  // 重置为0，后续使用特殊操码
  }

  // 步骤3: 处理零增量情况
  if (LineDelta == 0 && AddrDelta == 0) {
    Out.push_back(dwarf::DW_LNS_copy);
    return;
  }

  // 步骤4: 尝试使用单个特殊操码
  Temp += Params.DWARF2LineOpcodeBase;
  if (AddrDelta < 256 + MaxSpecialAddrDelta) {
    Opcode = Temp + AddrDelta * Params.DWARF2LineRange;
    if (Opcode <= 255) {
      Out.push_back(Opcode);  // 单个字节
      return;
    }
  }

  // 步骤5: 使用DW_LNS_const_add_pc优化大地址增量
  if (Opcode <= 255) {
    Out.push_back(dwarf::DW_LNS_const_add_pc);
    Out.push_back(Opcode);
    return;
  }

  // 步骤6: 使用DW_LNS_advance_pc处理超大地址增量
  Out.push_back(dwarf::DW_LNS_advance_pc);
  appendLEB128<LEB128Sign::Unsigned>(Out, AddrDelta);
  Out.push_back(Temp);
}
```

**编码效率算法**：
1. 优先使用单字节特殊操码（最紧凑）
2. 其次使用 `DW_LNS_const_add_pc + 特殊操码`（两字节）
3. 最后使用 `DW_LNS_advance_pc + ULEB128`（可变长，但地址增量超大时必需）

### 3.2 行表生成流程

位置: `llvm/lib/MC/MCDwarf.cpp:178`

```cpp
void MCDwarfLineTable::emitOne(
    MCStreamer *MCOS, MCSection *Section,
    const MCLineSection::MCDwarfLineEntryCollection &LineEntries) {
  
  // 初始化line matrix
  uint32_t FileNum = 1, LastLine = 1, Column = 0;
  uint8_t Flags = DWARF2_FLAG_IS_STMT, Isa = 0;
  uint32_t Discriminator = 0;

  // 遍历每个行表项
  for (auto LineEntry : LineEntries) {
    // 检查文件编号变化
    if (FileNum != LineEntry.getFileNum()) {
      MCOS->emitInt8(dwarf::DW_LNS_set_file);
      MCOS->emitULEB128IntValue(LineEntry.getFileNum());
    }

    // 检查列号变化
    if (Column != LineEntry.getColumn()) {
      MCOS->emitInt8(dwarf::DW_LNS_set_column);
      MCOS->emitULEB128IntValue(LineEntry.getColumn());
    }

    // DWARF4+: 处理discriminator
    if (Discriminator != LineEntry.getDiscriminator() && 
        DwarfVersion >= 4) {
      MCOS->emitInt8(dwarf::DW_LNS_extended_op);
      MCOS->emitULEB128IntValue(Size + 1);
      MCOS->emitInt8(dwarf::DW_LNE_set_discriminator);
      MCOS->emitULEB128IntValue(LineEntry.getDiscriminator());
    }

    // 处理ISA变化
    if (Isa != LineEntry.getIsa()) {
      MCOS->emitInt8(dwarf::DW_LNS_set_isa);
      MCOS->emitULEB128IntValue(LineEntry.getIsa());
    }

    // 处理is_stmt标志
    if ((LineEntry.getFlags() ^ Flags) & DWARF2_FLAG_IS_STMT) {
      MCOS->emitInt8(dwarf::DW_LNS_negate_stmt);
    }

    // 处理基本块和prolog/epilog标记
    if (LineEntry.getFlags() & DWARF2_FLAG_BASIC_BLOCK)
      MCOS->emitInt8(dwarf::DW_LNS_set_basic_block);
    if (LineEntry.getFlags() & DWARF2_FLAG_PROLOGUE_END)
      MCOS->emitInt8(dwarf::DW_LNS_set_prologue_end);
    if (LineEntry.getFlags() & DWARF2_FLAG_EPILOGUE_BEGIN)
      MCOS->emitInt8(dwarf::DW_LNS_set_epilogue_begin);

    // 编码行和地址增量
    int64_t LineDelta = LineEntry.getLine() - LastLine;
    MCDwarfLineAddr::Emit(MCOS, Params, LineDelta, AddrDelta);

    LastLine = LineEntry.getLine();
  }
}
```

---

## 4. Inline关系和Call Stack表示

### 4.1 DWARF中的Inline支持

LLVM使用**DWARF抽象基准模型**表示inline关系链：

#### 核心概念

1. **抽象实例(Abstract Instance)**
   - 函数原型的单一定义
   - 包含完整的函数签名和位置信息
   - 用`DW_AT_abstract_origin`引用

2. **具体实例(Concrete Inlined Instance)**
   - 每次inline调用产生一个具体实例
   - 包含`DW_AT_abstract_origin`指向抽象实例
   - 包含`DW_AT_call_file`、`DW_AT_call_line`、`DW_AT_call_column`指向调用点

#### 数据结构

```cpp
// DIE属性（在.debug_info中编码）
DW_AT_abstract_origin    // 指向抽象实例的引用（offset）
DW_AT_call_site_parameter // 调用点参数
DW_AT_call_line          // 调用所在的源代码行
DW_AT_call_column        // 调用所在的列
DW_AT_call_file          // 调用所在的文件
DW_AT_range              // inline代码的地址范围
DW_AT_ranges             // 多个地址范围（DWARF3+）
```

### 4.2 Inline信息在.ll IR中的表示

```llvm
; 抽象实例（在函数定义处）
!10 = distinct !DISubprogram(
  name: "inline_func",
  file: !1,
  line: 42,
  type: !9,
  isDefinition: true
)

; 调用点
!DILocation(line: 50, column: 5, scope: !current_scope, inlinedAt: !inline_loc)
!inline_loc = !DILocation(line: 100, column: 10, scope: !caller_scope)
```

**映射到.debug_info**:
```
DW_TAG_inlined_subroutine
  DW_AT_abstract_origin -> DIE of "inline_func"
  DW_AT_call_line       -> 100
  DW_AT_call_file       -> 文件编号
  DW_AT_call_column     -> 10
  DW_AT_ranges          -> [addr_start, addr_end)
```

### 4.3 Discriminator用途

在DWARF4+中，**discriminator**字段用于区分同一源代码行但来自不同inline路径的多个逻辑实例：

```cpp
// 编码时
if (Discriminator != LineEntry.getDiscriminator() &&
    DwarfVersion >= 4) {
  MCOS->emitInt8(dwarf::DW_LNS_extended_op);
  MCOS->emitULEB128IntValue(Size + 1);
  MCOS->emitInt8(dwarf::DW_LNE_set_discriminator);
  MCOS->emitULEB128IntValue(LineEntry.getDiscriminator());
}
```

**应用场景**:
```
源代码: for (i = 0; i < n; i++)  { func1(); func2(); }
        主要产生两个line matrix项都是同一行，但来自不同的调用

line: 10, disc: 0 -> func1()调用
line: 10, disc: 1 -> func2()调用
```

---

## 5. .ll (LLVM IR) 与 汇编的映射关系

### 5.1 编译管道

```
.ll (LLVM IR with DILocation metadata)
  ↓
[LLVM CodeGen中间表示]
  ↓
MachineInstr (with DebugLoc)
  ↓
[AsmPrinter/codegen/DwarfDebug.cpp]
  ↓
MCDwarfLoc / MCDwarfLineEntry
  ↓
[codegen/AsmPrinter/MCDwarf.cpp]
  ↓
.s (Assembly) + .debug_line/.debug_info (Binary DWARF)
```

### 5.2 信息流

1. **.ll中的DILocation**
   ```llvm
   !loc = !DILocation(line: 42, column: 5, scope: !scope_metadata)
   ```

2. **机器代码级别**
   ```cpp
   MachineInstr MI(...);
   MI.setDebugLoc(DebugLoc::get(42, 5, scope_DINode, ...));
   ```

3. **汇编打印时生成MCDwarfLoc**
   ```cpp
   MCDwarfLoc DLoc(FileNum=1, Line=42, Column=5, Flags=IS_STMT, ...);
   MCDwarfLineEntry LineEntry(Label, DLoc);
   ```

4. **最终编码到.debug_line**
   ```
   [特殊或标准操码编码的行表数据]
   ```

### 5.3 关键转换点

| 层级 | 数据结构 | 关键信息 | 保留情况 |
|------|---------|---------|--------|
| .ll | `!DILocation` | line, column, scope, inlinedAt | ✓完整保留 |
| LLVM IR | `DebugLoc` | 行、列、scope DINode | ✓完整保留 |
| MachineInstr | `DebugLoc` | 行、列、scope对象指针 | ✓完整保留 |
| MCDwarf | `MCDwarfLoc` | 行、列、文件ID、flags | ✓转换保留 |
| Binary DWARF | LEB128编码的操码 | 增量值 | ✓紧凑保留 |

---

## 6. AMDGPU后端特定实现

### 6.1 AMDGPU汇编打印器

位置: `llvm/lib/Target/AMDGPU/AMDGPUAsmPrinter.cpp`

AMDGPU后端继承通用LLVM AsmPrinter框架，主要处理：
- 目标特定的汇编语法（`.amdgcn_target`, `.amdhsa_kernel`等）
- 硬件特定的寄存器和指令

**继承关系**:
```
AsmPrinter (通用框架，处理DWARF生成)
    ↓
AMDGPUAsmPrinter (AMDGPU特定语法)
```

### 6.2 调试信息处理流程（对AMDGPU）

```
llvm::FunctionPass: MachineModuleInfo
    ↓ 收集DILocation信息
MachineFunction with DebugLoc
    ↓
DwarfDebug::beginFunction()
    ↓
MCDwarfLineTable::emitOne()
    ↓
.debug_line段 (DWARF二进制格式，与架构无关)
```

### 6.3 .s文件中的行号编码

在标准的AMDGPU `.s`文件中：
- **不显示**.loc伪指令（不是AIX/PowerPC）
- **不编码二进制DWARF**到.s中
- 在**链接时**由链接器生成.debug_info/.debug_line段

要看到行号信息，需要：
```bash
# 生成带调试信息的object文件
llc -g input.ll -o output.o

# 查看DWARF调试信息
objdump --dwarf=line output.o | head -50
```

---

## 7. DWARF规范与AMDGPU的适配

### 7.1 DWARF版本支持

```cpp
// MCContext中设置
unsigned DwarfVersion;  // 通常为3, 4, 或5(LLVM 15+)

// DWARF4增加特性
- DW_AT_call_*属性（inline call site）
- DW_LNE_set_discriminator
- DW_AT_ranges支持

// DWARF5增加特性
- .debug_line_str段（字符串标准化）
- Dwarf5线表增强格式
```

### 7.2 平台差异

```cpp
// 在某些平台(AIX)中
void MCAsmStreamer::emitDwarfAdvanceLineAddr(...) {
  // 生成.loc伪指令到.s中
  AddComment("Set address to " + Label->getName());
  emitIntValue(dwarf::DW_LNS_extended_op, 1);
  ...
}

// 在AMDGPU(ELF)中
// AsmPrinter/DwarfDebug.cpp自动处理
// 生成二进制.debug_line段
```

### 7.3 地址大小

```cpp
unsigned PointerSize = asmInfo->getCodePointerSize();  
// AMDGPU: 通常为8字节（64位地址空间）

// 在编码时用于计算DW_LNE_set_address的大小
```

---

## 8. 实际示例

### 8.1 简单C代码

```c
// test.c
int main() {
    int x = 42;  // 行2
    return x;    // 行3
}
```

### 8.2 对应的LLVM IR (带DILocation)

```llvm
!1 = !DIFile(filename: "test.c", directory: "/home/user")
!2 = !DIBasicType(name: "int", ...)
!3 = !DISubprogram(name: "main", file: !1, line: 1, ...)

define i32 @main() !dbg !3 {
entry:
  %x = alloca i32, align 4, !dbg !10
  store i32 42, ptr %x, align 4, !dbg !10
  %0 = load i32, ptr %x, align 4, !dbg !11
  ret i32 %0, !dbg !11
}

!10 = !DILocation(line: 2, column: 5, scope: !3)
!11 = !DILocation(line: 3, column: 5, scope: !3)
```

### 8.3 编码到.debug_line

```
Header:
  version: 3 (或4/5)
  min_insn_length: 1
  initial_value_of_is_stmt: 1
  line_base: -5
  line_range: 14
  opcode_base: 13

Directory table:
  0: /home/user

File table:
  1: test.c (directory: 0)

Line number statements:
  DW_LNs_set_file 1          # 设置文件
  DW_LNE_set_address 0x0     # 设置起始地址
  DW_LNS_advance_line 1      # 推进到行2
  DW_LNS_copy               # 产生line matrix副本
  <特殊操码>                # 行增量=1, 地址增量=?
  DW_LNS_copy               # 行3处的copy
  DW_LNE_end_sequence       # 序列结束
```

### 8.4 编码验证

```python
def encode_special_opcode(line_delta, addr_delta, 
                          line_base=-5, line_range=14, opcode_base=13):
    """计算特殊操码"""
    adjusted_line = line_delta - line_base  # 7
    opcode = adjusted_line + addr_delta * line_range + opcode_base
    if 13 <= opcode <= 255:
        return bytes([opcode])
    else:
        # 需要DW_LNS_advance_line
        return None

# 从行2->行3，假设地址增量=1个指令
line_delta = 1
addr_delta = 1
opcode = 1 - (-5) + 1 * 14 + 13  # = 6 + 14 + 13 = 33
print(f"特殊操码: {opcode}")  # 输出: 结果33（0x21）
```

---

## 9. 诊断和调试

### 9.1 查看DWARF调试信息

```bash
# 显示.debug_line段
llvm-dwarfdump --debug-line output.o

# 显示.debug_info段(包含abstract origins)
llvm-dwarfdump --debug-info output.o | grep -A5 "DW_AT_call_"

# 查看原始字节
llvm-objdump -s -j .debug_line output.o
```

### 9.2 跟踪IR到汇编的映射

```bash
# 生成带调试信息的IR
clang -emit-llvm -g -c test.c -o test.ll

# 转换为汇编，启用DWARF调试信息
llc -g test.ll -o test.s

# 查看生成的对象文件中的调试段
llvm-readelf --debug-dump test.o | head -100
```

---

## 总结

| 方面 | 结论 |
|------|------|
| **行号编码方式** | DWARF Line Table，使用LEB128和特殊操码进行增量编码 |
| **编码参数** | LineBase=-5, LineRange=14, OpcodeBase=13 |
| **特殊操码** | 13-255，同时编码行增量[-5,8]和地址增量 |
| **Inline关系** | 通过DIE的`DW_AT_abstract_origin`和`DW_AT_call_*`属性表示 |
| **Call Stack** | 隐含在DIE树结构中，通过parent-child关系表达 |
| **Discriminator** | DWARF4+，用于区分同行多个inline路径，使用`DW_LNE_set_discriminator`编码 |
| **ir到汇编映射** | `!DILocation` → `DebugLoc` → `MCDwarfLoc` → `特殊操码` |
| **文件位置** | `.debug_line` (DWARF二进制段), `.debug_info` (DIE结构) |
| **与.s关系** | 标准.s文件中不显示行号编码（二进制），仅在编译到object时生成 |

