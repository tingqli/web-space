# LLVM DWARF中的Inline关系链和Call Stack表示

## 概述

LLVM使用标准DWARF机制表示函数inline关系链和调用栈，分为两个层面：
1. **编译时**: DIE(Debug Information Entry)树结构
2. **运行时**: 结合.debug_line行表和.debug_info信息

---

## 1. Inline在LLVM IR中的表示

### 1.1 DISubprogram - 函数定义

```llvm
; 抽象实例(Abstract Instance): 被inline的函数的原型
!1 = distinct !DISubprogram(
  name: "inline_func",
  linkageName: "_Z11inline_funcii",
  file: !3,
  line: 10,
  type: !4,            ; 函数类型
  isDefinition: true,
  scopeLine: 10,
  flags: DIFlagPrototyped,
  spFlags: DISPFlagDefinition
)

; 调用者函数
!2 = distinct !DISubprogram(
  name: "main",
  file: !3,
  line: 20,
  type: !5,
  isDefinition: true
)
```

### 1.2 DILocation - 位置信息与Inline属性

```llvm
; 直接调用(非inline)
!loc1 = !DILocation(line: 50, column: 5, scope: !2)

; Inline调用：scope指向inline实例，inlinedAt指向调用点
!inline_scope = !DILexicalBlockFile(
  scope: !1,              ; scope在被inline的函数内
  file: !3,
  discriminator: 0
)
!loc2 = !DILocation(
  line: 25,               ; 被inline函数内的行号
  column: 10,
  scope: !inline_scope,   ; scope指向被inline的函数
  inlinedAt: !caller_loc  ; inlinedAt指向调用location
)

!caller_loc = !DILocation(
  line: 55,               ; 调用点所在的行
  column: 8,
  scope: !2               ; scope指向调用者函数
)
```

**关键区别**:
- **非inline**: `DILocation(line, column, scope)` - scope直接指向函数
- **Inline**: `DILocation(line, column, scope, inlinedAt)` - scope指向被inline函数, inlinedAt指回调用点

---

## 2. DIE(Debug Information Entry)树结构

### 2.1 抽象实例与具体实例

```
DW_TAG_compile_unit
├── DW_TAG_subprogram (main)
│   ├── DW_AT_name = "main"
│   ├── DW_AT_decl_line = 20
│   ├── DW_AT_type = int
│   └── [具体实例所对应的代码范围]
│
├── DW_TAG_subprogram (inline_func) [抽象实例]
│   ├── DW_AT_name = "inline_func"
│   ├── DW_AT_decl_line = 10
│   ├── DW_AT_type = int
│   ├── DW_AT_abstract_origin = (自身ID)
│   └── [DW_TAG_formal_parameter 参数列表]
│
└── [具体的inlined_subroutine会引用上面的abstract_origin]
```

### 2.2 完整示例：Inline调用的DIE树

```
DW_TAG_compile_unit
├── DW_TAG_subprogram (main)          ; 主函数
│   │ DW_AT_name = "main"
│   │ DW_AT_low_pc = 0x1000
│   │ DW_AT_high_pc = 0x1100
│   │
│   ├── DW_TAG_inlined_subroutine    ; inline call #1
│   │   │ DW_AT_abstract_origin = <ref to inline_func>
│   │   │ DW_AT_call_line = 55       ; 调用点行号
│   │   │ DW_AT_call_file = 1        ; 文件编号
│   │   │ DW_AT_call_column = 8      ; 列号
│   │   │ DW_AT_ranges = [0x1010-0x1030)
│   │   │
│   │   ├── DW_TAG_variable (函数局部变量)
│   │   │   └── DW_AT_name = "result"
│   │   │
│   │   └── DW_TAG_inlined_subroutine ; 嵌套inline call
│   │       │ DW_AT_abstract_origin = <ref to helper_func>
│   │       │ DW_AT_call_line = 12
│   │       │ DW_AT_ranges = [0x1020-0x1028)
│   │       └── ...
│   │
│   ├── DW_TAG_inlined_subroutine    ; inline call #2
│   │   │ DW_AT_abstract_origin = <ref to inline_func>
│   │   │ DW_AT_call_line = 70       ; 第二次调用
│   │   │ DW_AT_ranges = [0x1040-0x1050)
│   │   └── ...
│   │
│   └── DW_TAG_lexical_block         ; 其他作用域块
│       └── ...
│
├── DW_TAG_subprogram (inline_func)  ; 抽象实例
│   │ DW_AT_name = "inline_func"
│   │ DW_AT_type = int
│   │ DW_AT_decl_line = 10            ; 函数定义行
│   │
│   └── DW_TAG_formal_parameter
│       │ DW_AT_name = "x"
│       │ DW_AT_type = int
│       └── DW_AT_location = ...
│
└── DW_TAG_subprogram (helper_func)  ; 另一个被inline的函数
    └── ...
```

