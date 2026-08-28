/* verilator lint_off UNUSED */
package perf_pkg;
    localparam PERF_IFU_FETCH = 0;
    localparam PERF_LSU_LOAD  = 1;
    localparam PERF_LSU_STORE = 2;
    localparam PERF_EXU_DONE  = 3;

    import "DPI-C" function void perf_event(input int event_id);
endpackage
/* verilator lint_on UNUSED */
