module EXU (
    input   wire    [1:0]       nextpc_sel, 
    input   wire    [1:0]       wb_sel,
    input   reg                 ALUSrc,
    input   reg     [2:0]       ALUop,
    
    input   reg     [31:0]      pc,
    input   wire    [31:0]      src1_data,
    input   wire    [31:0]      src2_data,
    input   wire    [4:0]       rd,
    input   reg     [31:0]      imm,
    
    output  reg     [31:0]      wb,
    output  reg     [31:0]      next_pc
);

reg    [31:0]  alu_src1;
reg    [31:0]  alu_src2;
reg    [31:0]  alu_result;

wire    [31:0]  immI;
wire    [31:0]  immU;

localparam [2:0]
    IMM_X = 3'b000,
    IMM_I = 3'b001,
    IMM_S = 3'b010,
    IMM_B = 3'b011,
    IMM_U = 3'b100,
    IMM_J = 3'b101;

localparam [1:0]
    src_ALU = 2'b00,
    src_MEM = 2'b01,
    src_PC4 = 2'b10,
    src_No  = 2'b11;


always @(*) begin
    case (ALUop)
        3'b001: alu_result = alu_src1 + alu_src2;
        default:alu_result = 32'b0;
    endcase
end

always @(*) begin
    alu_src1 = src1_data;
    alu_src2 = ALUSrc?imm:src2_data;
end

always @(*) begin
    case (wb_sel)
        src_ALU: wb = alu_result;
        src_PC4: wb = pc + 32'h4;
        default: wb = 32'b0;
    endcase
    case (nextpc_sel)
        src_ALU: next_pc = alu_result;
        src_PC4: next_pc = pc + 32'h4;
        default: next_pc = 32'b0;
    endcase
end


endmodule
