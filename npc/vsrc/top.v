module top(
    input   clk,
    input   [31:0]  inst,
    output  [7:0]   seg0,
    output  [7:0]   seg1
);

//always@(posedge clk)
//    $display("jump_flag:%d", jump_flag);

wire    [3:0]   next_pc;
wire    [7:0]   q;
wire            jump_flag;

wire            jp_en;
wire            wen;
wire    [1:0]   waddr;
wire    [1:0]   raddr1;
wire    [1:0]   raddr2;
wire    [7:0]   wdata;
wire    [7:0]   rdata1;
wire    [7:0]   rdata2;

wire    [31:0]  next_pc;
wire    [31:0]  pc;




IFU ifu(
    .jp_en(.jp_en),
    .clk(clk),
    .next_pc(next_pc),
    .pc(pc)
);

IDU idu(
    .inst(inst)
);


rom rom(
    .jump_flag(jump_flag),
    .next_pc(next_pc),
    .clk(clk),
    .q(q)
);

inst inst(
    .q(q),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .wen(wen),
    .raddr1(raddr1),
    .raddr2(raddr2),
    .waddr(waddr),
    .wdata(wdata),
    .jump_flag(jump_flag),
    .next_pc(next_pc),
    .seg0(seg0),
    .seg1(seg1)
);

ram ram(
    .wen(wen),
    .clk(clk),
    .waddr(waddr),
    .raddr1(raddr1),
    .raddr2(raddr2),
    .wdata(wdata),
    .rdata1(rdata1),
    .rdata2(rdata2)
);


endmodule
