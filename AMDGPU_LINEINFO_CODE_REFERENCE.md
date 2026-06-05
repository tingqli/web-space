# LLVM AMDGPU行号编码 - 代码实现参考

## 快速参考索引

### 核心源文件

```
LLVM/
├── include/llvm/MC/MCDwarf.h          # MCDwarfLoc, MCDwarfLineEntry定义
├── lib/MC/MCDwarf.cpp                 # 行表编码核心算法
├── lib/CodeGen/AsmPrinter/
│   ├── DwarfDebug.cpp                 # 调试信息收集和生成
│   ├── DwarfUnit.cpp                  # DIE生成
│   └── AsmPrinter.cpp                 # 通用汇编打印器
├── lib/Target/AMDGPU/
│   └── AMDGPUAsmPrinter.cpp           # AMDGPU特定汇编打印
└── lib/MC/MCAsmStreamer.cpp           # 汇编流输出处理
```

---

## 1. MCDwarfLoc数据结构详解

### 源码位置
`llvm/include/llvm/MC/MCDwarf.h: 114-185`

```cpp
/// Instances of this class represent the information from a
/// dwarf .loc directive.
class MCDwarfLoc {
private:
  uint32_t FileNum;           // 源文件编号
  uint32_t Line;              // 源代码行号
  uint16_t Column;            // 源代码列号
  uint8_t Flags;              // 行表标志
  uint8_t Isa;                // ISA编号（指令集版本）
  uint32_t Discriminator;     // 甄别器（DWARF4+inline）

  friend class MCContext;
  friend class MCDwarfLineEntry;

  MCDwarfLoc(unsigned fileNum, unsigned line, unsigned column, 
             unsigned flags, unsigned isa, unsigned discriminator)
      : FileNum(fileNum), Line(line), Column(column), 
        Flags(flags), Isa(isa), Discriminator(discriminator) {}

public:
  unsigned getFileNum() const { return FileNum; }
  unsigned getLine() const { return Line; }
  unsigned getColumn() const { return Column; }
  unsigned getFlags() const { return Flags; }
  unsigned getIsa() const { return Isa; }
  unsigned getDiscriminator() const { return Discriminator; }

  void setFileNum(unsigned fileNum) { FileNum = fileNum; }
  void setLine(unsigned line) { Line = line; }
  void setColumn(unsigned column) {
    assert(column <= UINT16_MAX);
    Column = column;
  }
  void setFlags(unsigned flags) {
    assert(flags <= UINT8_MAX);
    Flags = flags;
  }
  void setIsa(unsigned isa) {
    assert(isa <= UINT8_MAX);
    Isa = isa;
  }
  void setDiscriminator(unsigned discriminator) {
    Discriminator = discriminator;
  }
};
```

### 标志定义
位置: `llvm/include/llvm/MC/MCDwarf.h: 128-133`

```cpp
#define DWARF2_LINE_DEFAULT_IS_STMT 1

#define DWARF2_FLAG_IS_STMT (1 << 0)           // 语句开始
#define DWARF2_FLAG_BASIC_BLOCK (1 << 1)       // 基本块开始
#define DWARF2_FLAG_PROLOGUE_END (1 << 2)      // Prolog结束
#define DWARF2_FLAG_EPILOGUE_BEGIN (1 << 3)    // Epilog开始
```

---

## 2. MCDwarfLineEntry - 行表项

### 源码
`llvm/include/llvm/MC/MCDwarf.h: 188-210`

```cpp
class MCDwarfLineEntry : public MCDwarfLoc {
private:
  MCSymbol *Label;                    // 对应代码的符号标签
  
public:
  MCDwarfLineEntry(MCSymbol *label, const MCDwarfLoc loc,
                   MCSymbol *lineStreamLabel = nullptr,
                   SMLoc streamLabelDefLoc = {})
      : MCDwarfLoc(loc), Label(label), LineStreamLabel(lineStreamLabel),
        StreamLabelDefLoc(streamLabelDefLoc) {}

  MCSymbol *getLabel() const { return Label; }

  // 用于分割调试信息(DWO)
  MCSymbol *LineStreamLabel;
  SMLoc StreamLabelDefLoc;

  // 序列结束标记
  bool IsEndEntry = false;

  void setEndLabel(MCSymbol *EndLabel) {
    assert(LineStreamLabel == nullptr);
    Label = EndLabel;
    IsEndEntry = true;
  }

  LLVM_ABI static void make(MCStreamer *MCOS, MCSection *Section);
};
```

