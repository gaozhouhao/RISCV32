
#include <klib.h>

extern uint32_t _start;
extern uint32_t _ssbl_start;

extern uint32_t _ssbl_text_start;
extern uint32_t _ssbl_text_end;
extern uint32_t _ssbl_text_lma;

extern uint32_t _text_start;
extern uint32_t _text_end;
extern uint32_t _text_lma;

extern uint32_t _data_start;
extern uint32_t _data_end;
extern uint32_t _data_lma;

extern uint32_t _data_extra_start;
extern uint32_t _data_extra_end;
extern uint32_t _data_extra_lma;

extern uint32_t _rodata_start;
extern uint32_t _rodata_end;
extern uint32_t _rodata_lma;

extern uint32_t _bss_start;
extern uint32_t _bss_end;

extern uint32_t _bss_extra_start;
extern uint32_t _bss_extra_end;

__attribute__((section(".fsbl_text")))
static void fsbl_copy(uint32_t *dst, const uint32_t *src, size_t size)
{
    while (size != 0) {
        *dst++ = *src++;
        size--;
    }
}


__attribute__((section(".fsbl_text")))
void fs_bootloader(void)
{
    fsbl_copy(&_ssbl_text_start, &_ssbl_text_lma, (size_t)(&_ssbl_text_end - &_ssbl_text_start));

    asm volatile(
        "jalr x0, 0(%0)"
        :
        : "r"(&_ssbl_start)
        : "memory"
    );
    __builtin_unreachable();
}


__attribute__((section(".ssbl_text")))
static void ssbl_copy(uint32_t *dst, const uint32_t *src, size_t size)
{
    while (size != 0) {
        *dst++ = *src++;
        size--;
    }
}

__attribute__((section(".ssbl_text")))
static void ssbl_zero(uint32_t *dst, size_t size)
{
    while (size != 0) {
        *dst++ = 0;
        size--;
    }
}

__attribute__((section(".ssbl_text")))
void ss_bootloader(void)
{
    ssbl_copy(&_text_start, &_text_lma, (size_t)(&_text_end - &_text_start));

    ssbl_copy(&_rodata_start, &_rodata_lma, (size_t)(&_rodata_end - &_rodata_start));
    
    ssbl_copy(&_data_start, &_data_lma, (size_t)(&_data_end - &_data_start));
    ssbl_copy(&_data_extra_start, &_data_extra_lma, (size_t)(&_data_extra_end - &_data_extra_start));

    ssbl_zero(&_bss_start, (size_t)(&_bss_end - &_bss_start));
    ssbl_zero(&_bss_extra_start, (size_t)(&_bss_extra_end - &_bss_extra_start));

    asm volatile(
        "jalr x0, 0(%0)"
        :
        : "r"(&_start)
        : "memory"
    );
    __builtin_unreachable();
}








