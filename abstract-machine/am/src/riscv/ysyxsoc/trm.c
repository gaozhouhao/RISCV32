#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <riscv/riscv.h>

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
extern char _run_start;
extern char _run_end;


#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)
#define RUN_END  ((uintptr_t)&_run_end)

Area heap = RANGE(&_heap_start, RUN_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
    while(!(inb(0x10000005) & 0x20)){
        continue;
    }
        outb(0x10000000, ch);
}


void halt(int code) {
    asm volatile("mv a0, %0" : : "r"(code) : "a0");
    asm volatile("ebreak");
    while(1);
}

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

    // outb(0x10002000, 0x5F);
    uart_init();

    uint32_t vendor, arch;
    asm volatile("csrr %0, mvendorid" : "=r"(vendor));
    asm volatile("csrr %0, marchid" : "=r"(arch));
    printf("mvendorid: %c%c%c%c\n", (uint8_t)(vendor>>24), (uint8_t)(vendor>>16), (uint8_t)(vendor>>8), (uint8_t)(vendor>>0));
    printf("arch: %d\n", arch);
    // while(1);
    int ret = main(mainargs);
    halt(ret);
}
