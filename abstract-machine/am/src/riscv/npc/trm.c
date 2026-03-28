#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <riscv/riscv.h>

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
    outb(0xa00003f8, ch);
}

void halt(int code) {
    if(code == 0)
        asm volatile("ebreak");
    while (1);
}

void _trm_init() {
    /*
    uint32_t vendor, arch;
    asm volatile("csrr %0, mvendorid" : "=r"(vendor));
    asm volatile("csrr %0, marchid" : "=r"(arch));
    printf("mvendorid: %x\n", vendor);
    printf("arch: %x\n", arch);
    */
    int ret = main(mainargs);
    halt(ret);
}
