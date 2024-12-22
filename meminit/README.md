# 测试指令

## 一、计算fibnacci数列前十项

### 1. 汇编代码

```asm
.globl _start

_start:
    # 初始化数据存储器起始地址
    lui x1, 0x80000          # x1 = 0x80000000 (数据存储器起始地址)

    # 初始化第一个斐波那契数列值
    li x10, 0                # x10 = 0 (fib(0))
    li x11, 1                # x11 = 1 (fib(1))
    li x12, 10               # x12 = 10 (计算前10项，用户可调整)

    # 串口基地址
    lui x2, 0x50000          # x2 = 0x50000000 (串口基地址)

    # 写入初始值到数据存储器
    sw x10, 0(x1)            # 存储 fib(0) 到 0x80000000
    addi x1, x1, 4           # 地址加 4
    sw x11, 0(x1)            # 存储 fib(1) 到 0x80000004
    addi x1, x1, 4           # 地址加 4

fib_loop:
    # 检查计数是否结束
    addi x12, x12, -1        # x12 -= 1
    beq x12, x0, tx         # 如果 x12 == 0, 跳转到结束

    # 计算下一个斐波那契数
    add x30, x10, x11        # x30 = x10 + x11 (下一个数)
    mv x10, x11              # x10 = x11
    mv x11, x30              # x11 = x30

    # 写入结果到数据存储器
    sw x30, 0(x1)            # 存储结果到内存
    addi x1, x1, 4           # 地址加 4

    # 继续循环
    j fib_loop

tx:
    # 向串口发送最后的 x30
    sw x30, 0(x2)            # 写入 x30 到串口地址 0x50000000
    j end
end:
    # 停机 (进入无限循环)
    j end
```

### 2. 翻译后的代码

```text
00000000 <_start>:
    0:        800000b7        lui x1 0x80000
    4:        00000513        addi x10 x0 0
    8:        00100593        addi x11 x0 1
    c:        00a00613        addi x12 x0 10
    10:        50000137        lui x2 0x50000
    14:        00a0a023        sw x10 0 x1
    18:        00408093        addi x1 x1 4
    1c:        00b0a023        sw x11 0 x1
    20:        00408093        addi x1 x1 4

00000024 <fib_loop>:
    24:        fff60613        addi x12 x12 -1
    28:        00060e63        beq x12 x0 28 <tx>
    2c:        00b50f33        add x30 x10 x11
    30:        00058513        addi x10 x11 0
    34:        000f0593        addi x11 x30 0
    38:        01e0a023        sw x30 0 x1
    3c:        00408093        addi x1 x1 4
    40:        fe5ff06f        jal x0 -28 <fib_loop>

00000044 <tx>:
    44:        01e12023        sw x30 0 x2
    48:        0040006f        jal x0 4 <end>

0000004c <end>:
    4c:        0000006f        jal x0 0 <end>
```

### 3. 十六进制机器码

```text
800000b7 00000513 00100593 00a00613 50000137
00a0a023 00408093 00b0a023 00408093 fff60613
00060e63 00b50f33 00058513 000f0593 01e0a023
00408093 fe5ff06f 01e12023 0040006f 0000006f
```

## 二、测试乘除法指令

### 1. 翻译后的代码

```text
    0:        00a00293        addi x5 x0 10
    4:        00300313        addi x6 x0 3
    8:        ff600393        addi x7 x0 -10
    c:        00000e13        addi x28 x0 0
    10:        02628eb3        mul x29 x5 x6
    14:        02639f33        mulh x30 x7 x6
    18:        0263afb3        mulhsu x31 x7 x6
    1c:        0262ceb3        div x29 x5 x6
    20:        0262df33        divu x30 x5 x6
    24:        0262efb3        rem x31 x5 x6
    28:        03c2ceb3        div x29 x5 x28
    2c:        03c2ef33        rem x30 x5 x28
    30:        fd1ff06f        jal x0 -48 <_start>
```

### 2. 十六进制机器码

```text
00a00293 00300313 ff600393 00000e13 02628eb3 02639f33 0263afb3 0262ceb3 0262df33 0262efb3 03c2ceb3 03c2ef33 fd1ff06f
```