---

## 3. MCDwarfLineTableParams - 编码参数

### 源码
`llvm/include/llvm/MC/MCDwarf.h: 233-249`

```cpp
struct MCDwarfLineTableParams {
  /// DWARF2行表操码的基值
  /// 0-12: 标准操码
  /// 13-255: 特殊操码
  uint8_t DWARF2LineOpcodeBase = 13;

  /// 行增量基值(Bias)
  /// 范围: [LineBase, LineBase + LineRange - 1]
  /// 对AMDGPU: [-5, 8]
  int8_t DWARF2LineBase = -5;

  /// 行增量范围大小
  /// 分子部分: (opcode - OpcodeBase) % LineRange
  /// 对AMDGPU: 14
  uint8_t DWARF2LineRange = 14;
};
```

**含义详解**:
```
特殊操码可表示的行增量范围 = [LineBase, LineBase + LineRange - 1]
                              = [-5, 8]

地址增量公式 = (opcode - OpcodeBase) / LineRange
             = (opcode - 13) / 14
```

---

## 4. 行号编码算法 - MCDwarfLineAddr::encode

### 完整源码
`llvm/lib/MC/MCDwarf.cpp: 748-843`

```cpp
/// Utility function to encode a Dwarf pair of LineDelta and AddrDeltas.
void MCDwarfLineAddr::encode(MCContext &Context, 
                             MCDwarfLineTableParams Params,
                             int64_t LineDelta, 
                             uint64_t AddrDelta,
                             SmallVectorImpl<char> &Out) {
  uint64_t Temp, Opcode;
  bool NeedCopy = false;

  // 计算最大特殊操码可表示的地址增量
  uint64_t MaxSpecialAddrDelta = SpecialAddr(Params, 255);
  
  // 地址增量进行最小指令长度缩放
  AddrDelta = ScaleAddrDelta(Context, AddrDelta);

  // ===== 特殊处理: 序列结束信号 =====
  if (LineDelta == INT64_MAX) {
    if (AddrDelta == MaxSpecialAddrDelta)
      Out.push_back(dwarf::DW_LNS_const_add_pc);
    else if (AddrDelta) {
      Out.push_back(dwarf::DW_LNS_advance_pc);
      appendLEB128<LEB128Sign::Unsigned>(Out, AddrDelta);
    }
    Out.push_back(dwarf::DW_LNS_extended_op);
    Out.push_back(1);
    Out.push_back(dwarf::DW_LNE_end_sequence);
    return;
  }

  // ===== 步骤1: 行增量偏置调整 =====
  Temp = LineDelta - Params.DWARF2LineBase;

  // ===== 步骤2: 检查行增量范围 =====
  // 如果超出特殊操码范围，使用标准操码DW_LNS_advance_line
  if (Temp >= Params.DWARF2LineRange ||
      Temp + Params.DWARF2LineOpcodeBase > 255) {
    // 发出DW_LNS_advance_line,参数为SLEB128编码的行增量
    Out.push_back(dwarf::DW_LNS_advance_line);
    appendLEB128<LEB128Sign::Signed>(Out, LineDelta);

    LineDelta = 0;
    Temp = 0 - Params.DWARF2LineBase;
    NeedCopy = true;  // 稍后需要DW_LNS_copy
  }

  // ===== 步骤3: 处理零增量情况 =====
  if (LineDelta == 0 && AddrDelta == 0) {
    Out.push_back(dwarf::DW_LNS_copy);
    return;
  }

  // ===== 步骤4: 加入特殊操码基值 =====
  Temp += Params.DWARF2LineOpcodeBase;

  // ===== 步骤5: 尝试单个特殊操码 =====
  if (AddrDelta < 256 + MaxSpecialAddrDelta) {
    Opcode = Temp + AddrDelta * Params.DWARF2LineRange;
    if (Opcode <= 255) {
      // 成功编码为单字节特殊操码
      Out.push_back(Opcode);
      return;
    }

    // 尝试: DW_LNS_const_add_pc + 特殊操码
    Opcode = Temp + (AddrDelta - MaxSpecialAddrDelta) * Params.DWARF2LineRange;
    if (Opcode <= 255) {
      Out.push_back(dwarf::DW_LNS_const_add_pc);
      Out.push_back(Opcode);
      return;
    }
  }

  // ===== 步骤6: 最后手段 - 使用DW_LNS_advance_pc =====
  Out.push_back(dwarf::DW_LNS_advance_pc);
  appendLEB128<LEB128Sign::Unsigned>(Out, AddrDelta);

  if (NeedCopy)
    Out.push_back(dwarf::DW_LNS_copy);
  else {
    assert(Temp <= 255 && "Buggy special opcode encoding.");
    Out.push_back(Temp);
  }
}
```

