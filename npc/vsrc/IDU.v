module IDU #(DATA_WIDTH = 32)(
    input   wire       [DATA_WIDTH-1:0]    inst,
    
    output  reg                         wen,
    output  reg     [1:0]               wb_sel,
    output  reg     [1:0]               nextpc_sel,

    output  reg                         is_jalr,
    output  reg                         ALUSrc,
    output  reg     [2:0]               ALUop,
    output          [4:0]               src1,
    output          [4:0]               src2,
    output          [4:0]               rd,
    output          [DATA_WIDTH-1:0]    imm
);


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

wire    [31:0]  immI;
wire    [31:0]  immU;

wire    [6:0]   opcode;
wire    [2:0]   funct3;

assign opcode = inst[6:0];
assign src1 = inst[19:15];
assign src2 = inst[24:20];
assign rd   = inst[11:7];

assign immI = {{20{inst[31]}},inst[31:20]};
assign immU = {inst[31:12],{12{1'b0}}};

always @(*) begin
    case (opcode)
        7'b0010011: imm = immI;
        7'b1100111: imm = immI;
        default:    imm = 32'b0;
    endcase
end

always @(*) begin
    ALUop = 0;
    ALUSrc = 0;
    is_jalr = 0;
    wen = 0;
    wb_sel = src_No;
    nextpc_sel = src_No;
    if(opcode == 7'b0010011 && funct3 == 3'b000) begin//addi
        ALUSrc = 1;
        wen = 1;
        ALUop = 3'b001;//addi
        wb_sel = src_ALU;
        nextpc_sel = src_PC4;
    end
    if(opcode == 7'b1100111 && funct3 == 3'b000) begin//jalr
        wen = 1;
        wb_sel = src_PC4;
        ALUSrc = 1;
        ALUop = 3'b001;
        nextpc_sel = src_ALU;
        is_jalr = 1;
    end
end

endmodule
