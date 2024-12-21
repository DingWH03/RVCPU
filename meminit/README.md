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
    li      t3, 100             # 测试迭代次数

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
    10:        06400e13        addi x28 x0 100

00000014 <write_loop>:
    14:        0062a023        sw x6 0 x5
    18:        0002a383        lw x7 0 x5
    1c:        00730463        beq x6 x7 8 <correct>
    20:        0140006f        jal x0 20 <error>

00000024 <correct>:
    24:        00428293        addi x5 x5 4
    28:        fffe0e13        addi x28 x28 -1
    2c:        fe0e14e3        bne x28 x0 -24 <write_loop>

00000030 <end>:
    30:        00000013        addi x0 x0 0

00000034 <error>:
    34:        00000013        addi x0 x0 0

```

### 3. 十六进制机器码

```text
800002b7 12345337 67830313 00000393 06400e13 0062a023 0002a383 00730463
0140006f 00428293 fffe0e13 fe0e14e3 00000013 00000013
```