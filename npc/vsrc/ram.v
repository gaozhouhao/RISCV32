module ram(
    input           wen,
    input           clk,
    input   [1:0]   waddr,
    input   [1:0]   raddr1,
    input   [1:0]   raddr2,
    input   [7:0]   wdata,
    output  reg    [7:0]   rdata1,
    output  reg    [7:0]   rdata2
);

reg     [7:0]   register[4];

initial begin
    register[0] = 8'b0;
    register[1] = 8'b0;
    register[2] = 8'b0;
    register[3] = 8'b0;
end

always @(posedge clk) begin
    if(wen == 1) begin
        register[waddr] <= wdata;
    end
end

assign rdata1 = register[raddr1];
assign rdata2 = register[raddr2];

endmodule
