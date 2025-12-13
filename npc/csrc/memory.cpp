#include <stdint.h>


const int N = 1 << 18;
uint32_t memory[N] = {
    0x01400513,
    0x010000e7,
    0x00c000e7,
    0x00c00067,
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

};

uint32_t pmem_read(uint32_t pc){
    return memory[pc];
}
