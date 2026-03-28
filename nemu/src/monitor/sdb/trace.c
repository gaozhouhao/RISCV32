#include <stdio.h>
#include "sdb.h"
#include <elf.h>

#define NR_RB 32

typedef struct I_RING_BUF{
    char logbuf[128];
    int valid;
}IRingBuf;

IRingBuf iringbuf[NR_RB];

//uint32_t iringbuf[NR_RB][128];
int p = 0;
int next_p = 1;
void itrace_push(char *str1, char *str2){
    strcpy(iringbuf[p].logbuf, str1);
    iringbuf[p].valid = 1;
    strcpy(iringbuf[next_p].logbuf, str2);
    iringbuf[next_p].valid = 1;
    
    p = next_p;
    next_p ++;
    next_p %= NR_RB;
}

void itrace_dump(){
    for(int i = 0; i < NR_RB; i ++){
        if(iringbuf[i].valid == 1){
            if(i == p) printf("-->\t");
            else printf("\t");
        
            printf("%s\n", iringbuf[i].logbuf);
        }
    }
}

void init_ftrace(const char *elf_file){
    char path[128];
    snprintf(path, sizeof(path), "../am-kernels/tests/cpu-tests/build/%s-riscv32-nemu.elf", elf_file);

    FILE *fp = fopen(path, "rb");
    if(fp == NULL){
        printf("Can not open file: %s\n", path);
    }
    char line[65536];
    while (fgets(line, sizeof(line), fp) != NULL){
        
    }    


    fclose(fp);
    
}




