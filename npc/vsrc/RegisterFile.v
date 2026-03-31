module RegisterFile(
    input                       clk,
    input                       reset,
    input       [31:0]            wdata,
    input       [4:0]             waddr,
    input                       lsu_rf_we,
    output  reg                   wb_done,
    output  reg                   wb_done_flag,
    input       [4:0]             raddr1,
    input       [4:0]             raddr2,
    output      [31:0]            rdata1,
    output      [31:0]            rdata2,

    input                       exu_to_rf_valid,
    output                      exu_to_rf_ready,
    input                       lsu_to_rf_valid,
    output                      lsu_to_rf_ready,
    input                       rf_to_ifu_ready,
    output                      rf_to_ifu_valid
);

    assign rf_to_ifu_valid = lsu_to_rf_valid;
    
    reg [31:0] rf [31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'b0;
    end
    
    always @(*) begin
        wb_done = lsu_to_rf_valid && reset;
    end

    always @(posedge clk) begin
        if(reset == 0) wb_done_flag <= 0;
        else if(lsu_to_rf_valid)begin
            if (lsu_rf_we) 
                if(waddr != 5'b0) begin
                    rf[waddr] <= wdata;
                end
            wb_done_flag <= 1;
        end
        else wb_done_flag <= 0;
    end
    
    assign exu_to_rf_ready = 1;

    assign rdata1 = (raddr1 == 5'b0)?{32{1'b0}}:rf[raddr1];
    assign rdata2 = (raddr2 == 5'b0)?{32{1'b0}}:rf[raddr2];
    

endmodule
