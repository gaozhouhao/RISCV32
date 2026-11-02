
#include <cstdio>
#include <cassert>
#include <cstdint>
#include <cstdlib>

#define REPLACE_FIFO   0
#define REPLACE_LRU    1
#define REPLACE_RANDOM 2

#define REPLACE_POLICY REPLACE_FIFO

#define WAY_WIDTH (INDEX_WIDTH - SET_WIDTH)

#define CACHE_NUM_LINES  (1 << INDEX_WIDTH)
#define CACHE_NUM_SETS   (1 << SET_WIDTH)
#define CACHE_NUM_WAYS   (1 << WAY_WIDTH)

#define TAG_WIDTH (32 - OFFSET_WIDTH - SET_WIDTH)


uint32_t valids[CACHE_NUM_SETS][CACHE_NUM_WAYS] = {0};
uint32_t tags[CACHE_NUM_SETS][CACHE_NUM_WAYS] = {0};
uint32_t targets[CACHE_NUM_SETS][CACHE_NUM_WAYS] = {0};
uint32_t fifo_ptr[CACHE_NUM_SETS] = {0};

uint32_t bht_1bit[CACHE_NUM_LINES] = {0};
uint32_t bht_2bit[CACHE_NUM_LINES] = {0};

uint64_t branch_trace_count = 0;
uint64_t branch_hit_count[5] = {0};
uint64_t btb_hit_count = 0;


typedef struct {
    uint32_t pc;
    uint32_t target;
    uint32_t taken;
} BranchTrace;


uint32_t find_set(uint32_t addr) {
    return (addr >> OFFSET_WIDTH) & (CACHE_NUM_SETS - 1);
}

uint32_t find_tag(uint32_t addr) {
    return addr >> (OFFSET_WIDTH + SET_WIDTH);
}


bool btb_access(BranchTrace t) {
    uint32_t set = find_set(t.pc);
    uint32_t tag = find_tag(t.pc);

    for (int i = 0; i < CACHE_NUM_WAYS; i++) {
        if (valids[set][i] && tags[set][i] == tag) {
            return true;
        }
    }

    if (t.taken) {
        uint32_t way = fifo_ptr[set];

        valids[set][way] = 1;
        tags[set][way] = tag;
        targets[set][way] = t.target;

        fifo_ptr[set] = (fifo_ptr[set] + 1) % CACHE_NUM_WAYS;
    }

    return false;
}


bool always_nt(BranchTrace t) {
    return false;
}

bool always_t(BranchTrace t) {
    return true;
}

bool btfnt(BranchTrace t) {
    return t.target < t.pc;
}

bool one_bit(BranchTrace t) {
    uint32_t index = (t.pc >> OFFSET_WIDTH) & (CACHE_NUM_LINES - 1);

    bool predict = bht_1bit[index];
    bht_1bit[index] = t.taken;

    return predict;
}

bool two_bit(BranchTrace t) {
    uint32_t index = (t.pc >> OFFSET_WIDTH) & (CACHE_NUM_LINES - 1);

    bool predict = bht_2bit[index] >= 2;

    if (t.taken) {
        if (bht_2bit[index] < 3) bht_2bit[index]++;
    }
    else {
        if (bht_2bit[index] > 0) bht_2bit[index]--;
    }

    return predict;
}


int main() {
    srand(1);
    const char *pc_trace_file = "./traces/branch_trace.txt";
    FILE *fp = fopen(pc_trace_file, "rb");
    assert(fp != NULL);

    BranchTrace trace;
    while (fread(&trace, sizeof(trace), 1, fp) == 1) {
        branch_trace_count++;

        if (btb_access(trace)) {
            btb_hit_count++;
        }

        if (trace.taken == always_nt(trace)) {
            branch_hit_count[0]++;
        }
        if (trace.taken == always_t(trace)) {
            branch_hit_count[1]++;
        }
        if (trace.taken == btfnt(trace)) {
            branch_hit_count[2]++;
        }
        if (trace.taken == one_bit(trace)) {
            branch_hit_count[3]++;
        }
        if (trace.taken == two_bit(trace)) {
            branch_hit_count[4]++;
        }
    }

    fclose(fp);

#ifdef BATCH_MODE
    char filename[256];
    sprintf(filename, "results/o%d_i%d_s%d.csv", OFFSET_WIDTH, INDEX_WIDTH, SET_WIDTH);
    fp = fopen(filename, "w");
    assert(fp != NULL);

    fprintf(fp, "%d,%d,%d,%lu,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
            OFFSET_WIDTH,
            INDEX_WIDTH,
            SET_WIDTH,
            branch_trace_count,
            (double)btb_hit_count / branch_trace_count,
            (double)branch_hit_count[0] / branch_trace_count,
            (double)branch_hit_count[1] / branch_trace_count,
            (double)branch_hit_count[2] / branch_trace_count,
            (double)branch_hit_count[3] / branch_trace_count,
            (double)branch_hit_count[4] / branch_trace_count);
    fclose(fp);
#else
    const char *names[5] = {
        "Always Not Taken",
        "Always Taken",
        "BTFNT",
        "One Bit",
        "Two Bit"
    };

    for (int i = 0; i < 5; i++) {
        printf("%-20s %.2f%%\n",
               names[i],
               branch_trace_count ?
               100.0 * branch_hit_count[i] / branch_trace_count : 0.0);
    }

    return 0;
#endif


}
