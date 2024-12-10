# Recently ideas

## 1. 拆分成九级流水线

可能需要先实现保留站才能完成九级流水线了

先使用流水线暂停的手段让九级流水线工作

同时还要完成cache

### 使用 struct 封装流水线阶段信号

## 2. 将dram和rom从sys_bus中移出

## 3. dram与rom在if中的选择通过地址判断ifp

## 4. dram与perips访问在mem一分为二的流水线中进行

同时访问，前一周期提出访问请求，后一周期检查访问是否完成

现在需要完成I-cache和D-cache的设计

## 5. 完成I-cache与D-cache

## 6. 完成乱序执行

## 7. 完成中断请求

## 8. 可选定义CPU位数
