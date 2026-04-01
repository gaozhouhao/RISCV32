#include <cpu/npc_cpu.h>
#include <cpu/npc_difftest.h>
#include <npc_utils.h>
#include <debug.h>
#include "../monitor/sdb/sdb.h"
#include "npc_include.h"
#include "cpu/npc_difftest.h"

void exec_once();

static void trace_and_difftest(uint32_t pc, uint32_t dnpc, uint32_t inst) {
    IFDEF(CONFIG_DIFFTEST, difftest_step(pc, dnpc));

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
        //if(top->rootp->top__DOT__ifu__DOT__wait_ready == 1) difftest_skip_ref();
        //if(top->rootp->top__DOT__ifu__DOT__idle == 1) difftest_skip_ref();
        
        //static int wb_done_r = top->rootp->top__DOT__regfile__DOT__wb_done;
        //if(wb_done_r == 1 && top->rootp->top__DOT__regfile__DOT__wb_done == 0)
        static int inst_done_r;
        if(top->inst_done == 0 && inst_done_r == 1)
        {
            printf("difftest\n");
            trace_and_difftest(top->pc, top->rootp->top__DOT__next_pc, top->rootp->top__DOT__inst);
        }
        inst_done_r = top->inst_done;
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
                    top->pc - 4);
       // fall through
       case NPC_QUIT: 
            //statistic();
            break;
    }

}
