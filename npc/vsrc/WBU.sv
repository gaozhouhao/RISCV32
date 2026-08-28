module WBU(
    input               clk,
    input               reset,
    input               in_valid,
    input               in_ready,
    input       [31:0]  in_wdata,
    input       [ 4:0]  in_waddr,
    input               lsu_rf_we,
    input       [ 4:0]  in_raddr1,
    input       [ 4:0]  in_raddr2,

    output      [31:0]  out_rdata1,
    output      [31:0]  out_rdata2,
    output  reg         out_wb_done,
    output              out_ready,
    output              out_valid
);

    assign out_valid = in_valid;
    
    reg [31:0] rf [31:0]/* verilator public_flat_rd */;

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'b0;
    end
    
    always @(*) begin
        out_wb_done = in_valid && ~reset;
    end

    always @(posedge clk) begin
        if(in_valid)begin
            if (lsu_rf_we) 
                if(in_waddr != 5'b0) begin
                    rf[in_waddr] <= in_wdata;
                end
        end
    end
    
    assign out_ready = 1'b1;

    assign out_rdata1 = (in_raddr1 == 5'b0)?{32{1'b0}}:rf[in_raddr1];
    assign out_rdata2 = (in_raddr2 == 5'b0)?{32{1'b0}}:rf[in_raddr2];
    

endmodule
