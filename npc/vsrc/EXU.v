module EXU (
    input   wire    [1:0]       wb_sel,
    input   wire    [2:0]       imm_sel,
    input   reg                 ALUSrc,
    input   reg     [2:0]       ALUop,
    input   wire    [31:0]      rsc1_data,
    input   wire    [31:0]      rsc2_data,
    input   wire    [4:0]       rd,
    input   wire    [31:0]      immI,
    input   wire    [31:0]      immU,
    
    output  reg     [31:0]      wb
);

reg    [31:0]  imm;
reg    [31:0]  alu_rsc1;
reg    [31:0]  alu_rsc2;
reg    [31:0]  alu_result;


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


always @(*) begin
    case (imm_sel)
        IMM_I:  imm = immI;
        IMM_U:  imm = immU;
        default:imm = 32'b0;
    endcase
end

always @(*) begin
    case (ALUop)
        3'b001: alu_result = alu_rsc1 + alu_rsc2;
        default:alu_result = 32'b0;
    endcase
end

always @(*) begin
    alu_rsc1 = rsc1_data;
    alu_rsc2 = ALUSrc?imm:rsc2_data;
end

always @(*) begin
    case (wb_sel)
        WB_ALU: wb = alu_result;
        default:wb = 32'b0;
    endcase
end


endmodule
