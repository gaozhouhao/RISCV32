#include <readline/readline.h>
#include <readline/history.h>
#include <cpu/npc_cpu.h>
#include "sdb.h"
#include "npc_include.h"
#include <memory.h>
#include "npc_utils.h"

static int is_batch_mode = false;

void itrace_dump();
void init_regex();
void init_wp_pool();

static int cmd_c(char *args) {
    cpu_exec(-1);
    return 0; 
}

static int cmd_q(char *args) {
    npc_state.state = NPC_QUIT;
    return -1;
}

static int cmd_si(char *args) {
    long n = 1;
    if (args != NULL) {
        n = strtol(args, NULL, 0);
    }
    cpu_exec(n);
    return 0;
}

static int cmd_info(char *args) {
    if(strcmp(args, "r") == 0) {
        reg_display();
    }

    if(strcmp(args, "w") == 0){
        WP* wp = find_head_wp();
        if(wp != NULL){
            printf("%-4s %-20s %-10s\n", "NO", "Info", "Val");
        }
        else{
            printf("No Watchpoint!\n");
        }
        while(wp != NULL){
            printf("%-4d %-20s %-10x\n", wp->cnt, wp->addr_expr, wp->last_val);
            wp = wp->next;
        }
    }
    return 0;
}

static int cmd_x(char *args){
    if(args != NULL){
        char *first_para = strtok(args, " ");
        char *second_para = first_para + strlen(first_para) + 1;
        long n = strtol(first_para, NULL, 0);
        //word_t addr = strtol(second_para, NULL, 0);
        bool success = false;
        word_t addr = expr(second_para, &success);
        for(int i = 0; i < n; i ++){
            printf("addr:%x", addr);
            if(addr >= MEM_LEFT && addr < MEM_RIGHT){
                printf("0x%08X:\t", addr);
                printf("%02X\t", (pmem_read(addr)>>24)&0xff);
                printf("%02X\t", (pmem_read(addr)>>16)&0xff);
                printf("%02X\t", (pmem_read(addr)>>8)&0xff);
                printf("%02X\t\n", pmem_read(addr)&0xff);
                addr += 4;
            }
            else {
            //    itrace_dump();
                panic("out of bound");
            }
        }
    }
    return 0;
}

static int cmd_p(char *args){
    if(args != NULL){
        bool success = false;
        printf("0x%08x\n",expr(args, &success));
    }
    return 0;
}

static int cmd_w(char *args){
    if(args != NULL){
        WP *wp = new_wp();
        bool success = false;
        strncpy(wp->addr_expr, args, sizeof(wp->addr_expr) - 1);
        wp->addr_expr[sizeof(wp->addr_expr) - 1] = '\0';
        wp->last_val = expr(args, &success);
        if(wp->next == NULL)    wp->cnt = 1;
        else    wp->cnt = wp->next->cnt + 1;
        printf("Hardware watchpoint %d: %s\n", wp->cnt, args);
    }
    return 0;
}

static int cmd_d(char *args){
    if(args != NULL){
        int num = strtol(args, NULL, 0);
        WP *tmp = find_head_wp();
        if(tmp == NULL){
            printf("No such watchpoint\n");
            return 0;
        }
        else if(num > tmp->cnt){
            printf("No such watchpoint\n");
            return 0;
        }
        else{
            for(; tmp != NULL; tmp = tmp->next){
                if(tmp->cnt == num){
                    free_wp(tmp);
                    printf("Delet watchpoint: %d\n", num);
                    return 0;
                }
            }
        }
    }
    return 0;
}


static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  //{ "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  /* TODO: Add more commands */
  { "si", "single step execute", cmd_si},
  { "info", "print infomation", cmd_info },
  { "x", "scan memory", cmd_x},
  { "p", "expr", cmd_p },
  { "w", "add a watch point", cmd_w},
  { "d", "delet a watch point", cmd_d},
};

#define NR_CMD ARRLEN(cmd_table)

static char* rl_gets() {
    static char *line_read = NULL;
    if (line_read) {
        free(line_read);
        line_read = NULL;
    }

    line_read = readline("\033[32m(npc)\033[0m ");

    if (line_read && *line_read) {
        add_history(line_read);
    }
    return line_read;
}

void sdb_set_batch_mode() {
    is_batch_mode = true;
} 


void sdb_mainloop() {
    if (is_batch_mode) {
        cmd_c(NULL);
        return;
    }
    for (char *str; (str = rl_gets()) != NULL; ) {
        char *str_end = str + strlen(str);
        char *cmd = strtok(str, " ");
        if (cmd == NULL) { continue; }
        char *args = cmd + strlen(cmd) + 1;
        if (args >= str_end) {
            args = NULL;
        }
        int i ;
        for (i = 0; i < NR_CMD; i ++) {
            if (strcmp(cmd, cmd_table[i].name) == 0) {
                if (cmd_table[i].handler(args) < 0) { return; }
                break;
            }
        }
        if (i == NR_CMD) { printf("Unkonown command '%s'\n", cmd); }
    }
}

void init_sdb() {
    init_regex();

    init_wp_pool();
}