### 辅助函数

```cpp
/// 计算特殊操码对应的地址增量
static uint64_t SpecialAddr(MCDwarfLineTableParams Params, uint64_t op) {
  return (op - Params.DWARF2LineOpcodeBase) / Params.DWARF2LineRange;
}

// 对于op=255:
// SpecialAddr(Params, 255) = (255 - 13) / 14 = 242 / 14 = 17
```

---

## 5. 行表生成 - MCDwarfLineTable::emitOne

### 核心逻辑
`llvm/lib/MC/MCDwarf.cpp: 178-307`

```cpp
void MCDwarfLineTable::emitOne(
    MCStreamer *MCOS, MCSection *Section,
    const MCLineSection::MCDwarfLineEntryCollection &LineEntries) {

  // ===== 初始化行表状态机 =====
  unsigned FileNum = 1;
  unsigned LastLine = 1;
  unsigned Column = 0;
  unsigned Flags = DWARF2_LINE_DEFAULT_IS_STMT ? DWARF2_FLAG_IS_STMT : 0;
  unsigned Isa = 0;
  unsigned Discriminator = 0;
  MCSymbol *PrevLabel = nullptr;
  bool IsAtStartSeq = true;

  bool EndEntryEmitted = false;

  // ===== 遍历每个行表项 =====
  for (auto It = LineEntries.begin(); It != LineEntries.end(); ++It) {
    auto LineEntry = *It;
    MCSymbol *CurrLabel = LineEntry.getLabel();

    // 处理行流标签（用于DWO分割调试信息）
    if (LineEntry.LineStreamLabel) {
      if (!IsAtStartSeq) {
        MCOS->emitDwarfLineEndEntry(Section, PrevLabel, CurrLabel);
        // 重置状态机
      }
      MCOS->emitLabel(LineEntry.LineStreamLabel, LineEntry.StreamLabelDefLoc);
      continue;
    }

    // 处理序列结束项
    if (LineEntry.IsEndEntry) {
      MCOS->emitDwarfAdvanceLineAddr(INT64_MAX, PrevLabel, CurrLabel,
                                     asmInfo->getCodePointerSize());
      EndEntryEmitted = true;
      continue;
    }

    // ===== 发出属性变化操码 =====

    // 文件编号变化
    if (FileNum != LineEntry.getFileNum()) {
      FileNum = LineEntry.getFileNum();
      MCOS->emitInt8(dwarf::DW_LNS_set_file);
      MCOS->emitULEB128IntValue(FileNum);
    }

    // 列号变化
    if (Column != LineEntry.getColumn()) {
      Column = LineEntry.getColumn();
      MCOS->emitInt8(dwarf::DW_LNS_set_column);
      MCOS->emitULEB128IntValue(Column);
    }

    // Discriminator变化 (DWARF4+)
    if (Discriminator != LineEntry.getDiscriminator() &&
        MCOS->getContext().getDwarfVersion() >= 4) {
      Discriminator = LineEntry.getDiscriminator();
      unsigned Size = getULEB128Size(Discriminator);
      MCOS->emitInt8(dwarf::DW_LNS_extended_op);
      MCOS->emitULEB128IntValue(Size + 1);
      MCOS->emitInt8(dwarf::DW_LNE_set_discriminator);
      MCOS->emitULEB128IntValue(Discriminator);
    }

    // ISA变化 (DWARF3+)
    if (Isa != LineEntry.getIsa()) {
      Isa = LineEntry.getIsa();
      MCOS->emitInt8(dwarf::DW_LNS_set_isa);
      MCOS->emitULEB128IntValue(Isa);
    }

    // is_stmt标志变化
    if ((LineEntry.getFlags() ^ Flags) & DWARF2_FLAG_IS_STMT) {
      Flags = LineEntry.getFlags();
      MCOS->emitInt8(dwarf::DW_LNS_negate_stmt);
    }

    // 基本块、Prolog/Epilog标志
    if (LineEntry.getFlags() & DWARF2_FLAG_BASIC_BLOCK)
      MCOS->emitInt8(dwarf::DW_LNS_set_basic_block);
    if (LineEntry.getFlags() & DWARF2_FLAG_PROLOGUE_END)
      MCOS->emitInt8(dwarf::DW_LNS_set_prologue_end);
    if (LineEntry.getFlags() & DWARF2_FLAG_EPILOGUE_BEGIN)
      MCOS->emitInt8(dwarf::DW_LNS_set_epilogue_begin);

    // ===== 编码行和地址增量 =====
    int64_t LineDelta = static_cast<int64_t>(LineEntry.getLine()) - LastLine;
    MCOS->emitDwarfAdvanceLineAddr(LineDelta, PrevLabel, CurrLabel,
                                   asmInfo->getCodePointerSize());

    Discriminator = 0;
    LastLine = LineEntry.getLine();
    PrevLabel = CurrLabel;
    IsAtStartSeq = false;
  }

  // 生成序列结束项
  if (!EndEntryEmitted && !IsAtStartSeq)
    MCOS->emitDwarfLineEndEntry(Section, PrevLabel);
}
```

