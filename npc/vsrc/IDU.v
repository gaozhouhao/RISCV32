module IDU #(DATA_WIDTH = 32)(
    input       [DATA_WIDTH-1:0]    inst,
    
    output      [1:0]               wb_sel,
    output      [2:0]               imm_sel,
    output                          ALUSrc,
    output      [2:0]               ALUop,
    output      [4:0]               src1,
    output      [4:0]               src2,
    output      [4:0]               rd,
    output      [DATA_WIDTH-1:0]    immI,
    output      [DATA_WIDTH-1:0]    immU
);


localparam [2:0]
  IMM_X = 3'b000,
  IMM_I = 3'b001,
  IMM_S = 3'b010,
  IMM_B = 3'b011,
  IMM_U = 3'b100,
  IMM_J = 3'b101;

localparam [1:0]
  WB_ALU = 2'b00,
  WB_MEM = 2'b01,
  WB_PC4 = 2'b10;


wire    [6:0]   opcode;
wire    [2:0]   funct3;

assign src1 = inst[19:15];
assign src2 = inst[24:20];
assign rd   = inst[11:7];

assign immI = {{20{inst[31]}},inst[31:20]};
assign immU = {inst[31:12],{12{1'b0}}};

always @(*) begin
    case(opcode)
        7'b0010011: imm_sel = IMM_I;
        defaule:    imm_sel = IMM_X;
    endcase
end

always @(*) begin
    ALUop = 0;
    ALUSrc = 0;
    if(opcode == 7'b0010011 && funct3 == 3'b000) begin
        ALUSrc = 1;
        ALUop = 3'b001;//addi
        wb_sel = WB_ALU;
    end
end

endmodule
