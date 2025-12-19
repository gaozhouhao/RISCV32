#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
const int N = 1 << 18;
uint32_t memory[N] = {

    /*
    0x01400513,
    0x010000e7,
    0x00c000e7,
    
    0b00000000000100000000000001110011,
    //0x00c00067,

    0x00a50513,
    0x00008067,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
    0x238b8b93,
*/
};

extern "C" unsigned int pmem_read(unsigned int raddr) {
    raddr -=0x80000000;
    uint32_t idx = (raddr & ~0x3u) >> 2;
    
    if (idx >= 1 << 18) {
        printf("OOB READ: raddr=0x%08x idx=%08x pc? (print in sim) \n", raddr, idx);
        exit(1);
    }
    return memory[idx];
    
}
extern "C" void pmem_write(unsigned int waddr, unsigned int wdata, unsigned char wmask) {
    waddr -= 0x80000000;
    if(wmask == 0x0f){
        memory[waddr >> 2] = wdata;
        return;
    }
    if(wmask == 0x01){
        memory[waddr >> 2] &= ~0x000000ff;
        memory[waddr >> 2] |= (wdata & 0xff) << 0;
    }
    if(wmask == 0x02){
        memory[waddr >> 2] &= ~0x0000ff00;
        memory[waddr >> 2] |= (wdata & 0xff) << 8;
    }
    if(wmask == 0x04){
        memory[waddr >> 2] &= ~0x00ff0000;
        memory[waddr >> 2] |= (wdata & 0xff) << 16;
    }
    if(wmask == 0x08){
        memory[waddr >> 2] &= ~0xff000000;
        memory[waddr >> 2] |= (wdata & 0xff) << 24;
    }
  

}