## 三、访存测试指令

### 1. 汇编代码

```asm
    .text
    .globl _start

_start:
    # 初始化寄存器
    li      t0, 0x80000000      # DRAM 起始地址
    li      t1, 0x12345678      # 要写入的数据值
    li      t2, 0x0             # 用于读取的数据值
    li      t3, 10000             # 测试迭代次数

write_loop:
    # 向 DRAM 写数据
    sw      t1, 0(t0)           # 将 t1 中的数据存入 t0 地址（即 DRAM 地址）
    
    # 读取 DRAM 数据
    lw      t2, 0(t0)           # 从 t0 地址读取数据到 t2

    # 检查读取的数据是否正确
    beq     t1, t2, correct     # 如果写入的数据和读取的数据相同，跳转到 correct 标签

    # 如果数据不一致，跳转到 error
    j       error

correct:
    # 数据正确，输出下一次的写入
    addi    t0, t0, 4           # 增加地址偏移，指向下一个地址
    addi    t3, t3, -1          # 迭代次数减 1
    bnez    t3, write_loop      # 如果 t3 不为零，继续循环

end:
    # 程序结束，可以添加终止程序的指令（例如，在模拟器中停止）
    nop

error:
    # 错误处理，可以跳转到错误标记或输出错误信息
    nop

```

### 2. 翻译后的代码

```text

00000000 <_start>:
    0:        800002b7        lui x5 0x80000
    4:        12345337        lui x6 0x12345
    8:        67830313        addi x6 x6 1656
    c:        00000393        addi x7 x0 0
    10:        00002e37        lui x28 0x2
    14:        710e0e13        addi x28 x28 1808

00000018 <write_loop>:
    18:        0062a023        sw x6 0 x5
    1c:        0002a383        lw x7 0 x5
    20:        00730463        beq x6 x7 8 <correct>
    24:        0140006f        jal x0 20 <error>

00000028 <correct>:
    28:        00428293        addi x5 x5 4
    2c:        fffe0e13        addi x28 x28 -1
    30:        fe0e14e3        bne x28 x0 -24 <write_loop>

00000034 <end>:
    34:        00000013        addi x0 x0 0

00000038 <error>:
    38:        00000013        addi x0 x0 0
```

### 3. 十六进制机器码

```text
800002b7 12345337 67830313 00000393 00002e37 710e0e13  
0062a023 0002a383 00730463 0140006f 00428293 fffe0e13  
fe0e14e3 00000013 00000013  
```

## 四、使用串口发送Hello,world

### 1. 汇编

