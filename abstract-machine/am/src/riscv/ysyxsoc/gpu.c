#include <am.h>
#include <riscv/riscv.h>


#define FB_ADDR 0x21000000


void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
    uint32_t width = 640;
    if(ctl->pixels != NULL){
        uint32_t x = ctl->x;
        uint32_t y = ctl->y;
        uint32_t w = ctl->w;
        uint32_t h = ctl->h;
        uint32_t *src = (uint32_t *)ctl->pixels;
        uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
        for (int i = 0; i < h; i ++){
            for (int j = 0; j < w; j ++){
                fb[(y+i)*width + j + x] = src[i*w + j];
            }
        }
    }
}
