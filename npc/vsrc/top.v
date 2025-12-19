module top(
    input   clk,
    //input   [31:0]  inst,
    output  [31:0]  pc
);

wire    [31:0]  inst;
wire    [31:0]  next_pc;

wire            is_ebreak;
wire            is_jalr;
wire            wen;
wire            sen;

wire    [1:0]   nextpc_sel;
wire    [1:0]   wb_sel;
wire    [1:0]   alu_src1_sel;
wire            ALUSrc;
wire    [2:0]   ALUop;
wire    [4:0]   src1;
wire    [4:0]   src2;
wire    [4:0]   rd;
wire    [31:0]  imm;

wire    [31:0]  src1_data;
wire    [31:0]  src2_data;

wire    [31:0]  wb;

wire    [2:0]   funct3;
IFU ifu(
    .is_jalr(is_jalr),
    .clk(clk),
    .next_pc(next_pc),
    .pc(pc)
);

IDU idu(
    //.inst(inst),
    .pc(pc),
    .wen(wen),
    .sen(sen),
    .is_ebreak(is_ebreak),
    .is_jalr(is_jalr),
    .wb_sel(wb_sel),
    .nextpc_sel(nextpc_sel),
    .alu_src1_sel(alu_src1_sel),
    .ALUSrc(ALUSrc),
    .ALUop(ALUop),
    .funct3(funct3),
    .src1(src1),
    .src2(src2),
    .rd(rd),
    .imm(imm)
);


EXU exu(
    .clk(clk),
    .nextpc_sel(nextpc_sel),
    .wb_sel(wb_sel),
    .alu_src1_sel(alu_src1_sel),
    .ALUSrc(ALUSrc),
    .ALUop(ALUop),
    .is_ebreak(is_ebreak),
    .pc(pc),
    .src1_data(src1_data),
    .src2_data(src2_data),
    .rd(rd),
    .imm(imm),
    .wb(wb),
    .sen(sen),
    .funct3(funct3),
    .next_pc(next_pc)
);

RegisterFile regfile (
    .clk(clk),
    .wdata(wb),
    .waddr(rd),
    .wen(wen),
    .raddr1(src1),
    .raddr2(src2),
    .rdata1(src1_data),
    .rdata2(src2_data)
);


endmodule
