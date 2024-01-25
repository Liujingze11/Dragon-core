# 代码分析文档

## Table of Contents
- [Project Overview](#project-overview)
- [Team Members](#team-members)
- [Introduction to CVA6](#introduction-to-cva6)
- [Code analysis](#code-analysis)
  - [core](#core)
    - [frontend](#frontend-前端)
    - [cache_subsystem](#cache_subsystem)
  - [sw](#sw)

## Project Overview
4th national RISC-V student contest 2023-2024 in France
Accelerating AI applications on a RISC-V processor
The works of Dragon core

## Team Members
Liu Jingze
Zhang Yalei
Sun Yongxin

## Introduction to CVA6
CVA6 is a high-performance processor design that supports out-of-order and in-order execution. It is capable of handling advanced features such as branch prediction, instruction reordering, exception handling, and virtual memory support.
![RISC-V流水线](images/image1.png "流水线")


## Code Analysis

### core
在这里，详细描述文件夹core的代码实现和功能。例如：

#### frontend 前端
![RISC-V流水线](images/image2.jpeg "流水线")

- frontend文件夹是前端与译码阶段（Instruction Decode (ID)）
- bht.sv：分支历史表（Branch History Table, BHT）
- btb.sv：分支目标缓冲器（Branch Target Buffer, BTB）
两个部分用于分支预测
- instr_scan.sv：负责扫描、识别和处理即将进入译码阶段的指令。
- instr_queue.sv：指令队列（Instruction Queue）存储待处理的指令。
- fronted.sv：模块的接口定义和内部一些子模块的实例化。

#### cache_subsystem
![RISC-V流水线](images/image3.jpeg "流水线")

- Cache_subsystem 部分是处理器的缓存子系统，这部分是负责管理和提供 CPU 快速访问数据的组件。这个缓存子系统通常包括指令缓存（I-Cache）和数据缓存（D-Cache），它们分别缓存指令和数据，以减少处理器访问主内存的次数，从而提高效率。
- wt_dcache_ctrl.sv：DS Controller 控制数据缓存的逻辑，包括处理缓存一致性、读写请求等。
- wt_dcache_mem.sv：DS Mem 这部分代表数据缓存的内存接口，负责管理数据缓存与主内存或其他缓存级别之间的数据交换。
- wt_dcache_missunit.sv：DS Miss Unit 当处理器尝试从数据缓存中读取数据但未命中时，缺失单元会处理这个缺失，可能需要从主内存或更低级别的缓存中拉取数据。
- wt_dcache_wbuffer.sv：DS Buffer 缓冲区，用于优化数据写操作。在缓存无法立即写入时，数据可能首先写入这个缓冲区。
- wt_dcache.sv：
- wt_dcache_subsystem.sv：指令和数据缓存的管理逻辑，以及与内存接口的适配器逻辑。通过参数化设计，它能够适配不同的配置和内存系统接口。


### sw

同上，对组件2进行详细描述。



