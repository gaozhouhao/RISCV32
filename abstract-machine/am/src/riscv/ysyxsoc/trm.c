#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <riscv/riscv.h>

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
extern char _psram_start;
extern char _psram_end;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)
#define PSRAM_END  ((uintptr_t)&_psram_end)

extern uint8_t _start;

extern uint8_t _text_end;
extern uint8_t _text_lma;

extern uint8_t _rodata_start;
extern uint8_t _rodata_end;
extern uint8_t _rodata_lma;

extern uint8_t _data_start; 
extern uint8_t _data_end; 
extern uint8_t _data_lma; 

extern uint8_t _bss_start; 
extern uint8_t _bss_end; 

Area heap = RANGE(&_heap_start, PSRAM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
    while(!(inb(0x10000005) & 0x20)){
        continue;
    }
        outb(0x10000000, ch);
}

void halt(int code) {
    if(code == 0)
        asm volatile("ebreak");
    
    putch('W');
    putch('R');
    putch('O');
    putch('N');
    putch('G');
    putch('\n');
    while (1);
}

/*
static void bootloader(){
    //memset(&_psram_start, 0, &_psram_end - &_psram_start);
    //memcpy(&_start, &_text_lma, &_text_end - &_start);
    //memcpy(&_rodata_start, &_rodata_lma, &_rodata_end - &_rodata_start);
    memcpy(&_data_start, &_data_lma, &_data_end - &_data_start);
    memset(&_bss_start, 0, &_bss_end - &_bss_start);

    //asm volatile("jalr x0, %0" : : "r"(_start));
}
*/

void uart_init(){
    uint8_t tmp = inb(0x10000003);
    tmp |= 0x80;
    outb(0x10000003, tmp);
    outb(0x10000000, 0x01);
    outb(0x10000001, 0x00);
    tmp = inb(0x10000003);
    tmp &= ~0x80;
    outb(0x10000003, tmp);
}

int _trm_init() {

    //bootloader();

    uart_init();

    printf("fasdg");

    uint32_t vendor, arch;
    asm volatile("csrr %0, mvendorid" : "=r"(vendor));
    asm volatile("csrr %0, marchid" : "=r"(arch));
    printf("mvendorid: %c%c%c%c\n", (uint8_t)(vendor>>24), (uint8_t)(vendor>>16), (uint8_t)(vendor>>8), (uint8_t)(vendor>>0));
    //printf("arch: %d\n", arch);
    
    int ret = main(mainargs);
    halt(ret);
    //return ret;
}
