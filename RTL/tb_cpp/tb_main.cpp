#include "verilated.h"
#include "verilated_vcd_c.h"
#include "VRVCPU.h" // 顶层模块由 Verilator 自动生成
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // 实例化顶层模块
    auto top = new VRVCPU;

    // 设置 VCD 波形跟踪
    auto tfp = new VerilatedVcdC;
    top->trace(tfp, 99); // 跟踪 99 层层次结构
    tfp->open("output/waveform.vcd");

    // 初始化信号
    vluint64_t sim_time = 0;
    top->clk = 0;
    top->rst = 1; // 初始复位信号高

    // 仿真循环
    while (!Verilated::gotFinish() && sim_time < 1100000) {
        // 每 5 个仿真时间单位翻转一次时钟
        if (sim_time % 5 == 0) {
            top->clk = !top->clk; // 翻转时钟
        }

        // 释放复位信号
        if (sim_time > 10) { // 保持复位信号高至少 10 个时间单位
            top->rst = 0; // 释放复位信号
        }
        
        top->eval();         // 评估模型
        tfp->dump(sim_time); // 转储跟踪数据
        sim_time++;
    }

    // 完成仿真
    tfp->close();
    delete tfp;
    delete top;

    std::cout << "Simulation completed." << std::endl;
    return 0;
}
