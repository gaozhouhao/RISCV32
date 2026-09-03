#include <cstdio>
#include <cassert>
#include <cstdint>
#include <stdio.h>
#include <cstdlib>
#include <ctime>


#define REPLACE_FIFO   0
#define REPLACE_LRU    1
#define REPLACE_RANDOM 2

#define REPLACE_POLICY REPLACE_RANDOM

#define OFFSET_WIDTH 2
#define INDEX_WIDTH 4
#define SET_WIDTH 2
#define WAY_WIDTH INDEX_WIDTH - SET_WIDTH

#define CACHE_LINE_BYTES (1 << OFFSET_WIDTH)
#define CACHE_NUM_LINES  (1 << INDEX_WIDTH)
#define CACHE_NUM_SETS   (1 << SET_WIDTH)
#define CACHE_NUM_WAYS   (1 << WAY_WIDTH)

#define TAG_WIDTH (32 - OFFSET_WIDTH - INDEX_WIDTH + WAY_WIDTH)


uint32_t valids[CACHE_NUM_SETS][CACHE_NUM_WAYS] = {0};
uint32_t tags[CACHE_NUM_SETS][CACHE_NUM_WAYS] = {0};


uint32_t find_set(uint32_t addr) {
    return (addr >> OFFSET_WIDTH) & ((1 << SET_WIDTH) - 1);
}


uint32_t find_tag(uint32_t addr) {
    return (addr >> (OFFSET_WIDTH + SET_WIDTH)) & ((1 << TAG_WIDTH ) - 1);
}

uint64_t cache_access_count = 0;
uint64_t cache_hit_count = 0;
uint64_t cache_miss_count = 0;


int main() {
    srand(1);
    static char *pc_trace_file = NULL;
    pc_trace_file = "./traces/pc_trace.txt";
    FILE *fp = fopen(pc_trace_file, "rb");
    assert(fp != NULL);

    uint32_t set;
    uint32_t index;
    uint32_t tag;
    uint32_t pc;
    while (fread(&pc, sizeof(pc), 1, fp) == 1) {
        cache_access_count ++;
        set = find_set(pc);
        tag = find_tag(pc);

        bool hit = false;
        for (int i = 0; i < CACHE_NUM_WAYS; i++) {
            if (valids[set][i] && tags[set][i] == tag) {
                hit = true;
                break;
            }
        }
        if (!hit) {
            for (int i = 0; i < CACHE_NUM_WAYS; i++) {
                if (valids[set][i] == 0) {
                    valids[set][i] = 1;
                    tags[set][i] = tag;
                    break;
                }
                else if (i == CACHE_NUM_WAYS - 1) {
                    int way = rand() % CACHE_NUM_WAYS;
                    valids[set][way] = 1;
                    tags[set][way] = tag;
                }
            }
        }

        if (hit) {
            cache_hit_count ++;
        }
        else {
            cache_miss_count ++;
        }
    }
    assert(cache_access_count == cache_hit_count + cache_miss_count);
    printf("Cache access count: %llu\n", cache_access_count);
    printf("Cache hit count: %llu\n", cache_hit_count);
    printf("Cache miss count: %llu\n", cache_miss_count);
    printf("Cache hit rate: %.2f%%\n", (double)cache_hit_count / cache_access_count * 100.0);

    fclose(fp);

    return 0;
}