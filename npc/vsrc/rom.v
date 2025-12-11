module rom(
    input           jump_flag,
    input           clk,
    input       [3:0]   next_pc,
    output  [7:0]   q);

reg [7:0]   FF[0:15];

reg [3:0]   current_pc;

always @(posedge clk) begin
//    $display("next_pc:%d\nflag:%d", next_pc, jump_flag);
    if(jump_flag == 1) begin
        current_pc <= next_pc;
    end
    else
        current_pc <= current_pc + 1;

end

initial begin
    FF[0] = 8'b10001010;
    FF[1] = 8'b10010000;
    FF[2] = 8'b10100000;
    FF[3] = 8'b10110001;
    FF[4] = 8'b00010111;
    FF[5] = 8'b00101001;
    FF[6] = 8'b11010001;
    FF[7] = 8'b01011110;
    FF[8] = 8'b11100010;
end

assign q = FF[current_pc];
//always@(posedge clk)
//    $display("q:%x",q);

endmodule