---

## 6. 标准操码定义

### DWARF标准操码
`llvm/include/llvm/BinaryFormat/Dwarf.h`

```cpp
namespace dwarf {
  // 标准line opcodes (0-12)
  enum LineNumberOps {
    DW_LNS_extended_op = 0,           // 0: 扩展操码
    DW_LNS_copy = 1,                  // 1: 产生line matrix副本
    DW_LNS_advance_pc = 2,            // 2: 增加address (ULEB128)
    DW_LNS_advance_line = 3,          // 3: 增加line (SLEB128)
    DW_LNS_set_file = 4,              // 4: 设置file (ULEB128)
    DW_LNS_set_column = 5,            // 5: 设置column (ULEB128)
    DW_LNS_negate_stmt = 6,           // 6: 反转is_stmt
    DW_LNS_set_basic_block = 7,       // 7: 设置basic_block标志
    DW_LNS_const_add_pc = 8,          // 8: 增加最大特殊操码地址
    DW_LNS_fixed_advance_pc = 9,      // 9: 增加固定地址 (u16)
    DW_LNS_set_prologue_end = 10,     // 10: (DWARF3+)
    DW_LNS_set_epilogue_begin = 11,   // 11: (DWARF3+)
    DW_LNS_set_isa = 12,              // 12: (DWARF3+) 设置ISA
  };

  // 扩展操码 (在DW_LNS_extended_op之后)
  enum LineNumberExtendedOps {
    DW_LNE_end_sequence = 1,
    DW_LNE_set_address = 2,
    DW_LNE_define_file = 3,
    DW_LNE_set_discriminator = 4,     // (DWARF4+)
    ...
  };
}
```

---

## 7. LEB128编码

### 无符号LEB128 (ULEB128)
```cpp
void appendLEB128<LEB128Sign::Unsigned>(
    SmallVectorImpl<char> &Out, uint64_t Value) {
  while (Value >= 0x80) {
    Out.push_back((Value & 0x7F) | 0x80);
    Value >>= 7;
  }
  Out.push_back(Value & 0x7F);
}

// 示例: 300
// 二进制: 0001 0010 1100
// 分组: 0010 1100 | 0000 0010
// ULEB128: 0xAC 0x02 (300 >= 128, 所以第一字节高位=1)
```

### 有符号LEB128 (SLEB128)
```cpp
void appendLEB128<LEB128Sign::Signed>(
    SmallVectorImpl<char> &Out, int64_t Value) {
  bool More = true;
  while (More) {
    uint8_t Byte = Value & 0x7F;
    Value >>= 7;
    
    // 检查是否更多字节
    More = !(((Value == 0) && ((Byte & 0x40) == 0)) ||
             ((Value == -1) && ((Byte & 0x40) != 0)));
    
    if (More)
      Byte |= 0x80;
    Out.push_back(Byte);
  }
}

// 示例: -50
// Twos补码: 显示...11001110
// SLEB128: 0x7E (因为(-50) & 0x7F = 0x7E, 符号位需要)
```

