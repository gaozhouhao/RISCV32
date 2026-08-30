#include <cpu/npc_cpu.h>
#include <cpu/decode.h>
#include <cpu/npc_difftest.h>
#include <npc_utils.h>
#include <debug.h>
#include <macro.h>
#include "../monitor/sdb/sdb.h"
#include "npc_include.h"
#include "cpu/npc_difftest.h"

#define MAX_INST_TO_PRINT 1000

uint64_t g_nr_guest_inst = 0;
static bool g_print_step = false;

void exec_once(Decode *s);

static void trace_and_difftest(Decode *_this) {
    IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, _this->dnpc));
    IFDEF(CONFIG_ITRACE, log_write("%s\n", _this->logbuf));
    if (g_print_step) { IFDEF(CONFIG_ITRACE, printf("%s\n", _this->logbuf)); }
#ifdef CONFIG_DIFFTEST
    if(_this->pc >= MROM_ADDR && _this->pc < MROM_ADDR + MROM_SIZE){
        difftest_skip_ref();
    }
    if(_this->pc >= SRAM_ADDR && _this->pc < SRAM_ADDR + SRAM_SIZE){
        difftest_skip_ref();
    }
    if(_this->pc >= PSRAM_ADDR && _this->pc < PSRAM_ADDR + PSRAM_SIZE){
        difftest_skip_ref();
    }
    if(_this->pc >= FLASH_ADDR && _this->pc <= FLASH_ADDR + FLASH_SIZE){
        difftest_skip_ref();
    }
    if(_this->pc >= SDRAM_ADDR && _this->pc <= SDRAM_ADDR + SDRAM_SIZE){
        difftest_skip_ref();
    }
    difftest_step(_this->pc, _this->dnpc);
#endif

#ifdef CONFIG_WATCHPOINT
    WP* wp = find_head_wp();
    while(wp != NULL){
        bool success = false;
        word_t current_val = expr(wp->addr_expr, &success);
        if(current_val != wp->last_val){
            printf("Hardware watchpoint %d: %s\n\n", wp->cnt, wp->addr_expr);
            printf("Old value = %d\n", wp->last_val);
            printf("New value = %d\n", current_val);
            wp->last_val = current_val;
            npc_state.state = NPC_STOP;
        }
        wp = wp->next;
    }
#endif
}

static void execute(uint64_t  n) {
    Decode s;
    for (; n > 0; n --) {
        exec_once(&s);
        g_nr_guest_inst ++;
        static int inst_done_r;
        static int owner_rd_r, owner_wr_r;
        if(DUT_INST_DONE == 0 && inst_done_r == 1) {
            trace_and_difftest(&s);
        }
        inst_done_r = DUT_INST_DONE;
        if (npc_state.state != NPC_RUNNING) break;
        // if (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu__DOT__inst_valid) {
        //     n --;
        // }
    }
}


void assert_fail_msg(){
    reg_display();
}

void cpu_exec(uint64_t n) {
    g_print_step = (n < MAX_INST_TO_PRINT);
    switch (npc_state.state) {
        case NPC_END: case  NPC_ABORT: case NPC_QUIT:
            printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
            return;
        default: npc_state.state = NPC_RUNNING;
    }
    
    execute(n);

    switch (npc_state.state) {
        case NPC_RUNNING: npc_state.state = NPC_STOP; break;

        case NPC_END: case NPC_ABORT:
            printf("npc: %s at pc = " FMT_WORD"\n",
                (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
                (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
                    ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
                    DUT_PC - 4);
       // fall through
       case NPC_QUIT: 
            //statistic();
            break;
    }

}
