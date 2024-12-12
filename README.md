# RVCPU_DEMO

## 目录

- [简介](#简介)
- [功能](#功能)
- [运行代码](#运行代码)
- [指令集](#指令集)
- [许可证](#许可证)

## 简介

该项目是 RISC-V CPU 的DEMO，实现了核心功能并支持 RISC-V 处理器的一些典型功能。

这个文件是项目的指令集介绍以及基本实现情况，[文档](./docs/README.md)中进行介绍。

> checkout1分支中有单周期CPU的代码。

## 功能

### 已完成

- [x] 基本 ALU 操作（ADD、SUB、AND、OR、XOR）
- [x] 指令获取、解码、执行、内存和写回阶段
- [x] 立即数生成和处理
- [x] 寄存器文件读写操作
- [x] 加载和存储操作（LW、SW）
- [x] 跳转和分支处理（JAL、BEQ、BNE）
- [x] 系统总线，包括 ROM、DRAM 和外设
- [x] 用于流水线设计和冒险检测的控制单元
- [x] 所有 RV64I 指令的数据前递和控制冒险与结构冒险

### 正在进行中

- [ ] Uart串口通信
- [ ] 链接到 led 的 GPIO
- [ ] 支持其他 RISC-V 指令（例如乘法和除法）
- [ ] 指令和数据内存的缓存实现
- [ ] 异常和中断处理

### 计划实现功能

- [ ] CSR（控制和状态寄存器）支持
- [ ] 完全符合 RISC-V 特权规范

## 运行代码

> 流水线CPU仿真工具已更换为支持SystemVerilog的Verilator，需安装Verilator进行仿真，仍然可以使用[运行](#运行)这里的命令来仿真。

### 安装

目前使用 iverilog 进行模拟。

```bash
sudo apt install make iverilog gtkwave # 对于 debian/ubuntu
```

### 运行

```bash
make # 编译
make run # 生成output/waveform.vcd文件
```

然后你可以使用 gtkwave 观看波形。

## 指令集

> Risc-V 架构指令集参考[riscv-isa-pages](https://msyksphinz-self.github.io/riscv-isadoc/html/index.html)

已实现RV64I部分指令，未实现中断。

## 许可证

本项目采用 GPL-3.0 许可证。
