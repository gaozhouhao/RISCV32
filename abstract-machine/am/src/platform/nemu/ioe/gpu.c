#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
    int i;
    int w = inl(VGACTL_ADDR) >> 16;  // TODO: get the correct width
    int h = inl(VGACTL_ADDR) & 0xffff;  // TODO: get the correct height
    uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
    for (i = 0; i < w * h; i ++) fb[i] = i;
    outl(SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = inl(VGACTL_ADDR) >>16,
    .height = inl(VGACTL_ADDR) & 0xffff,
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
    uint32_t width = inl(VGACTL_ADDR) >> 16;
    //uint32_t heigth = inl(VGACTL_ADDR) & 0xffff;
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
        //for (int i = 0; i < w * h; i ++) fb[i] = src[i];
    }
    if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
