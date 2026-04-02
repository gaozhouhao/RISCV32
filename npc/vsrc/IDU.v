`include "params.vh"
module IDU(
    input           [31:0]              pc,
    input   reg     [31:0]              inst,
    input                               ifu_to_idu_valid,
    output                              ifu_to_idu_ready,
    input                               idu_to_exu_ready,
    output                              idu_to_exu_valid,
    
    output  reg                         sen, 
    output  reg                         idu_we,
    output  reg                         csr_wen,
    output  reg     [1:0]               wb_sel,
    output  reg     [2:0]               nextpc_sel,
    output  reg                         csr_op_sel,
    
    output  reg                         is_ecall,
    output  reg                         is_ebreak,
    output  reg                         is_jalr,
    output  reg                         is_jal,
    output  reg                         is_branch,
    output  reg                         is_csr,
    output  reg                         is_load,
    output  reg                         is_store,
    output  reg                         trapValid,
    output  reg                         id_done,

    output          [2:0]               funct3,

    output  reg     [1:0]               alu_src2_sel,
    output  reg     [1:0]               alu_src1_sel,
    output  reg     [3:0]               ALUop,
    output          [4:0]               src1,
    output          [4:0]               src2,
    output          [4:0]               rd,
    output          [31:0]              imm,
    output          [31:0]              shamt,
    output          [11:0]              csr_addr
);

wire    [31:0]  immR, immI, immS, immB, immU, immJ;

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
assign immB = {{20{inst[31]}}, inst[7], inst[30:25] ,inst[11:8] ,1'b0};
assign immJ = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};//imm[20|10:1|11|19:12]
assign shamt = {{27{1'b0}}, inst[24:20]};
assign csr_addr = inst[31:20];


always @(*) begin
    case (opcode)
        7'b0010011: imm = immI;
        7'b1100111: imm = immI;
        7'b0000011: imm = immI;
        7'b0110111: imm = immU;
        7'b0010111: imm = immU;
        7'b0100011: imm = immS;
        7'b1100011: imm = immB;
        7'b1101111: imm = immJ;

        default:    imm = 32'b0;
    endcase
end


always @(*) begin
    ifu_to_idu_ready = 1;
    idu_to_exu_valid = ifu_to_idu_valid;
    is_ecall = 1'b0;
    is_ebreak = 1'b0;
    ALUop = `NPC_ALU_ADD;
    csr_op_sel = `CSR_WRITE;
    alu_src1_sel = `NPC_RS1_DATA;
    alu_src2_sel = 0;
    is_jalr = 0;
    is_jal = 0;
    is_csr = 0;
    is_load = 0;
    is_store = 0;
    is_branch = 0;
    trapValid = 0;
    id_done = 0;
    csr_wen = 0;
    sen = 0;
    idu_we = 0;
    wb_sel = `NPC_ALU;
    //nextpc_sel = `PCSEL_C_PC;
    if(ifu_to_idu_valid == 1'b1) begin
        if(opcode == 7'b0110011) begin
            idu_we = 1;
            wb_sel = `NPC_ALU;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_RS2_DATA;
            //nextpc_sel = `PCSEL_PC4;
            if(funct3 == 3'b000)begin
                if(funct7 == 7'b0000000) ALUop = `NPC_ALU_ADD;
                if(funct7 == 7'b0100000) ALUop = `NPC_ALU_SUB;
            end
            if(funct3 == 3'b001) ALUop = `NPC_ALU_SLL;
            if(funct3 == 3'b010) ALUop = `NPC_ALU_SLT;
            if(funct3 == 3'b011) ALUop = `NPC_ALU_SLTU;
            if(funct3 == 3'b100) ALUop = `NPC_ALU_XOR;
            if(funct3 == 3'b110) ALUop = `NPC_ALU_OR;
            if(funct3 == 3'b101) begin
                if(funct7 == 7'b0000000) ALUop = `NPC_ALU_SRL;
                if(funct7 == 7'b0100000) ALUop = `NPC_ALU_SRA;
            end
            if(funct3 == 3'b111) ALUop = `NPC_ALU_AND;
        end
        if(opcode == 7'b0010011) begin
            idu_we = 1;
            wb_sel = `NPC_ALU;
            //nextpc_sel = `PCSEL_PC4;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            if (funct3 == 3'b000) ALUop = `NPC_ALU_ADD; //addi
            if (funct3 == 3'b001) ALUop = `NPC_ALU_SLL; //slli
            if (funct3 == 3'b010) ALUop = `NPC_ALU_SLT;
            if (funct3 == 3'b011) ALUop = `NPC_ALU_SLTU; //sltiu
            if (funct3 == 3'b100) ALUop = `NPC_ALU_XOR;//xori
            if (funct3 == 3'b110) ALUop = `NPC_ALU_OR;//ori
            if (funct3 == 3'b101) begin
                alu_src2_sel = `NPC_SHAMT;
                if(funct7 == 7'b0000000) ALUop = `NPC_ALU_SRL;//srli
                if(funct7 == 7'b0100000) ALUop = `NPC_ALU_SRA;//srai
            end
            if(funct3 == 3'b111) ALUop = `NPC_ALU_AND;
        end
        if(opcode == 7'b1101111)begin // jal
            idu_we = 1;
            wb_sel = `NPC_PC4;
            alu_src1_sel = `NPC_CUR_PC;
            alu_src2_sel = `NPC_IMM;
            ALUop = `NPC_ALU_ADD;
            //nextpc_sel = `PCSEL_JAL;
            is_jal = 1;
        end
        if(opcode == 7'b1100111 && funct3 == 3'b000) begin//jalr
            idu_we = 1;
            wb_sel = `NPC_PC4;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            ALUop = `NPC_ALU_ADD;
            //nextpc_sel = `PCSEL_JALR;
            is_jalr = 1;
        end
        if (opcode == 7'b1100011) begin // branch
            idu_we = 0;
            alu_src1_sel = `NPC_CUR_PC;
            alu_src2_sel = `NPC_IMM;
            //nextpc_sel = `PCSEL_BR;
            is_branch = 1;
        end

        if(opcode == 7'b0110111) begin//lui
            idu_we = 1;
            wb_sel = `NPC_ALU;
            alu_src1_sel = `NPC_ZERO;
            alu_src2_sel = `NPC_IMM;
            ALUop = `NPC_ALU_ADD;
            //nextpc_sel = `PCSEL_PC4;
        end
        if(opcode == 7'b0010111) begin //auipc
            idu_we = 1;
            wb_sel = `NPC_ALU;
            alu_src1_sel = `NPC_CUR_PC;
            alu_src2_sel = `NPC_IMM;
            ALUop = `NPC_ALU_ADD;
            //nextpc_sel = `PCSEL_PC4; 
        end
        if (opcode == 7'b0000011) begin// lb/lh/lw/lbu/lhu
            idu_we = 1;
            wb_sel = `NPC_MEM;
            if(ifu_to_idu_valid == 1'b1)begin
                is_load = 1'b1;
            end
            else is_load = 1'b0;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            ALUop = `NPC_ALU_ADD;
            //nextpc_sel = `PCSEL_PC4;
        end
        if (opcode == 7'b0100011) begin // sb/sh/sw
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            ALUop = `NPC_ALU_ADD;
            sen = 1;
            is_store = 1;
            //nextpc_sel = `PCSEL_PC4;
        end
        
        if(inst == 32'b0000_0000_0000_0000_0000_0000_0111_0011) begin
            is_ecall = 1'b1;
            //nextpc_sel = `PCSEL_MTVEC;
            trapValid = 1;
        end
        if(inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011) begin
            is_ebreak = 1'b1;
        end
        if(inst == 32'b0011_0000_0010_0000_0000_0000_0111_0011) begin
            //nextpc_sel = `PCSEL_MEPC;
            trapValid = 1;
        end
        if(opcode == 7'b1110011) begin//priortiy
            if(funct3 == 3'b001)begin //CSRRW
                is_csr = 1;
                if(rd != 0) idu_we = 1;
                wb_sel = `NPC_CSR;
                csr_wen = 1;
                csr_op_sel = `CSR_WRITE;
            end
            if(funct3 == 3'b010)begin //CSRRS
                is_csr = 1;
                csr_wen = 1;
                if(rd != 0) idu_we = 1;
                wb_sel = `NPC_CSR;
                if(src1 != 0) csr_wen = 0;
                csr_op_sel = `CSR_SET;
            end
        end
    end
    else begin
        //is_load = 1'b0;
        //wen = 1'b0;
        //csr_wen = 1'b0;
        //sen = 1'b0;
        //idu_to_exu_valid = 1'b0;
    end
end

endmodule




