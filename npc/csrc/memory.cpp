#include <stdint.h>


const int N = 1 << 18;
uint32_t memory[N] = {0};

uint32_t pmem_read(uint32_t pc){
    return memory[pc];
}
