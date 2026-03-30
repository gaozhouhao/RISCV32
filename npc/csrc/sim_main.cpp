#include <assert.h>
#include <verilated.h>
#include <verilated_fst_c.h>
#include <nvboard.h>
#include "npc_include.h"
#include "svdpi.h"
#include <debug.h>
#include "npc_utils.h"
#include <stdio.h>
FILE *log_fp = stdout;
const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};    
const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};

VerilatedFstC* tfp = new VerilatedFstC;
//void nvboard_bind_all_pins(TOP_NAME* top);

int flag = 0;
void ebreak(svBit is_ebreak){ flag = is_ebreak; }

void sdb_mainloop();
void init_monitor(int, char *[]);
int is_exit_status_bad();
extern uint32_t memory[1<<28];

CPUArchState cpu = {.pc=0x80000000};

void exec_once() {
    top->clk = 1; top->eval(); contextp->timeInc(1);
    tfp->dump(contextp->time());
    top->clk = 0; top->eval(); contextp->timeInc(1);
    tfp->dump(contextp->time());
#ifdef CONFIG_ITRACE
    printf("0x%08X\n", top->rootp->top__DOT__inst);
#endif

    for (int i = 0; i < 32; i ++){
        cpu.gpr[i] = top->rootp->top__DOT__regfile__DOT__rf[i];
        cpu.gpr[0] = 0;
    }
    cpu.csr[0x300] = top->rootp->top__DOT__csr__DOT__mstatus;
    cpu.csr[0x305] = top->rootp->top__DOT__csr__DOT__mtvec;
    cpu.csr[0x341] = top->rootp->top__DOT__csr__DOT__mepc;
    cpu.csr[0x342] = top->rootp->top__DOT__csr__DOT__mcause;
    cpu.pc = top->pc;
    //printf("cpu.csr[0x305]:%x\n", cpu.csr[0x305]);
    static int cnt = 0;
    cnt ++;
    if(flag) npc_state.state = NPC_END;
}

static void reset(int n) {
    //dut.rst = 1;
    //while (n -- > 0) single_cycle();
    //dut.rst = 0;
}

int main(int argc, char** argv){
    int ret = 0;
    FILE *fp = NULL; 
    //nvboard_bind_all_pins(top.get());
    //nvboard_init();
#if CONFIG_GTKWAVE
    Verilated::mkdir("logs");
    contextp->traceEverOn(true);
    top->trace(tfp, 99);
    int cnt = 0;
    tfp->open("./build/obj_dir/wave.fst");
#endif
    printf("main-pc:\033[32m0x%08x\033[0m\n", cpu.pc);
    init_monitor(argc, argv);
    top->reset = 0; 
    top->clk = 1; top->eval();    contextp->timeInc(1);
    tfp->dump(contextp->time());
    top->clk = 0; top->eval();    contextp->timeInc(1);
    tfp->dump(contextp->time());
    top->reset = 1; top->eval(); contextp->timeInc(1);
    while (1) {
        sdb_mainloop();

        tfp->close();
        return is_exit_status_bad();
        //top->eval();
        //nvboard_update();
        tfp->dump(contextp->time());
    }
}
