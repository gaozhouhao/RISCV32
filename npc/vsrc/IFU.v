module IFU #(ADDR_WIDTH = 32, DATA_WIDTH = 32) (
    input                               jp_en,
    input                               clk,
    input           [ADDR_WIDTH-1:0]    next_pc,
    output  reg     [ADDR_WIDTH-1:0]    pc
);


always @(posedge clk) begin
    if(jp_en)
        pc <= next_pc;
    else
        pc <= pc + 32'h4;
end


endmodule
