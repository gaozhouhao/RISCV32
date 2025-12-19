module IFU #(ADDR_WIDTH = 32, DATA_WIDTH = 32) (
    input                               is_jalr,
    input                               clk,
    input           [ADDR_WIDTH-1:0]    next_pc,
    output  reg     [ADDR_WIDTH-1:0]    pc
);
initial pc = 0'h80000000;

always @(posedge clk) begin
    if(is_jalr)
        pc <= next_pc & ~32'b1;
    else
        pc <= next_pc;

end


endmodule
