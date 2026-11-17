# 一生一芯：RV32E 处理器设计与验证

这是我在“一生一芯”学习过程中维护的 RISC-V 处理器工程。项目从多周期处理器逐步扩展到顺序流水线，主要涉及处理器 RTL 设计、仿真调试、差分测试、缓存与分支预测，以及处理器接入 SoC 后的软件适配。

工程基于一生一芯及南京大学的教学项目搭建。NEMU、Abstract Machine、测试程序和 SoC 框架包含大量上游代码；我在这些基础上完成课程实验，并继续修改和扩展。各部分的来源见文末说明。

以下内容以当前 `master` 分支为准，其他分支保留了不同阶段的实现。

## 处理器设计

### 流水线与指令执行

处理器以 RV32E 为基础，使用 16 个 32 位通用寄存器，包含取指（IFU）、译码（IDU）、执行（EXU）、访存（LSU）和写回（WBU）模块。RTL 使用 Verilog 和 SystemVerilog 编写，顶层模块为 `ysyx_25120302`。

各级通过 `valid/ready` 信号传递指令和数据，以适应不同的存储器响应时间。译码阶段检测寄存器数据相关，在结果尚未写回时暂停后续指令；分支跳转或异常发生时，通过重定向和流水线冲刷调整执行流程。

目前包含整数运算、逻辑运算、移位、条件分支、跳转和加载／存储等指令的实现。CSR 相关逻辑包含 `CSRRW`、`CSRRS`，以及 `mstatus`、`mtvec`、`mepc`、`mcause` 等寄存器。CSR 更新、异常入口和 `MRET` 返回在写回阶段处理。

### 指令缓存与分支预测

SoC 配置下的取指路径接入了直接映射指令缓存。当前代码配置为 4 条缓存行，每行 16 字节，总容量为 64 字节。缓存缺失时通过 AXI 突发读取填充整条缓存行，并配合 `FENCE.I` 完成指令缓存失效和后续取指的同步。

条件分支预测使用带地址标签和目标地址的预测表，并通过两位饱和计数器判断跳转方向。当前预测表有 32 个表项，在执行阶段根据分支的实际结果更新；预测错误时重新取指。

### 总线与启动流程

处理器通过 AXI 接口接入 `ysyxSoC`，取指和数据访存请求经过仲裁后访问存储器及外设。

SoC 软件启动采用两级引导：第一级程序在 Flash 中执行，将第二级引导程序复制到 SRAM；第二级引导程序将应用程序的代码和数据搬运到 SDRAM，清零 BSS 段，再跳转到应用入口。相关实现位于 [启动代码](abstract-machine/am/src/riscv/ysyxsoc/bootloader.c) 和 [链接脚本](abstract-machine/scripts/ysyxsoc_linker.ld)。

## 仿真、调试与性能分析

仿真环境基于 Verilator，使用 C/C++ 编写仿真驱动，并通过 Makefile 管理构建和运行。

- **差分测试**：以本仓库中的 NEMU 为参考模型，在 RTL 指令提交时比较 PC 和 16 个通用寄存器的状态，用于定位指令执行错误。
- **交互调试**：提供单步执行、寄存器查看、表达式求值和监视点等功能。
- **执行跟踪**：支持指令、访存和函数调用跟踪，并可生成 FST 波形，通过 GTKWave 查看。
- **性能统计**：通过 DPI-C 记录周期数、提交指令数、各级暂停及访存等待等事件，统计 IPC、指令缓存命中率和缺失开销。
- **行为模型**：`cachesim` 和 `branchsim` 使用执行轨迹分析缓存配置与分支预测策略，辅助 RTL 设计。

差分测试、跟踪和波形等功能由 `npc/Kconfig` 中的选项控制，需要按用途启用。当前差分比较代码检查 PC 和通用寄存器，尚未启用 CSR 状态比较。

## 目录说明

| 路径 | 内容 |
| --- | --- |
| `npc/vsrc/` | 处理器、指令缓存、分支预测及总线相关 RTL |
| `npc/csrc/` | Verilator 仿真驱动、差分测试、调试器和性能统计 |
| `npc/tools/cachesim/` | 缓存行为模型与参数扫描脚本 |
| `npc/tools/branchsim/` | 分支预测行为模型与参数扫描脚本 |
| `npc/scripts/` | 构建配置、综合及静态时序分析相关脚本 |
| `nemu/` | 基于 NEMU 修改的指令集模拟器和参考模型 |
| `abstract-machine/` | 运行时环境、平台适配、启动代码和链接脚本 |
| `ysyxSoC/` | SoC 框架及外设，以子模块引入 |
| `riscv-tests-am/`、`riscv-arch-test-am/` | 适配 Abstract Machine 的指令测试集，以子模块引入 |

