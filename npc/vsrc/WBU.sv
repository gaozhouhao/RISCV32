module WBU(
    input               clk,
    input               reset,
    input       [31:0]  in_pc,
    input       [31:0]  in_inst,
    input       [31:0]  in_npc,
    input               in_is_ebreak,
    input               in_valid,
    input       [31:0]  in_wdata,
    input       [ 4:0]  in_waddr,
    input               in_rf_we,
    input               in_is_mmio,
    input               in_is_fencei,
    input       [ 4:0]  in_raddr1,
    input       [ 4:0]  in_raddr2,
    input               commit_ready,

    output              commit_valid,
    output              commit_fire,
    output      [31:0]  commit_pc,
    output      [31:0]  commit_inst,
    output      [31:0]  commit_npc,
    output              commit_ebreak,
    output              commit_skip_ref,
    output              commit_wen,
    output      [ 4:0]  commit_rd,
    output      [31:0]  commit_wdata,
    output      [31:0]  out_rdata1,
    output      [31:0]  out_rdata2,
    output              out_fencei_done,
    output              out_ready
);

`ifdef VERILATOR
    import perf_pkg::*;
`endif

    reg [31:0] rf [0:15]/* verilator public_flat_rd */;
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) rf[i] = 32'b0;
    end

    assign commit_valid = in_valid;

    assign out_ready   = commit_ready && !reset;
    assign commit_fire = commit_valid && out_ready;

    assign commit_pc       = in_pc;
    assign commit_inst     = in_inst;
    assign commit_npc      = in_npc;
    assign commit_ebreak   = in_is_ebreak;
    assign commit_skip_ref = in_is_mmio;

    assign commit_wen      = in_rf_we && (in_waddr != 5'd0);
    assign commit_rd       = in_waddr;
    assign commit_wdata    = in_wdata;

    assign out_fencei_done = commit_fire && in_is_fencei;

    always @(posedge clk) begin
        if (reset == 1'b1) begin

        end
        else if (commit_fire) begin
            `ifdef VERILATOR
                perf_event(PERF_INSTRET);
            `endif
            if (commit_wen) begin
                rf[commit_rd[3:0]] <= commit_wdata;
            end
        end
    end

    assign out_rdata1 = (in_raddr1 == 5'b0)?32'b0:rf[in_raddr1[3:0]];
    assign out_rdata2 = (in_raddr2 == 5'b0)?32'b0:rf[in_raddr2[3:0]];
    

endmodule
