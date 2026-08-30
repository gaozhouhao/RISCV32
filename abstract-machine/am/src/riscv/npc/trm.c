#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <riscv/riscv.h>

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (16 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
    outb(0x10000000, ch);
}

void halt(int code) {
    asm volatile("mv a0, %0" : : "r"(code) : "a0");
    asm volatile("ebreak");

    while(1);
}

void _trm_init() {
    
    uint32_t vendor, arch;
    asm volatile("csrr %0, mvendorid" : "=r"(vendor));
    asm volatile("csrr %0, marchid" : "=r"(arch));
    printf("mvendorid: %c%c%c%c\n", (uint8_t)(vendor>>24), (uint8_t)(vendor>>16), (uint8_t)(vendor>>8), (uint8_t)(vendor>>0));
    printf("arch: %d\n", arch);
    
    int ret = main(mainargs);
    halt(ret);
}
