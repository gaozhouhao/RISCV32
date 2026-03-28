#ifndef __NPC_INCLUDE_H__
#define __NPC_INCLUDE_H__

#define NPC_WATCHPOINT  1
#define NPC_ITRACE_COND 1
#define NPC_MTRACE_COND 1


#define START_ADDR 0x80000000

#define MEM_LEFT 0x80000000
#define MEM_RIGHT 0x88000000


extern const char *regs[];

#include <Vtop.h>
#include <Vtop___024root.h>
#include "Vtop__Dpi.h"
#include <debug.h>

typedef struct {
    uint32_t gpr[32];
    uint32_t pc;
    uint32_t csr[4096];
} CPUArchState;

extern CPUArchState cpu;


extern const std::unique_ptr<VerilatedContext> contextp;
extern const std::unique_ptr<Vtop> top;
uint32_t pmem_read(uint32_t pc);
void nvboard_bind_all_pins(TOP_NAME* top);



#endif