---

## 3. 属性详解：DW_AT_*

### 3.1 Inline相关的关键属性

| 属性 | 在什么DIE出现 | 含义 | 值类型 |
|-----|------------|------|--------|
| `DW_AT_abstract_origin` | inlined_subroutine, variable等 | 指向该DIE的抽象实例 | reference (offset) |
| `DW_AT_call_line` | inlined_subroutine | 调用点所在行号 | constant (ULEB128) |
| `DW_AT_call_file` | inlined_subroutine | 调用点所在文件编号 | constant (ULEB128) |
| `DW_AT_call_column` | inlined_subroutine | 调用点所在列号 | constant (ULEB128) |
| `DW_AT_call_target` | inlined_subroutine | 被调用的函数 (DWARF5) | reference |
| `DW_AT_call_return_pc` | inlined_subroutine | 返回地址 | address |
| `DW_AT_call_all_calls` | inlined_subroutine | 所有调用信息 | flag (DWARF5) |
| `DW_AT_noreturn` | subprogram | 函数不返回 | flag |

### 3.2 地址范围属性

```cpp
// 单一地址范围
DW_AT_low_pc  = 0x1000   ; 开始地址
DW_AT_high_pc = 0x1100   ; 结束地址(绝对)或长度(相对)

// 多个地址范围 (DWARF3+, 用于非连续代码)
DW_AT_ranges = offset_to_ranges_section
// 在.debug_ranges或.debug_rnglists中存储多个[addr_start, addr_end)对
```

---

## 4. 调用栈的重建算法

### 4.1 从二进制DWARF重建调用栈

```
给定: PC地址 (program counter)

Step 1: 在.debug_aranges中查找地址对应的CU (Compile Unit)
Step 2: 在CU的.debug_info中查找包含该PC的DIE
Step 3: 遍历DIE树:
  for each inlined_subroutine:
    if PC in DW_AT_ranges:
      输出调用栈项: 
        function = resolve(DW_AT_abstract_origin)
        call_site = (DW_AT_call_file, DW_AT_call_line, DW_AT_call_column)
        code_range = DW_AT_ranges
      递归进入该inlined_subroutine处理嵌套调用
```

### 4.2 Python伪代码

```python
def reconstruct_call_stack(pc, debug_info_section, debug_ranges_section):
    """从PC地址重建调用栈"""
    
    call_stack = []
    
    # Step 1: 查找CU
    cu = find_cu_for_address(pc, debug_info_section)
    if not cu:
        return None
    
    # Step 2: 遍历CU的DIE树
    def traverse_dies(die, pc):
        """递归遍历DIE树"""
        
        # 检查当前DIE是否包含该PC
        if die.tag == "DW_TAG_inlined_subroutine":
            # 检查地址范围
            if address_in_ranges(pc, die.get("DW_AT_ranges")):
                # 找到一个inline调用
                call_info = {
                    'function': get_abstract_instance(die),
                    'call_site': {
                        'file': die.get("DW_AT_call_file"),
                        'line': die.get("DW_AT_call_line"),
                        'column': die.get("DW_AT_call_column"),
                    },
                    'code_ranges': die.get("DW_AT_ranges"),
                }
                call_stack.append(call_info)
                
                # 递归处理子DIE (嵌套inline)
                for child in die.children:
                    traverse_dies(child, pc)
        
        elif die.tag == "DW_TAG_subprogram":
            # 处理函数作用域
            if address_in_ranges(pc, die.get("DW_AT_ranges")):
                for child in die.children:
                    traverse_dies(child, pc)
        
        # ... 其他DIE类型 ...
    
    # 从CU根开始遍历
    traverse_dies(cu.root_die, pc)
    
    return call_stack
```

