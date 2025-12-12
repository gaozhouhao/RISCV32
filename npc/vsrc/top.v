module top(
    input   clk,
    input   [31:0]  inst,
    output  [31:0]  pc
);

//always@(posedge clk)
//    $display("jump_flag:%d", jump_flag);


wire    [31:0]  next_pc;
wire            jp_en;

wire    [1:0]   wb_sel;
wire    [2:0]   imm_sel;
wire            ALUSrc;
wire    [2:0]   ALUop;
wire    [4:0]   src1;
wire    [4:0]   src2;
wire    [4:0]   rd;
wire    [31:0]  immI;
wire    [31:0]  immU;


wire    [31:0]  rsc1_data;
wire    [31:0]  rsc2_data;

wire    [31:0]  wb;

IFU ifu(
    .jp_en(jp_en),
    .clk(clk),
    .next_pc(next_pc),
    .pc(pc)
);

IDU idu(
    .inst(inst),
    .wb_sel(wb_sel),
    .imm_sel(imm_sel),
    .ALUSrc(ALUSrc),
    .ALUop(ALUop),
    .src1(src1),
    .src2(src2),
    .rd(rd),
    .immI(immI),
    .immU(immU)
);


EXU exu(
    .wb_sel(wb_sel),
    .imm_sel(imm_sel),
    .ALUSrc(ALUSrc),
    .ALUop(ALUop),
    .rsc1_data(rsc1_data),
    .rsc2_data(rsc2_data),
    .rd(rd),
    .immI(immI),
    .immU(immU),
    .wb(wb)
);




endmodule