```asm
.globl _start

# 定义 UART 基地址
.equ UART_BASE, 0x50000000
.equ UART_TX_DATA, UART_BASE       # 数据寄存器
.equ UART_STATUS, 0x50000004    # 状态寄存器
.equ UART_TX_BUSY_BIT, 31          # TX_BUSY 位位置

_start:
    # 初始化字符串和寄存器
    li x1, 0x48                    # x1 = 'H' (ASCII: 0x48)
    li x2, 0x65                    # x2 = 'e' (ASCII: 0x65)
    li x3, 0x6C                    # x3 = 'l' (ASCII: 0x6C)
    li x4, 0x6C                    # x4 = 'l' (ASCII: 0x6C)
    li x5, 0x6F                    # x5 = 'o' (ASCII: 0x6F)
    li x6, 0x2C                    # x6 = ',' (ASCII: 0x2C)
    li x7, 0x20                    # x7 = ' ' (ASCII: 0x20)
    li x8, 0x77                    # x8 = 'w' (ASCII: 0x77)
    li x9, 0x6F                    # x9 = 'o' (ASCII: 0x6F)
    li x10, 0x72                   # x10 = 'r' (ASCII: 0x72)
    li x11, 0x6C                   # x11 = 'l' (ASCII: 0x6C)
    li x12, 0x64                   # x12 = 'd' (ASCII: 0x64)
    li x13, 0x0A                   # x13 = '\n' (ASCII: 0x0A)

    # 加载 UART 寄存器地址
    li x14, UART_TX_DATA           # UART 数据寄存器地址
    li x15, UART_STATUS            # UART 状态寄存器地址

    # 初始化计数器
    li x16, 13                     # x16 = 字符数量（计数器）
    li x17, 0                      # x17 = 当前发送索引

send:
    # 判断是否发送完成
    beq x17, x16, end              # 如果索引等于计数器，则跳转到 end

    # 将字符加载到 x31（发送寄存器）
    addi x31, x0, 0                 # 清零 t0->x31
    addi x31, x1, 0                # x31 = x1 + 偏移量
    # 进行寄存器平移（x1 -> x0, x2 -> x1, ..., x13 -> x12）
    addi x0, x1, 0                 # x1 = x0
    add x1, x2, x0                 # x2 = x1
    add x2, x3, x0                 # x3 = x2
    add x3, x4, x0                 # x4 = x3
    add x4, x5, x0                 # x5 = x4
    add x5, x6, x0                 # x6 = x5
    add x6, x7, x0                 # x7 = x6
    add x7, x8, x0                 # x8 = x7
    add x8, x9, x0                 # x9 = x8
    add x9, x10, x0                # x10 = x9
    add x10, x11, x0               # x11 = x10
    add x11, x12, x0               # x12 = x11
    add x12, x13, x0               # x13 = x12

    # 等待 TX 不忙
wait_tx:
    lw x30, 0(x15)                  # 读取 UART 状态寄存器
    srai x30, x30, UART_TX_BUSY_BIT  # 提取 TX_BUSY 位
    andi x30, x30, 1                 # 判断 TX_BUSY 是否为 1
    bnez x30, wait_tx               # 如果忙，继续等待

    # 写入数据寄存器
    sb x31, 0(x14)                  # 将字符写入 UART 数据寄存器

    # 增加索引，发送下一个字符
    addi x17, x17, 1               # 索引加 1
    j send                         # 跳转到 send 发送下一个字符

end:
    j end                          # 程序结束，进入死循环

```

### 2. 翻译后

```text

00000000 <_start>:
    0:        04800093        addi x1 x0 72
    4:        06500113        addi x2 x0 101
    8:        06c00193        addi x3 x0 108
    c:        06c00213        addi x4 x0 108
    10:        06f00293        addi x5 x0 111
    14:        02c00313        addi x6 x0 44
    18:        02000393        addi x7 x0 32
    1c:        07700413        addi x8 x0 119
    20:        06f00493        addi x9 x0 111
    24:        07200513        addi x10 x0 114
    28:        06c00593        addi x11 x0 108
    2c:        06400613        addi x12 x0 100
    30:        00a00693        addi x13 x0 10
    34:        50000737        lui x14 0x50000
    38:        500007b7        lui x15 0x50000
    3c:        00478793        addi x15 x15 4
    40:        00d00813        addi x16 x0 13
    44:        00000893        addi x17 x0 0

00000048 <send>:
    48:        05088e63        beq x17 x16 92 <end>
    4c:        00000f93        addi x31 x0 0
    50:        00008f93        addi x31 x1 0
    54:        00008013        addi x0 x1 0
    58:        000100b3        add x1 x2 x0
    5c:        00018133        add x2 x3 x0
    60:        000201b3        add x3 x4 x0
    64:        00028233        add x4 x5 x0
    68:        000302b3        add x5 x6 x0
    6c:        00038333        add x6 x7 x0
    70:        000403b3        add x7 x8 x0
    74:        00048433        add x8 x9 x0
    78:        000504b3        add x9 x10 x0
    7c:        00058533        add x10 x11 x0
    80:        000605b3        add x11 x12 x0
    84:        00068633        add x12 x13 x0

00000088 <wait_tx>:
    88:        0007af03        lw x30 0 x15
    8c:        41ff5f13        srai x30 x30 31
    90:        001f7f13        andi x30 x30 1
    94:        fe0f1ae3        bne x30 x0 -12 <wait_tx>
    98:        01f70023        sb x31 0 x14
    9c:        00188893        addi x17 x17 1
    a0:        fa9ff06f        jal x0 -88 <send>

000000a4 <end>:
    a4:        0000006f        jal x0 0 <end>

```

### 3. 机器语言