### 4.3 地址范围查询(DW_AT_ranges)

```
.debug_ranges格式 (DWARF 3-4):
  [pair0_start, pair0_end)
  [pair1_start, pair1_end)
  ...
  [0x00000000, 0x00000000)  ; 结束标记

示例: inline_func在两个不相邻的代码块中
DW_AT_ranges = offset_into_debug_ranges

在.debug_ranges中:
  offset: 0x0100
    0x00001020  0x00001030   ; inline_func第一部分
    0x00001040  0x00001050   ; inline_func第二部分 (tail call optimization)
    0x00000000  0x00000000   ; 结束
```

---

## 5. Discriminator - 区分同行多个inline实例

### 5.1 问题场景

```c
// 同一行中的多个inline调用
result = inline_func(x) + inline_func(y);  // 行100

// 编译后生成的代码:
// 0x1010: call inline_func(x)
// 0x1020: call inline_func(y)

// 两个inline都对应行100，但需要区分
```

### 5.2 Discriminator编码

```llvm
; 第一个inline (x参数)
!loc1 = !DILocation(
  line: 100,
  column: 8,
  scope: !inline_scope,
  inlinedAt: !caller1,
  discriminator: 0  ; 第一个inline
)

; 第二个inline (y参数)
!loc2 = !DILocation(
  line: 100,
  column: 25,
  scope: !inline_scope,
  inlinedAt: !caller2,
  discriminator: 1  ; 第二个inline
)
```

### 5.3 在.debug_line中的编码

```
DW_LNS_extended_op
  <size>
  DW_LNE_set_discriminator
  <discriminator_value (ULEB128)>
```

---

## 6. 实际示例：C代码到DWARF的映射

### 6.1 C源代码

```c
// test.c
inline int inline_add(int a, int b) {
    return a + b;                           // 行3
}

int main() {
    int x = 10;
    int y = 20;
    int result = inline_add(x, y);          // 行9: inline调用点
    return result;                          // 行10
}

// 编译: gcc -g -O2 test.c -o test
```

### 6.2 LLVM IR (带DILocation)

