
#include <klib.h>

extern uint32_t _start;

extern uint32_t _text_start;
extern uint32_t _text_end;
extern uint32_t _text_lma;
extern uint32_t _rodata_start;

extern uint32_t _data_end;
extern uint32_t _data_lma;
extern uint32_t _data_start;

extern uint32_t _rodata_end;
extern uint32_t _rodata_lma;

extern uint32_t _bss_start;
extern uint32_t _bss_end;
extern uint32_t _bss_lma;



__attribute__((section(".boot.text"), noinline))
static void boot_copy(uint32_t *dst, const uint32_t *src, size_t size)
{
    while (size != 0) {
        *dst++ = *src++;
        size--;
    }
}

__attribute__((section(".boot.text"), noinline))
static void boot_zero(uint32_t *dst, size_t size)
{
    while (size != 0) {
        *dst++ = 0;
        size--;
    }
}

__attribute__((section(".boot.text"), noreturn))
void bootloader(void)
{
    boot_copy(&_text_start, &_text_lma, (size_t)(&_text_end - &_text_start));

    boot_copy(&_rodata_start, &_rodata_lma, (size_t)(&_rodata_end - &_rodata_start));
    
    boot_copy(&_data_start, &_data_lma, (size_t)(&_data_end - &_data_start));

    boot_zero(&_bss_start, (size_t)(&_bss_end - &_bss_start));

    asm volatile(
        "jalr x0, 0(%0)"
        :
        : "r"(&_start)
        : "memory"
    );
    __builtin_unreachable();
}
