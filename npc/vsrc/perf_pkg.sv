/* verilator lint_off UNUSED */
package perf_pkg;

    typedef enum int {
        PERF_IFU_FETCH,
        PERF_LSU_LOAD,
        PERF_LSU_STORE,
        PERF_EXU_DONE,
        PERF_CYCLE,
        PERF_INSTRET,
        PERF_BRANCH,
        PERF_BRANCH_TAKEN,
        PERF_JUMP,
        PERF_IFU_STALL,
        PERF_IDU_STALL,
        PERF_EXU_STALL,
        PERF_LSU_STALL,
        PERF_IFU_MEM_WAIT,
        PERF_LSU_LOAD_WAIT,
        PERF_LSU_STORE_WAIT,
        PERF_MAX
    } perf_event_t;
    perf_event_t event_id;
    import "DPI-C" function void perf_event(input int event_id);

endpackage
/* verilator lint_on UNUSED */