```llvm
; 函数单元和类型定义
!0 = !DICompileUnit(...)
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)

; 抽象实例: inline_add
!3 = distinct !DISubprogram(
  name: "inline_add",
  linkageName: "_Z10inline_addii",
  file: !1,
  line: 1,
  type: !4,
  isDefinition: true,
  scopeLine: 1,
  flags: DIFlagPrototyped,
  spFlags: DISPFlagDefinition | DISPFlagOptimized
)

!4 = !DISubroutineType(types: !5)
!5 = !{!2, !2, !2}  ; 返回int, 参数int, int

; 参数定义
!6 = !DILocalVariable(name: "a", arg: 1, scope: !3, line: 1)
!7 = !DILocalVariable(name: "b", arg: 2, scope: !3, line: 1)

; 被inline的return语句的位置
!loc_inline_return = !DILocation(
  line: 3,              ; inline_add函数内的行3
  column: 12,
  scope: !3,            ; scope = inline_add
  inlinedAt: !10        ; inlinedAt指向main中的调用点
)

; main函数
!8 = distinct !DISubprogram(
  name: "main",
  file: !1,
  line: 6,
  type: !9,
  isDefinition: true,
  scopeLine: 6,
  spFlags: DISPFlagDefinition | DISPFlagOptimized
)

!9 = !DISubroutineType(types: !{!2})

; main中的调用点
!10 = !DILocation(
  line: 9,              ; 调用点在main中的行9
  column: 17,
  scope: !8             ; scope = main
)

; 在inline_add内的虚拟位置(当PC在inlined代码段时)
!loc_inlined_body = !DILocation(
  line: 3,              ; inline_add的行3
  column: 5,
  scope: !3,            ; scope = inline_add
  inlinedAt: !10        ; inline context = main line 9
)

define i32 @main() !dbg !8 {
entry:
  %x = alloca i32, align 4, !dbg !11
  store i32 10, i32* %x, align 4, !dbg !11
  %y = alloca i32, align 4, !dbg !12
  store i32 20, i32* %y, align 4, !dbg !12
  
  ; 被inline后的add操作
  %0 = load i32, i32* %x, align 4, !dbg !loc_inlined_body
  %1 = load i32, i32* %y, align 4, !dbg !loc_inlined_body
  %add = add i32 %0, %1, !dbg !loc_inline_return
  
  %result = alloca i32, align 4, !dbg !10
  store i32 %add, i32* %result, align 4, !dbg !10
  
  %2 = load i32, i32* %result, align 4, !dbg !13
  ret i32 %2, !dbg !13
}

!11 = !DILocation(line: 7, column: 9, scope: !8)
!12 = !DILocation(line: 8, column: 9, scope: !8)
!13 = !DILocation(line: 10, column: 5, scope: !8)
```

### 6.3 编译后的.debug_info DIE树

```
0x0000: DW_TAG_compile_unit
  DW_AT_producer = "clang version X.X.X"
  DW_AT_language = DW_LANG_C99
  DW_AT_name = "test.c"
  DW_AT_comp_dir = "/tmp"
  DW_AT_stmt_list = 0x00000000

0x0014: DW_TAG_base_type
  DW_AT_name = "int"
  DW_AT_encoding = DW_ATE_signed
  DW_AT_byte_size = 0x04

0x001b: DW_TAG_subprogram        ; inline_add (抽象实例)
  DW_AT_name = "inline_add"
  DW_AT_linkage_name = "_Z10inline_addii"
  DW_AT_decl_file = 0x00000001
  DW_AT_decl_line = 0x00000001
  DW_AT_type = <0x0014>
  DW_AT_external = true
  
0x0028:   DW_TAG_formal_parameter
  DW_AT_name = "a"
  DW_AT_decl_file = 0x00000001
  DW_AT_decl_line = 0x00000001
  DW_AT_type = <0x0014>

0x002f:   DW_TAG_formal_parameter
  DW_AT_name = "b"
  DW_AT_decl_file = 0x00000001
  DW_AT_decl_line = 0x00000001
  DW_AT_type = <0x0014>

0x0036: DW_TAG_subprogram        ; main (具体实例)
  DW_AT_name = "main"
  DW_AT_decl_file = 0x00000001
  DW_AT_decl_line = 0x00000006
  DW_AT_type = <0x0014>
  DW_AT_low_pc = 0x0000000000000000
  DW_AT_high_pc = 0x0000000000000030 (length)
  DW_AT_frame_base = DW_OP_reg7 DW_OP_breg7 8
  DW_AT_external = true
  
0x0055:   DW_TAG_variable
  DW_AT_name = "x"
  DW_AT_decl_file = 0x00000001
  DW_AT_decl_line = 0x00000007
  DW_AT_type = <0x0014>
  DW_AT_location = [0x00000000, 0x00000030): DW_OP_fbreg -4

0x0068:   DW_TAG_variable
  DW_AT_name = "y"
  DW_AT_decl_file = 0x00000001
  DW_AT_decl_line = 0x00000008
  DW_AT_type = <0x0014>
  DW_AT_location = [0x00000000, 0x00000030): DW_OP_fbreg -8

0x007b:   DW_TAG_inlined_subroutine  ; 被inline的inline_add调用
  DW_AT_abstract_origin = <0x001b>    ; 指向inline_add定义
  DW_AT_low_pc = 0x0000000000000008   ; 内联代码的地址范围
  DW_AT_high_pc = 0x0000000000000020 (length)
  DW_AT_call_file = 0x00000001
  DW_AT_call_line = 0x00000009        ; 调用点: 行9
  DW_AT_call_column = 0x0000000b      ; 调用点: 列17
  DW_AT_call_return_pc = 0x0000000000000020

0x009b:     DW_TAG_variable        ; inline_add中的局部变量在调用点的值
  DW_AT_abstract_origin = <0x0028>   ; 指向参数a的定义
  DW_AT_location = DW_OP_reg0        ; 在main中对应的位置

0x00a3:     DW_TAG_variable
  DW_AT_abstract_origin = <0x002f>   ; 指向参数b的定义
  DW_AT_location = DW_OP_reg1        ; 在main中对应的位置

0x00ab: Null (DIE树结束)
```