```text
04800093 06500113 06c00193 06c00213 06f00293 02c00313 02000393 07700413 06f00493 07200513 06c00593 06400613 00a00693 50000737 500007b7 00478793 00d00813 00000893 05088e63 00000f93 00008f93 00008013 000100b3 00018133 000201b3 00028233 000302b3 00038333 000403b3 00048433 000504b3 00058533 000605b3 00068633 0007af03 41ff5f13 001f7f13 fe0f1ae3 01f70023 00188893 fa9ff06f 0000006f

```

## 五、测试RV64I简单运算

### 1. 汇编代码

```asm
    .globl _start

_start:
    # 测试加法
    li x1, 5           # x1 = 5
    li x2, 7           # x2 = 7
    add x3, x1, x2     # x3 = x1 + x2 = 5 + 7 = 12

    # 测试减法
    li x4, 10          # x4 = 10
    li x5, 3           # x5 = 3
    sub x6, x4, x5     # x6 = x4 - x5 = 10 - 3 = 7

    # 测试乘法
    li x7, 6           # x7 = 6
    li x8, 9           # x8 = 9
    mul x9, x7, x8     # x9 = x7 * x8 = 6 * 9 = 54

    # 测试按位与、或、异或
    li x10, 0b10101010  # x10 = 0b10101010
    li x11, 0b11001100  # x11 = 0b11001100
    and x12, x10, x11  # x12 = x10 & x11 = 0b10001000
    or  x13, x10, x11  # x13 = x10 | x11 = 0b11101110
    xor x14, x10, x11  # x14 = x10 ^ x11 = 0b01100110

    # 测试加载/存储
    li x15, 0x80000000      # x15 = 0x80000000 (地址)
    li x16, 42          # x16 = 42 (数据)
    sw x16, 0(x15)      # 将 42 存储到地址 0x1000
    lw x17, 0(x15)      # 从地址 0x1000 加载数据到 x17（x17 应该等于 42）

    # 测试条件跳转
    li x18, 0           # x18 = 0
    li x19, 1           # x19 = 1
    beq x18, x19, equal # 如果 x18 == x19，则跳转到 equal 标签
    li x20, 10          # 如果 x18 != x19，则设置 x20 = 10

equal:
    li x21, 20          # 如果跳转到 equal，设置 x21 = 20

    # 测试无条件跳转
    j done               # 跳转到 done 标签

done:
    li x22, 99          # 设置 x22 = 99（表示程序结束）

```

### 2. 翻译代码

```text

00000000 <_start>:
    0:        00500093        addi x1 x0 5
    4:        00700113        addi x2 x0 7
    8:        002081b3        add x3 x1 x2
    c:        00a00213        addi x4 x0 10
    10:        00300293        addi x5 x0 3
    14:        40520333        sub x6 x4 x5
    18:        00600393        addi x7 x0 6
    1c:        00900413        addi x8 x0 9
    20:        028384b3        mul x9 x7 x8
    24:        0aa00513        addi x10 x0 170
    28:        0cc00593        addi x11 x0 204
    2c:        00b57633        and x12 x10 x11
    30:        00b566b3        or x13 x10 x11
    34:        00b54733        xor x14 x10 x11
    38:        800007b7        lui x15 0x80000
    3c:        02a00813        addi x16 x0 42
    40:        0107a023        sw x16 0 x15
    44:        0007a883        lw x17 0 x15
    48:        00000913        addi x18 x0 0
    4c:        00100993        addi x19 x0 1
    50:        01390463        beq x18 x19 8 <equal>
    54:        00a00a13        addi x20 x0 10

00000058 <equal>:
    58:        01400a93        addi x21 x0 20
    5c:        0040006f        jal x0 4 <done>

00000060 <done>:
    60:        06300b13        addi x22 x0 99

```

### 3. 机器代码

```text
00500093 00700113 002081b3 00a00213 00300293 40520333 00600393 
00900413 028384b3 0aa00513 0cc00593 00b57633 00b566b3 00b54733 
800007b7 02a00813 0107a023 0007a883 00000913 00100993 01390463 
00a00a13 01400a93 0040006f 06300b13

```
