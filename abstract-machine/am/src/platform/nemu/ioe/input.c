#include <am.h>
#include <nemu.h>
#include "klib.h"
#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
    uint32_t key = inl(KBD_ADDR);
    kbd->keycode = key & ~0x8000;
    kbd->keydown = (key >> 15) & 0x1;
}
