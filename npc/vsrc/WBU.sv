module WBU(
    input               clk,
    input               reset,
    input               in_valid,
    input               in_ready,
    input       [31:0]  in_wdata,
    input       [ 4:0]  in_waddr,
    input               in_rf_we,
    input       [ 4:0]  in_raddr1,
    input       [ 4:0]  in_raddr2,

    output      [31:0]  out_rdata1,
    output      [31:0]  out_rdata2,
    output  reg         out_wb_done,
    output              out_ready,
    output              out_valid
);
    import perf_pkg::*;
    always @(posedge clk) begin
        if (out_valid && in_ready) begin

        end
    end


    reg [31:0] rf [31:0]/* verilator public_flat_rd */;
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'b0;
    end
    assign out_wb_done = out_valid && in_ready;
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            out_valid <= 1'b0;
        end
        else if (in_valid && out_ready) begin
            if (in_rf_we) 
                if(in_waddr != 5'b0) begin
                    rf[in_waddr] <= in_wdata;
                end
            perf_event(PERF_INSTRET);
            out_valid <= 1'b1;
        end
        else if (out_valid && in_ready) begin
            out_valid <= 1'b0;
        end
    end

    assign out_ready = in_ready;
    assign out_rdata1 = (in_raddr1 == 5'b0)?{32{1'b0}}:rf[in_raddr1];
    assign out_rdata2 = (in_raddr2 == 5'b0)?{32{1'b0}}:rf[in_raddr2];
    

endmodule