---

## 7. GDB/调试器如何使用这些信息

### 7.1 显示调用栈

```
(gdb) bt
#0  0x0000000000000015 in inline_add (a=10, b=20) at test.c:3
     inlined into main at test.c:9
#1  0x0000000000000030 in main () at test.c:6

(gdb) info frame 0
Stack frame at 0x7fffffffde50:
 pc = 0x15 in inline_add (test.c:3); saved rip = 0x30
 inlined in main() (test.c:9)
```

### 7.2 设置条件断点

```
(gdb) break test.c:3 if a > 15
Breakpoint will trigger when:
  - program counter在inline_add的地址范围内
  - 且调用来自main行9处
  - 且参数a具体值 > 15
```

### 7.3 源代码级调试步进

```
(gdb) step
在inline代码中单步时，显示inline_func的源行，
同时在bt中展示inline context
```

---

## 8. DWARF5增强

### 8.1 新属性

```cpp
DW_AT_call_target          ; 被调用目标 (reference)
DW_AT_call_all_calls       ; 所有调用总数 (flag)
DW_AT_call_origin          ; 调用来源 (reference)
DW_AT_call_tail_call       ; 尾调用优化 (flag)
```

### 8.2 新格式

```
.debug_line_str            ; 共享字符串表 (代替重复的文件名)
.debug_loclists_offsets    ; 位置列表偏移表 (替代debug_loc)
.debug_rnglists_offsets    ; 地址范围列表偏移表 (替代debug_ranges)
```

---

## 9. 总结对照表

| 概念 | LLVM IR表示 | DIE表示 | .debug_line表示 | 用途 |
|-----|-----------|--------|----------------|------|
| Inline调用点 | `inlinedAt` | `DW_TAG_inlined_subroutine` | `discriminator` | 指示调用发生的位置 |
| Inline函数 | `DISubprogram` | `DW_TAG_subprogram` + 参数 | 隐含在scope中 | 函数身份 |
| 调用点位置 | `!DILocation(inlinedAt)` | `DW_AT_call_line/file/column` | 行号信息 | 调试显示调用点 |
| 抽象原型 | `distinct !DISubprogram` | `DW_TAG_subprogram` (无地址) | 不适用 | 共享函数定义 |
| 具体实例 | 机器代码 + DebugLoc | `DW_TAG_inlined_subroutine` | 地址→行映射 | 运行时查询 |
| 嵌套inline | 递归`inlinedAt` | 子DIE树 | 递归discriminator | 支持inline-of-inline |
| 参数映射 | `DILocalVariable` | `DW_TAG_formal_parameter` + `DW_AT_abstract_origin` | 不适用 | 参数值查询 |
| 地址范围 | IR中隐含 | `DW_AT_ranges` (非连续代码) | `DW_LNE_set_address` | 非连续代码块映射 |

