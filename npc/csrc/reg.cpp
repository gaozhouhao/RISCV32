#include "npc_include.h"

const char *regs[] = {
    "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void reg_display() {

    for(int i = 0; i < 32; i ++){
        printf("%-3s:  %02x", regs[i], top->rootp->top__DOT__regfile__DOT__rf[i]);
        if (i % 4 == 3) printf("\n");
        else printf("\t");
    }
    printf("mstatus: %02x,\tmtvec: %02x,\tmepc: %02x,\tmcause: %02x\n",
         top->rootp->top__DOT__csr__DOT__mstatus,
         top->rootp->top__DOT__csr__DOT__mtvec,
         top->rootp->top__DOT__csr__DOT__mepc,
         top->rootp->top__DOT__csr__DOT__mcause);
}

