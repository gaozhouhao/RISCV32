module IFU #(ADDR_WITH = 1, DATA_WIDTH = 1) (
    input                           jp_en,
    input                           clk,
    input       [ADDR_WIDTH-1:0]    next_pc,
    output      [ADDR_WIDTH-1:0]    pc
);


reg [ADDR_WIDTH-1:0]    pc;

always @(posedge clk) begin
    if(jp_en)
        pc <= next_pc;
    else
        pc <= pc + 4;
end


endmodule
