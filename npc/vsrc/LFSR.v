module LFSR(
    input                   clk, 
    output          [7:0]   random_num
);


reg x0, x1, x2, x3, x4, x5, x6, x7, x8;

initial x0 = 1'b1;


assign random_num = {x7, x6, x5, x4, x3, x2, x1, x0};
always @ (posedge clk) begin
    x0 <= x1;
    x1 <= x2;
    x2 <= x3;
    x3 <= x4;
    x4 <= x5;
    x5 <= x6;
    x6 <= x7;
    x7 <= x8;
    x8 <= x0 ^ x2 ^ x3 ^ x4;
end



endmodule
