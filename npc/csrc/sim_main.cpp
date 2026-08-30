#include <assert.h>
#include <cpu/decode.h>
#include <verilated.h>
#include <verilated_fst_c.h>
#include "npc_include.h"
#include "npc_memory.h"
#include "svdpi.h"
#include <debug.h>
#include "npc_utils.h"
#include <stdio.h>
#include "monitor/sdb/sdb.h"

#ifdef ARCH_YSYXSOC
#include <nvboard.h>
#endif
const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};    
const std::unique_ptr<TOP_NAME> top{new TOP_NAME{contextp.get(), "TOP"}};

VerilatedFstC* tfp = new VerilatedFstC;

#if CONFIG_NVBOARD
    void nvboard_bind_all_pins(TOP_NAME* top);
#endif
int flag = 0;
void ebreak(svBit is_ebreak){ flag = is_ebreak; }

void sdb_mainloop();
void init_monitor(int, char *[]);
int is_exit_status_bad();
extern uint32_t memory[1<<28];

extern "C" void flash_read(int32_t addr, int32_t *data) {
    *data = flash[addr >> 2];
}
extern "C" void mrom_read(int32_t addr, int32_t *data) { 
    *data = mrom[(addr - MROM_ADDR) >> 2];
}

uint32_t current_inst = 0;
extern "C" void get_inst(int inst) {
    current_inst = (uint32_t)inst;
};

static uint64_t perf_cnt[16] = {};
extern "C" void perf_event(int event_id) {
    perf_cnt[event_id]++;
}

void print_perf_cnt();
CPUArchState cpu = {.pc=RESET_PC};

void exec_once(Decode *s) {
    s->pc = DUT_PC;
    top->clock = 0; top->eval(); contextp->timeInc(1);
    IFDEF(CONFIG_GTKWAVE, tfp->dump(contextp->time()));
    top->clock = 1; top->eval(); 
    contextp->timeInc(1);
    
    IFDEF(CONFIG_GTKWAVE, tfp->dump(contextp->time()));
    IFDEF(CONFIG_NVBOARD, nvboard_update());
    if(DUT_ALLOW_FETCH) {
        s->inst = current_inst;
    }
    if(DUT_INST_DONE) {
        s->dnpc = DUT_NEXT_PC;
        s->pc = s->dnpc;
    }
    //s->snpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__next_pc;

#ifdef CONFIG_FTRACE
    static int call_depth = 0;
    if(DUT_INST_VALID) {
        if((s->inst & 0x7f) == 0x6f) { //jal
            if (((s->inst >> 7) & 0x1f) == 0x1) { // rd = 1, call
                printf("0x%08x:", s->pc);
                for (int i = 0; i < call_depth; i ++) printf("  ");
                    printf("call [%s@0x%08x]\n", find_func(s->pc), s->dnpc);
                call_depth ++;
            }
        }
        if((s->inst & 0x7f) == 0x67) { //jalr
            if (((s->inst >> 7) & 0x1f) == 0x1) { // rd = 1, call
                printf("0x%08x:", s->pc);
                for (int i = 0; i < call_depth; i ++) printf("  ");
                    printf("call [%s@0x%08x]\n", find_func(s->pc), s->dnpc);
                call_depth ++;
            }
        }
    }
    if(DUT_INST_VALID) {
        if((s->inst & 0x7f) == 0x67) { //jalr
            if (((s->inst >> 7) & 0x1f) == 0x0 &&
                ((s->inst >> 15) & 0x1f) == 0x1 &&
                ((s->inst >> 20) & 0xfff) == 0x0) { // rd = 0 && rs1 = 1 && imm = 0, ret
                    call_depth --;
                    printf("0x%08x:", s->pc);
                    for (int i = 0; i < call_depth; i ++) printf("  ");
                    printf("ret [%s]\n", find_func(s->dnpc));
            }
        }
    }
#endif
    
#ifdef CONFIG_ITRACE
    if (DUT_INST_VALID) {
        char *p = s->logbuf;
        p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":\t", s->pc);
        int i;

        uint8_t *inst = (uint8_t *)&s->inst;
        for (i = 3; i >= 0; i --) {
            p += snprintf(p, 4, " %02x", inst[i]);
        }
        p += snprintf(p, 3, "\t ");

        void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
        disassemble(p, s->logbuf + sizeof(s->logbuf) - p, s->pc, (uint8_t *)&s->inst, 4);
    }
    itrace_push(s->logbuf);
