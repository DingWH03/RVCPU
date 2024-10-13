# RVCPU_DEMO

## Instrustion Set

RISC-V 64 with instruction of 32 bit

### RV64I

RISC-V 指令集架构 (ISA) 中，RV64I 是基本整数指令集的 64 位扩展。指令格式分为多种类型，每种类型用于不同的指令编码。以下是 U-type, B-type, R-type, I-type 和 S-type 指令格式的列表，它们分别表示了指令格式及其对应的指令。

### RISC-V 指令格式

![image](./Ref/images/riscv-inst-format.png)

### 指令

#### 1. U-type 指令 (Upper Immediate Type)

用于表示一个高 20 位立即数，通常用于构建绝对地址。

| 指令名  | 描述                           | 格式     |
|---------|--------------------------------|----------|
| `LUI`   | 加载高 20 位立即数             | U-type   |
| `AUIPC` | 加载高 20 位立即数，并加到 PC  | U-type   |

##### 2. B-type 指令 (Branch Type)

用于条件分支，计算分支目标地址。

| 指令名  | 描述                       | 格式     |
|---------|----------------------------|----------|
| `BEQ`   | 相等时分支                 | B-type   |
| `BNE`   | 不相等时分支               | B-type   |
| `BLT`   | 小于时分支                 | B-type   |
| `BGE`   | 大于或等于时分支           | B-type   |
| `BLTU`  | 无符号小于时分支           | B-type   |
| `BGEU`  | 无符号大于或等于时分支     | B-type   |

##### 3. R-type 指令 (Register Type)

用于寄存器之间的操作。

| 指令名  | 描述                         | 格式     |
|---------|------------------------------|----------|
| `ADD`   | 寄存器加法                   | R-type   |
| `SUB`   | 寄存器减法                   | R-type   |
| `SLL`   | 逻辑左移                     | R-type   |
| `SRL`   | 逻辑右移                     | R-type   |
| `SRA`   | 算术右移                     | R-type   |
| `SLT`   | 有符号比较                   | R-type   |
| `SLTU`  | 无符号比较                   | R-type   |
| `AND`   | 按位与                       | R-type   |
| `OR`    | 按位或                       | R-type   |
| `XOR`   | 按位异或                     | R-type   |

##### 4. I-type 指令 (Immediate Type)

用于立即数运算和内存访问。

| 指令名  | 描述                             | 格式     |
|---------|----------------------------------|----------|
| `ADDI`  | 立即数加法                       | I-type   |
| `SLTI`  | 立即数有符号比较                 | I-type   |
| `SLTIU` | 立即数无符号比较                 | I-type   |
| `ANDI`  | 立即数按位与                     | I-type   |
| `ORI`   | 立即数按位或                     | I-type   |
| `XORI`  | 立即数按位异或                   | I-type   |
| `SLLI`  | 立即数逻辑左移                   | I-type   |
| `SRLI`  | 立即数逻辑右移                   | I-type   |
| `SRAI`  | 立即数算术右移                   | I-type   |
| `LB`    | 载入一个字节                     | I-type   |
| `LH`    | 载入半字（16 位）                | I-type   |
| `LW`    | 载入一个字（32 位）              | I-type   |
| `LD`    | 载入一个双字（64 位）            | I-type   |
| `LBU`   | 载入无符号字节                   | I-type   |
| `LHU`   | 载入无符号半字（16 位）          | I-type   |
| `LWU`   | 载入无符号字（32 位）            | I-type   |
| `JALR`  | 通过寄存器跳转并链接             | I-type   |
| `ECALL` | 系统调用（进入内核态）           | I-type   |
| `EBREAK`| 调试断点                         | I-type   |

##### 5. S-type 指令 (Store Type)

用于将数据存储到内存中。

| 指令名  | 描述                         | 格式     |
|---------|------------------------------|----------|
| `SB`    | 存储一个字节                 | S-type   |
| `SH`    | 存储半字（16 位）            | S-type   |
| `SW`    | 存储一个字（32 位）          | S-type   |
| `SD`    | 存储一个双字（64 位）        | S-type   |

##### 6. J-type 指令 (Jump Type)

用于跳转指令。

| 指令名  | 描述                     | 格式     |
|---------|--------------------------|----------|
| `JAL`   | 无条件跳转并链接         | J-type   |