阅读处理器代码时，可以从 [顶层模块](npc/vsrc/ysyx_25120302.v) 开始，再依次查看 IFU、IDU、EXU、LSU 和 WBU。

## 运行方式

工程使用 Linux 开发环境。基本依赖包括 Git、GNU Make、GCC/G++、Verilator、Python，以及 Readline 和 ncurses 开发库。编译测试程序还需要支持 RV32E 的 RISC-V 交叉工具链；当前构建脚本使用 `riscv64-linux-gnu-` 前缀。

SoC 仿真还需要 NVBoard，以及生成好的 `ysyxSoC/build/ysyxSoCFull.v`。生成 SoC RTL 所需的工具和初始化步骤见 [ysyxSoC 的构建文件](https://github.com/gaozhouhao/ysyxSoC/blob/e11bbd218e27c5cc152a2be4286909ff4ad79eac/Makefile)。启用波形查看时需要 GTKWave。

### 获取工程并设置路径

```bash
git clone https://github.com/gaozhouhao/RISCV32.git
cd RISCV32
git submodule update --init --recursive

export NEMU_HOME="$PWD/nemu"
export AM_HOME="$PWD/abstract-machine"
export NPC_HOME="$PWD/npc"
```

`ysyxSoC` 子模块当前使用 SSH 地址，需要先配置 GitHub SSH 访问。运行 SoC 仿真时，还需将 `NVBOARD_HOME` 设置为本机 NVBoard 所在目录。

### 配置与运行

可以在仓库根目录打开仿真配置：

```bash
make -C npc ARCH=npc menuconfig
```

启用差分测试前，需要将 NEMU 配置为 RISC-V 32 位参考模型，并选择共享库构建目标。NPC 默认从以下位置加载参考模型：

```text
nemu/build/riscv32-nemu-interpreter-so
```

准备好与目标平台匹配的程序镜像后，可使用以下入口运行。请将示例路径替换为实际的镜像路径：

```bash
# 独立处理器仿真，镜像起始地址为 0x80000000
make -C npc ARCH=npc sim IMG=/path/to/npc-program.bin ARGS="-b"

# SoC 仿真，Flash 镜像起始地址为 0x30000000
make -C npc ARCH=ysyxsoc sim IMG=/path/to/soc-program.bin ARGS="-b"
```

`-b` 表示批量运行；去掉后进入交互调试。若已准备好 `am-kernels`，也可以在对应测试目录使用 `ARCH=riscv32e-npc` 或 `ARCH=riscv32e-ysyxsoc` 编译并运行程序，平台脚本会调用 NPC 仿真入口。

工程保留了一生一芯的实验记录机制，部分构建和仿真命令会在本地 `tracer-ysyx` 分支记录代码快照。

## 代码来源与致谢

本项目依托 [一生一芯](https://ysyx.oscc.cc/) 课程开展，使用或参考了以下项目：

- [NEMU](https://github.com/NJU-ProjectN/nemu)：指令集模拟器、参考模型、调试器和差分测试基础设施。
- [Abstract Machine](https://github.com/NJU-ProjectN/abstract-machine)：程序运行时、平台抽象和配套构建流程。
- [ysyxSoC](https://github.com/OSCPU/ysyxSoC)：SoC 集成框架及相关外设。
- [NVBoard](https://github.com/NJU-ProjectN/nvboard)：仿真中的虚拟外设。
- [riscv-tests-am](https://github.com/NJU-ProjectN/riscv-tests-am) 和 [riscv-arch-test-am](https://github.com/NJU-ProjectN/riscv-arch-test-am)：指令测试程序。

我的工作主要集中在处理器 RTL、流水线控制、指令缓存、分支预测，以及仿真环境、软件运行环境和性能分析工具的修改与扩展。其中部分实现参考了课程讲义和上游代码，具体以源码中的说明和提交记录为准。

仓库中各组件保留各自的版权和许可证。NEMU 及其衍生代码中的许可声明、[Abstract Machine 的许可证](abstract-machine/LICENSE)，以及各子模块和第三方组件的原有声明均应分别遵守。

