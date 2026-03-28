/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <memory/vaddr.h>
#include <memory/paddr.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

static int is_batch_mode = false;

void itrace_dump();
void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
    nemu_state.state = NEMU_QUIT;
    return -1;
}

static int cmd_si(char *args) {
    long n = 1;
    if(args != NULL){
        n = strtol(args, NULL, 0);
    }
    cpu_exec(n);   
    return 0; 
}

static int cmd_info(char *args){   
    if(strcmp(args, "r") == 0){
        isa_reg_display();
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
            if(addr >= PMEM_LEFT && addr <= PMEM_RIGHT){
                printf("0x%08X:\t", addr);
                printf("%02X\t", (vaddr_read(addr, 4)>>24)&0xff);
                printf("%02X\t", (vaddr_read(addr, 4)>>16)&0xff);
                printf("%02X\t", (vaddr_read(addr, 4)>>8)&0xff);
                printf("%02X\t\n", vaddr_read(addr, 4)&0xff);
                addr += 4;
            }
            else {
                itrace_dump();
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

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  
  /* TODO: Add more commands */
  { "si", "single step execute", cmd_si},
  { "info", "print infomation", cmd_info},
  { "x", "scan memory", cmd_x},
  { "p", "expr", cmd_p},
  { "w", "add a watch point", cmd_w},
  { "d", "delet a watch point", cmd_d},
};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
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

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() { /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