---

## 8. AMDGPU特定实现

### AMDGPUAsmPrinter

**关键方法**:
```cpp
// lib/Target/AMDGPU/AMDGPUAsmPrinter.cpp

class AMDGPUAsmPrinter : public AsmPrinter {
public:
  void emitFunctionBodyStart() override;      // DWARF调试信息开始
  void emitFunctionBodyEnd() override;        // DWARF调试信息结束
  void emitFunctionEntryLabel() override;     // 入口标签
  
  // 继承自AsmPrinter的DWARF支持
  // DwarfDebug和MCDwarfLineTable在这里自动工作
};
```

**继承关系**:
```
AsmPrinter (llvm/CodeGen/AsmPrinter)
    ↓ 包含DwarfDebug成员
    ↓
AMDGPUAsmPrinter (llvm/Target/AMDGPU/AMDGPUAsmPrinter)
    ↓
编输DWARF行表 (通过MCDwarfLineTable::emitOne)
```

---

## 9. 实际编码示例

### 场景: 简单的两行程序

```c
// line1: int x = 42;
// line2: return x;
```

**参数**:
```
LineBase = -5
LineRange = 14
OpcodeBase = 13
AddrDelta = 2 (两条指令)
LineDelta = 1
```

**计算过程**:
```
1. 调整行增量: Temp = 1 - (-5) = 6
2. 检查范围: 6 < 14, 且 6 + 13 = 19 < 255 ✓
3. 计算操码: opcode = 6 + 2 * 14 + 13 = 47 (0x2F)
4. 输出: 单字节 0x2F
```

**验证解码**:
```
opcode = 0x2F = 47
addr_delta = (47 - 13) / 14 = 34 / 14 = 2
line_delta = (47 - 13) % 14 + (-5) = 8 + (-5) = 1 ✓
```

### 场景: 大地址增量

```
LineDelta = 1
AddrDelta = 50 (大地址跨度)
MaxSpecialAddrDelta = (255 - 13) / 14 = 17
```

**计算过程**:
```
1. 50 > 256 + 17? No, 进入第一个if
2. opcode = 6 + 50 * 14 + 13 = 713 > 255 ✗
3. 尝试DW_LNS_const_add_pc:
   opcode = 6 + (50 - 17) * 14 + 13 = 475 > 255 ✗
4. 使用DW_LNS_advance_pc:
   输出: [DW_LNS_advance_pc(2), ULEB128(50), 0x06]
```

---

## 10. 调试技巧

### 编码验证脚本 (Python)

```python
def spec_opcode(line_delta, addr_delta, 
                line_base=-5, line_range=14, opcode_base=13):
    """计算DWARF特殊操码"""
    adjusted_line = line_delta - line_base
    opcode = adjusted_line + addr_delta * line_range + opcode_base
    return opcode if 13 <= opcode <= 255 else None

def decode_opcode(opcode, 
                  line_base=-5, line_range=14, opcode_base=13):
    """解码特殊操码"""
    adjusted_opcode = opcode - opcode_base
    line_inc = (adjusted_opcode % line_range) + line_base
    addr_inc = adjusted_opcode // line_range
    return (line_inc, addr_inc)

# 测试
print(f"Encode(1, 2): {spec_opcode(1, 2)}")  # 输出: 47
print(f"Decode(47): {decode_opcode(47)}")    # 输出: (1, 2)
```

### llvm-readelf查看调试信息

```bash
# 查看详细的行表信息
llvm-dwarfdump --debug-line test.o

# 查看特定格式
llvm-dwarfdump --debug-line=verbose test.o

# 查看原始字节
od -x .debug_line部分
```

---

## 总结表

| 代码位置 | 责任 |
|---------|------|
| `MCDwarfLoc` | 存储单条行表项的属性(行, 列, 文件等) |
| `MCDwarfLineEntry` | 关联行表项与代码地址(Label) |
| `MCDwarfLineTable::emitOne` | 遍历行表项，发出属性变化操码 |
| `MCDwarfLineAddr::encode` | 核心编码: 行和地址增量→字节流 |
| `特殊操码(13-255)` | 同时编码行增量[-5,8]和地址增量[0,17] |
| `DWARF操码(0-12)` | 标准操码处理超出范围的属性变化 |
| `.debug_line段` | 最终二进制DWARF行表数据 |

