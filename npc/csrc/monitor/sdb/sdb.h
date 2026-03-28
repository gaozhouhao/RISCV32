#ifndef __SDB_H__
#define __SDB_H__

#include <npc_common.h>


void reg_display();


typedef struct watchpoint{
    int NO;
    struct watchpoint *next;
    char addr_expr[128];
    word_t last_val;
    int cnt;
}WP;

word_t expr(char *e, bool *success);

WP* find_head_wp();
WP* new_wp();
void free_wp(WP *wp);

void itrace_push(char *str1, char *str2);


#endif
