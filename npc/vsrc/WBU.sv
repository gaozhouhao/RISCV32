module WBU(
    input                       clk,
    input                       reset,
    input       [31:0]            wdata,
    input       [4:0]             waddr,
    input                       lsu_rf_we,
    output  reg                   wb_done,
    input       [4:0]             raddr1,
    input       [4:0]             raddr2,
    output      [31:0]            rdata1,
    output      [31:0]            rdata2,

    input                       lsu_to_rf_valid,
    output                      out_ready,
    input                       rf_to_ifu_ready,
    output                      rf_to_ifu_valid
);

    assign rf_to_ifu_valid = lsu_to_rf_valid;
    
    reg [31:0] rf [31:0]/* verilator public_flat_rd */;

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'b0;
    end
    
    always @(*) begin
        wb_done = lsu_to_rf_valid && ~reset;
    end



    always @(posedge clk) begin
        if(lsu_to_rf_valid)begin
            if (lsu_rf_we) 
                if(waddr != 5'b0) begin
                    rf[waddr] <= wdata;
                end
        end
    end
    
    assign out_ready = 1'b1;

    assign rdata1 = (raddr1 == 5'b0)?{32{1'b0}}:rf[raddr1];
    assign rdata2 = (raddr2 == 5'b0)?{32{1'b0}}:rf[raddr2];
    

endmodule
