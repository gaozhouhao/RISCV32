#include <cstdio>
#include <cassert>
#include <cstdint>
#include <stdio.h>


#define OFFSET_WIDTH 2
#define INDEX_WIDTH 4
#define SET_WIDTH 2

#define CACHE_LINE_BYTES (1 << OFFSET_WIDTH)
#define CACHE_NUM_LINES  (1 << INDEX_WIDTH)
#define CACHE_SIZE_BYTES (CACHE_LINE_BYTES * CACHE_NUM_LINES)

#define CACHE_NUM_SETS   (1 << SET_WIDTH)

#define TAG_WIDTH (32 - INDEX_WIDTH - OFFSET_WIDTH - SET_WIDTH)



int main() {
    static char *pc_trace_file = NULL;
    pc_trace_file = "./traces/pc_trace.txt";
    FILE *fp = fopen(pc_trace_file, "rb");
    assert(fp != NULL);

    uint32_t pc;
    while (fread(&pc, sizeof(pc), 1, fp) == 1) {
        printf("pc: %08x\n", pc);
    }

    fclose(fp);

    return 0;
}