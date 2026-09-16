module WBU(
    input               clk,
    input               reset,
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
    output              commit_fire
    output      [31:0]  out_rdata1,
    output      [31:0]  out_rdata2,
    output  reg         out_fencei_done,
    output              out_ready
);

`ifdef VERILATOR
    import perf_pkg::*;
`endif
    always @(posedge clk) begin
        if (out_valid && in_ready) begin
            `ifdef VERILATOR
                perf_event(PERF_INSTRET);
            `endif
        end
    end


    reg [31:0] rf [0:15]/* verilator public_flat_rd */;
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) rf[i] = 32'b0;
    end

    reg is_mmio/* verilator public_flat_rd */;

    assign commit_valid = in_valid;
    assign commit_fire  = commit_valid && commit_ready;
    assign out_ready = commit_ready;
    assign out_fencei_done = commit_fire && in_is_fencei;


    always @(posedge clk) begin
        if(out_wb_done)
            is_mmio <= in_is_mmio;
    end

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            is_mmio <= 1'b0;
        end
        else if (commit_fire) begin
            `ifdef VERILATOR
                perf_event(PERF_INSTRET);
            `endif
            if (in_rf_we && in_waddr != 5'b0) begin
                rf[in_waddr[3:0]] <= in_wdata;
            end
        end
        else if (in_valid && out_ready) begin
            if (in_rf_we) begin
                if(in_waddr != 5'b0) begin
                    rf[in_waddr[3:0]] <= in_wdata;
                end
            end
            is_mmio <= in_is_mmio;
        end

    end

    assign out_ready = !out_valid || in_ready;
    assign out_rdata1 = (in_raddr1 == 5'b0)?32'b0:rf[in_raddr1[3:0]];
    assign out_rdata2 = (in_raddr2 == 5'b0)?32'b0:rf[in_raddr2[3:0]];
    

endmodule
