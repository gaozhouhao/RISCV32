module IDU #(DATA_WIDTH = 32)(
    //input   wire       [DATA_WIDTH-1:0]    inst,
    input           [31:0]              pc,
    output  reg                         sen, 
    output  reg                         wen,
    output  reg     [1:0]               wb_sel,
    output  reg     [1:0]               nextpc_sel,
    
    output  reg                         is_ebreak,
    output  reg                         is_jalr,
    
    output          [2:0]               funct3,

    output  reg                         ALUSrc,
    output  reg     [1:0]               alu_src1_sel,
    output  reg     [2:0]               ALUop,
    output          [4:0]               src1,
    output          [4:0]               src2,
    output          [4:0]               rd,
    output          [DATA_WIDTH-1:0]    imm
);


localparam [1:0]
    src_ALU = 2'b00,
    src_MEM = 2'b01,
    src_PC4 = 2'b10,
    src_No  = 2'b11;

localparam [1:0]
    src_data = 2'b00,
    cur_pc   = 2'b01,
    src_zero = 2'b10;

wire    [31:0]  immI;
wire    [31:0]  immU;
wire    [31:0]  immS;

reg    [31:0]  inst;
wire    [6:0]   opcode;
wire    [6:0]   funct7;

assign opcode = inst[6:0];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

assign src1 = inst[19:15];
assign src2 = inst[24:20];
assign rd   = inst[11:7];

assign immI = {{20{inst[31]}},inst[31:20]};
assign immU = {inst[31:12],{12{1'b0}}};
assign immS = {{20{inst[31]}},inst[31:25],inst[11:7]};

always @(*) begin
    case (opcode)
        7'b0010011: imm = immI;
        7'b1100111: imm = immI;
        7'b0000011: imm = immI;
        7'b0110111: imm = immU;
        7'b0100011: imm = immS;
        default:    imm = 32'b0;
    endcase
end

import "DPI-C" function int unsigned pmem_read(input int unsigned raddr); 
always @(*) begin
    inst = pmem_read(pc);
end


always @(*) begin
    is_ebreak = 1'b0;
    ALUop = 0;
    alu_src1_sel = src_data;
    ALUSrc = 0;
    is_jalr = 0;
    wen = 0;
    sen = 0;
    wb_sel = src_No;
    nextpc_sel = src_PC4;
    if(opcode == 7'b0010011 && funct3 == 3'b000) begin//addi
        alu_src1_sel = src_data;
        ALUSrc = 1;
        wen = 1;
        ALUop = 3'b001;//add
        wb_sel = src_ALU;
        nextpc_sel = src_PC4;
    end
    if(opcode == 7'b1100111 && funct3 == 3'b000) begin//jalr
        wen = 1;
        wb_sel = src_PC4;
        alu_src1_sel = src_data;
        ALUSrc = 1;
        ALUop = 3'b001;
        nextpc_sel = src_ALU;
        is_jalr = 1;
    end
    if(opcode == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000000) begin//add
        wen = 1;
        wb_sel = src_ALU;
        alu_src1_sel = src_data;
        ALUSrc = 0;
        ALUop = 3'b001;
        nextpc_sel = src_PC4;
    end
    if(opcode == 7'b0110111) begin//lui
        wen = 1;
        wb_sel = src_ALU;
        alu_src1_sel = src_zero;
        ALUSrc = 1;
        ALUop = 3'b001;
        nextpc_sel = src_PC4;
    end
    if (opcode == 7'b0000011) begin// lw/lbu
        wen = 1;
        wb_sel = src_MEM;
        alu_src1_sel = src_data;
        ALUSrc = 1;
        ALUop = 3'b001;
        nextpc_sel = src_PC4;
    end
    if (opcode == 7'b0100011) begin // sw/sb
        alu_src1_sel = src_data;
        ALUSrc = 1;
        ALUop = 3'b001;
        sen = 1;
        nextpc_sel = src_PC4;
    end
    if(inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011) begin
        is_ebreak = 1'b1;
    end
end

endmodule