#endif

    for (int i = 0; i < 32; i ++){
        cpu.gpr[i] = DUT_RF[i];
        cpu.gpr[0] = 0;
    }
    /*TODO
    cpu.csr[0x300] = top->rootp->top__DOT__csr__DOT__mstatus;
    cpu.csr[0x305] = top->rootp->top__DOT__csr__DOT__mtvec;
    cpu.csr[0x341] = top->rootp->top__DOT__csr__DOT__mepc;
    cpu.csr[0x342] = top->rootp->top__DOT__csr__DOT__mcause;
    */
    cpu.pc = DUT_PC;
    static int cnt = 0;
    cnt ++;
    if(flag) { 
        if (cpu.gpr[10] == 0)
            npc_state.state = NPC_END;
        else
            npc_state.state = NPC_ABORT;
    }
}

static void reset() {
    top->reset = 1; 
    top->clock = 0; top->eval(); contextp->timeInc(1); 
    tfp->dump(contextp->time());
    for(int i = 0; i < 30; i ++){
        top->clock = 1; top->eval();    contextp->timeInc(1); tfp->dump(contextp->time());
        top->clock = 0; top->eval();    contextp->timeInc(1); tfp->dump(contextp->time());
    }
    top->clock = 1; top->eval();    contextp->timeInc(1);
    tfp->dump(contextp->time());
    /*
    top->clock = 0; top->eval();    contextp->timeInc(1);
    tfp->dump(contextp->time());
    */
    top->reset = 0; top->eval(); contextp->timeInc(1);
    tfp->dump(contextp->time());
}

int main(int argc, char** argv){
    int ret = 0;
    FILE *fp = NULL; 
    for(uint32_t i = 0; i < (1<<22); i ++){
        flash[i] = i * 4;
    }

    // nvboard_init();
#if CONFIG_NVBOARD
    nvboard_bind_all_pins(top.get());
    nvboard_init();
#endif
    Verilated::commandArgs(argc, argv);
#if CONFIG_GTKWAVE
    Verilated::mkdir("logs");
    contextp->traceEverOn(true);
    top->trace(tfp, 99);
    int cnt = 0;
    tfp->open("./build/obj_dir/wave.fst");
#endif

    printf("main-pc:\033[32m0x%08x\033[0m\n", cpu.pc);
    init_monitor(argc, argv);
    reset();
    while (1) {
        sdb_mainloop();
        print_perf_cnt();
        tfp->close();
        return is_exit_status_bad();
        IFDEF(CONFIG_NVBOARD, nvboard_update());
        tfp->dump(contextp->time());
    }
}


void print_perf_cnt() {
    float ipc = 0.0f;

    if (perf_cnt[PERF_CYCLE] != 0) {
        ipc = (float)perf_cnt[PERF_INSTRET] / (float)perf_cnt[PERF_CYCLE];
    }

    printf("========== Performance ==========\n");

    printf("IPC             : %f\n", ipc);

    printf("Cycle           : %lu\n", perf_cnt[PERF_CYCLE]);
    printf("Instret         : %lu\n", perf_cnt[PERF_INSTRET]);

    printf("IFU fetch       : %lu\n", perf_cnt[PERF_IFU_FETCH]);
    printf("LSU load        : %lu\n", perf_cnt[PERF_LSU_LOAD]);
    printf("LSU store       : %lu\n", perf_cnt[PERF_LSU_STORE]);
    printf("EXU done        : %lu\n", perf_cnt[PERF_EXU_DONE]);

    printf("Branch          : %lu\n", perf_cnt[PERF_BRANCH]);
    printf("Branch taken    : %lu\n", perf_cnt[PERF_BRANCH_TAKEN]);
    printf("Jump            : %lu\n", perf_cnt[PERF_JUMP]);

    printf("IFU stall       : %lu\n", perf_cnt[PERF_IFU_STALL]);
    printf("IDU stall       : %lu\n", perf_cnt[PERF_IDU_STALL]);
    printf("EXU stall       : %lu\n", perf_cnt[PERF_EXU_STALL]);
    printf("LSU stall       : %lu\n", perf_cnt[PERF_LSU_STALL]);

    printf("IFU mem wait    : %lu\n", perf_cnt[PERF_IFU_MEM_WAIT]);
    printf("LSU load wait   : %lu\n", perf_cnt[PERF_LSU_LOAD_WAIT]);
    printf("LSU store wait  : %lu\n", perf_cnt[PERF_LSU_STORE_WAIT]);

    printf("=================================\n");
}