#include <stdio.h>
#include "sdb.h"
#include <elf.h>

#define NR_RB 16

typedef struct I_RING_BUF{
    char logbuf[128];
    int valid;
}IRingBuf;

IRingBuf iringbuf[NR_RB];

//uint32_t iringbuf[NR_RB][128];
int p = 0;
void itrace_push(char *str1){
    strcpy(iringbuf[p].logbuf, str1);
    iringbuf[p].valid = 1;

    p ++;
    p %= NR_RB;
}

void itrace_dump(){
    for(int i = 0; i < NR_RB; i ++){
        if(iringbuf[i].valid == 1){
            if(i == p) printf("  --->\t");
            else printf("\t");
        
            printf("%s\n", iringbuf[i].logbuf);
        }
    }
}

typedef struct {
    const char *name;
    uint32_t addr;
    uint32_t size;
} FuncInfo;

void init_ftrace(const char *elf_file){
    FILE *fp = fopen(elf_file, "rb");
    if(fp == NULL){
        printf("Can not open elf file: %s\n", elf_file);
    }

    Elf32_Ehdr ehdr;
    int ret = fread(&ehdr, sizeof(Elf32_Ehdr), 1, fp);

    // printf("Start of section headers num: %x\n\n", ehdr.e_shnum);
    fseek(fp, ehdr.e_shoff, SEEK_SET);
    Elf32_Shdr shdr[ehdr.e_shnum];
    ret = fread(&shdr, sizeof(Elf32_Shdr), ehdr.e_shnum, fp);

    int symtab_idx = 0;
    for (int i = 0; i < ehdr.e_shnum; i ++) {
        if (shdr[i].sh_type == SHT_SYMTAB) symtab_idx = i;
    }
    int strtab_idx = shdr[symtab_idx].sh_link;

    int sym_num = shdr[symtab_idx].sh_size / sizeof(Elf32_Sym);
    Elf32_Sym sym_table[sym_num];
    fseek(fp, shdr[symtab_idx].sh_offset, SEEK_SET);
    ret = fread(&sym_table, sizeof(Elf32_Sym), sym_num, fp);

    char *strtab = malloc(shdr[strtab_idx].sh_size);
    fseek(fp, shdr[strtab_idx].sh_offset, SEEK_SET);
    ret = fread(strtab, 1, shdr[strtab_idx].sh_size, fp);
    

    int func_num = 0;
    FuncInfo func_table[sym_num];
    for (int i = 0; i < sym_num; i ++) {
        Elf32_Sym *sym = &sym_table[i];
        if (ELF32_ST_TYPE(sym->st_info) == STT_FUNC) {
            func_table[func_num].addr = sym->st_value;
            func_table[func_num].size = sym->st_size;
            
            func_table[func_num].name = strtab + sym->st_name;
            func_num ++;
        }
    }

    printf("func name: %s\n", func_table[0].name);
    printf("func name: %s\n", func_table[1].name);
    assert(ret == shdr[strtab_idx].sh_size);

    fclose(fp);
}




