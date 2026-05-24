#include <cpu/npc_cpu.h>
#include <cpu/npc_difftest.h>
#include <npc_utils.h>
#include <debug.h>
#include "../monitor/sdb/sdb.h"
#include "npc_include.h"
#include "cpu/npc_difftest.h"

void exec_once();

static void trace_and_difftest(uint32_t pc, uint32_t dnpc, uint32_t inst) {
    //IFDEF(CONFIG_DIFFTEST, difftest_step(pc, dnpc));
#ifdef CONFIG_DIFFTEST
    if(pc >= MROM_ADDR && pc < MROM_ADDR + MROM_SIZE){
        difftest_skip_ref();
    }
    if(pc >= SRAM_ADDR && pc < SRAM_ADDR + SRAM_SIZE){
        difftest_skip_ref();
    }
    difftest_step(pc, dnpc);
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
    for (;n > 0; n --) {
        exec_once();
        
        static int inst_done_r;
        static int owner_rd_r, owner_wr_r;
    //printf("%d, %d\n", top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst_done, inst_done_r);
        if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst_done == 0 && inst_done_r == 1)
        {
            //if(owner_wr_r == 2 || owner_rd_r == 2)
            trace_and_difftest(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc, top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__next_pc, top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst);
        }
        inst_done_r = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst_done;
        //owner_rd_r = top->rootp->ysyx_25120302__DOT__xbar__DOT__owner_rd;
        //owner_wr_r = top->rootp->ysyx_25120302__DOT__xbar__DOT__owner_wr;
        //TODO
        if (npc_state.state != NPC_RUNNING) break;
    }
}


void assert_fail_msg(){
    reg_display();
}

void cpu_exec(uint64_t n) {
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
                    top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc - 4);
       // fall through
       case NPC_QUIT: 
            //statistic();
            break;
    }

}
