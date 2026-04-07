#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <npc_include.h>
const int N = 1 << 28;
uint32_t memory[N] = {
0b10110000000000000010010101110011,
0b10110000000000000010010101110011,
0b10110000000000000010010101110011,
0b10110000000000000010010101110011,

    0x01400513, // addi a0, x0, 20
    0x01400513, // addi a0, x0, 20
    0x01400513, // addi a0, x0, 20
    0x01400513, // addi a0, x0, 20
    0x01400513, // addi a0, x0, 20
    0x00c000ef, // jal  ra, +12   (-> 0x80000010)
    0x004000ef, // jal  ra, +4    (-> 0x8000000c)
    0x00100073, // ebreak
    0x00a50513, // addi a0, a0, 10
    0x00008067, // ret  (jalr x0, 0(ra))
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


unsigned int pmem_read(unsigned int raddr) {
    if(raddr >= START_ADDR);
    raddr -= START_ADDR;
    uint32_t idx = (raddr & ~0x3u) >> 2;
    
    if (idx >= 1 << 28) {
        printf("OOB READ: raddr=0x%08x idx=%08x pc? (print in sim) \n", raddr+START_ADDR, idx);
        exit(1);
    }
    return memory[idx]; 
}
extern "C" void pmem_write(unsigned int waddr, unsigned int wdata, char wmask) {
    if (waddr == 0xa00003f8) {
        putchar(wdata & 0xff); 
        return;
    };
    
    assert(waddr >= START_ADDR);
    waddr -= START_ADDR;
    
    if(wmask & 0x01){
        memory[waddr >> 2] &= ~0x000000ff;
        memory[waddr >> 2] |= (wdata & 0xff) << 0;
    }
    if(wmask & 0x02){
        memory[waddr >> 2] &= ~0x0000ff00;
        memory[waddr >> 2] |= wdata & 0x0000ff00;
    }
    if(wmask & 0x04){
        memory[waddr >> 2] &= ~0x00ff0000;
        memory[waddr >> 2] |= wdata & 0x00ff0000;
    }
    if(wmask & 0x08){
        memory[waddr >> 2] &= ~0xff000000;
        memory[waddr >> 2] |= wdata & 0xff000000;
    }
#ifdef CONFIG_MTRACE_COND
    printf("%s-write:\t%08x\t[0x%08x]\n", "memory", wdata, waddr+START_ADDR);
#endif
}

