module EXU (
    input       [1:0]       wb_sel,
    input       [2:0]       imm_sel,
    input                   ALUSrc,
    input       [2:0]       ALUop,
    input       [4:0]       rsc1_data,
    input       [4:0]       rsc2_data,
    input       [4:0]       rd,
    input       [31:0]      immI,
    input       [31:0]      immU,
    
    output      [31:0]      wb
);

wire    [31:0]  imm;
wire    [31:0]  alu_rsc1;
wire    [31:0]  alu_rsc2;
wire    [31:0]  alu_result;
wire    [31:0]  wb;


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
    alu_src1 = rsc1_data;
    alu_src2 = ALUSrc?imm:rsc2_data;
end

always @(*) begin
    case (wb_sel)
        WB_ALU: wb = alu_result;
        default:wb = 32'b0;
    endcase
end


endmodule
