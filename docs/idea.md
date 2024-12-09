# Recently ideas

## 1. 拆分成九级流水线

### 使用 struct 封装流水线阶段信号

## 2. 将dram和rom从sys_bus中移出

## 3. dram与rom在if中的选择通过地址判断ifp

## 4. dram与perips访问在mem一分为二的流水线中进行

dram访问靠后，system_bus靠前，因为外设访问可能单周期就能完成

现在需要完成I-cache和D-cache的设计

## 5. 完成I-cache与D-cache

## 6. 完成乱序执行

## 7. 完成中断请求

## 8. 可选定义CPU位数
