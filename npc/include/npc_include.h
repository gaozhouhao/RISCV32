#ifndef __NPC_INCLUDE_H__
#define __NPC_INCLUDE_H__

#define NPC_WATCHPOINT  1
#define NPC_ITRACE_COND 1
//#define NPC_MTRACE_COND 1


#define START_ADDR  0x30000000

#define MROM_ADDR   0x20000000
#define MROM_SIZE   0x1000
#define FLASH_ADDR  0x30000000
#define FLASH_SIZE  0x1000000
#define SRAM_ADDR   0x0f000000
#define SRAM_SIZE   0x2000
#define PSRAM_ADDR  0x80000000
#define PSRAM_SIZE  0x20000000
#define SDRAM_ADDR  0xA0000000
#define SDRAM_SIZE  0x20000000

#define MEM_LEFT    0x80000000
#define MEM_RIGHT   0x88000000

enum {
    PERF_IFU_FETCH = 0,
    PERF_LSU_LOAD,
    PERF_LSU_STORE,
    PERF_EXU_DONE,
    PERF_CYCLE,
    PERF_INSTRET,
    PERF_BRANCH,
    PERF_BRANCH_TAKEN,
    PERF_JUMP,
    PERF_IFU_STALL,
    PERF_IDU_STALL,
    PERF_EXU_STALL,
    PERF_LSU_STALL,
    PERF_IFU_MEM_WAIT,
    PERF_LSU_LOAD_WAIT,
    PERF_LSU_STORE_WAIT,
    PERF_ICACHE_ACCESS,
    PERF_ICACHE_HIT,
    PERF_ICACHE_MISS,
    
    PERF_ICACHE_HIT_CYCLES,
    PERF_ICACHE_MISS_CYCLES,
    PERF_ICACHE_MISS_PENALTY,
    PERF_MAX
};

extern const char *regs[];
#define STR1(x)     #x
#define STR(x)      STR1(x)
#include STR(TOP_NAME.h)
#include STR(TOP_ROOT.h)
#include STR(TOP_DPI.h)
#include <debug.h>

typedef struct {
    uint32_t gpr[32];
    uint32_t pc;
    uint32_t csr[4096];
} CPUArchState;

extern CPUArchState cpu;


extern const std::unique_ptr<VerilatedContext> contextp;
extern const std::unique_ptr<TOP_NAME> top;
uint32_t pmem_read(uint32_t pc);
void nvboard_bind_all_pins(TOP_NAME* top);

#ifdef ARCH_NPC

#define DUT_INST_DONE   (top->rootp->ysyx_25120302__DOT__ifu__DOT__inst_done)
#define DUT_ALLOW_FETCH (top->rootp->ysyx_25120302__DOT__ifu__DOT__allow_fetch)
#define DUT_INST_VALID  (top->rootp->ysyx_25120302__DOT__ifu__DOT__out_valid)
#define DUT_PC          (top->rootp->ysyx_25120302__DOT__ifu__DOT__pc)
#define DUT_NEXT_PC     (top->rootp->ysyx_25120302__DOT__ifu__DOT__next_pc)
#define DUT_RF          (top->rootp->ysyx_25120302__DOT__wbu__DOT__rf)

// #define IFU_VALID(top) \
//     top->rootp->top__DOT__cpu__DOT__ifu__DOT__out_valid

// #define LSU_VALID(top) \
//     top->rootp->top__DOT__cpu__DOT__lsu__DOT__out_valid

#elif defined(ARCH_YSYXSOC)

#define DUT_INST_DONE   (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu__DOT__inst_done)
#define DUT_ALLOW_FETCH (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu__DOT__allow_fetch)
#define DUT_INST_VALID  (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu__DOT__out_valid)
#define DUT_PC          (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu__DOT__pc)
#define DUT_NEXT_PC     (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu__DOT__next_pc)
#define DUT_RF          (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wbu__DOT__rf)

#endif


#endif
