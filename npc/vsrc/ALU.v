`include "params.vh"
module ALU(
    input           [31:0]  alu_src1,
    input           [31:0]  alu_src2,
    input           [1:0]   alu_src1_sel,
    input           [1:0]   alu_src2_sel,
    input           [3:0]   ALUop,

    input           [31:0]  src1_data,
    input           [31:0]  src2_data,

    output  reg     [31:0]  alu_result,
    output          [3:0]   alu_flags
);

reg [31:0]  alu_diff;
reg alu_cout;
reg alu_zero, alu_negative, alu_no_borrow, alu_overflow;
always @(*) begin
    {alu_cout, alu_diff} = {1'b0, alu_src1} + {1'b0, ~alu_src2} + 33'b1;
    alu_zero = (alu_diff == 32'b0);
    alu_negative = alu_diff[31];
    alu_no_borrow = alu_cout;
    alu_overflow = (alu_src1[31] ^ alu_src2[31]) & (alu_src1[31] ^ alu_diff[31]);
end

always @(*) begin
    //$display("OP:%d\n", ALUop);
    case (ALUop)
        `NPC_ALU_ADD:   alu_result = alu_src1 + alu_src2;
        `NPC_ALU_SUB:   alu_result = alu_src1 +  ~alu_src2 + 1'b1;
        `NPC_ALU_AND:   alu_result = alu_src1 & alu_src2;
        `NPC_ALU_OR:    alu_result = alu_src1 | alu_src2;
        `NPC_ALU_XOR:   alu_result = alu_src1 ^ alu_src2;
        `NPC_ALU_SLL:   alu_result = alu_src1 << alu_src2[4:0];
        `NPC_ALU_SRL:   alu_result = alu_src1 >> alu_src2[4:0]; 
        `NPC_ALU_SRA:   alu_result = {32{alu_src1[31]}} << (32-alu_src2[4:0]) | alu_src1 >> alu_src2[4:0]; 
        `NPC_ALU_SLT:   alu_result = {31'b0, alu_negative^alu_overflow}; 
        `NPC_ALU_SLTU:  alu_result = {31'b0, ~alu_no_borrow};
        default:        alu_result = 32'hffff;
    endcase
end

reg [31:0] result;
reg        cout;

reg zero, negative, no_borrow, overflow;
always @(*) begin
    {cout, result} = {1'b0, src1_data} + {1'b0, ~src2_data} + 33'b1;
    zero = (result == 32'b0);
    negative = result[31];
    no_borrow = cout;
    overflow = (src1_data[31] ^ src2_data[31]) & (src1_data[31] ^ result[31]);
end

assign alu_flags[`ALU_FLAG_ZERO] = zero;
assign alu_flags[`ALU_FLAG_NEGATIVE] = negative;
assign alu_flags[`ALU_FLAG_NOBORROW] = no_borrow;
assign alu_flags[`ALU_FLAG_OVERFLOW] = overflow;



endmodule
