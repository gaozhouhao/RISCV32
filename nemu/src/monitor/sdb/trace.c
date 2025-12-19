#include <stdio.h>
#include "sdb.h"

#define NR_RB 32

typedef struct I_RING_BUF{
    char logbuf[128];
}IRingBuf;

IRingBuf iringbuf[NR_RB];

//uint32_t iringbuf[NR_RB][128];
int p = 0;
void itrace_push(char *str){
    strcpy(iringbuf[p].logbuf, str);

    p ++;
    p %= NR_RB;
}

void itrace_dump(){
    for(int i = 0; i < NR_RB; i ++){
        if(i == p) printf("-->\t");
        else printf("\t\t");
        
        printf("%s\n", iringbuf[i].logbuf);
    }
}
