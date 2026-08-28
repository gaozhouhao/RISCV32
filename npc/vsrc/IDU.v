`include "params.vh"
module IDU(

    input   reg     [31:0]              in_inst,
    input                               in_valid,
    input                               in_ready,

    input           [31:0]              in_src1_data,
    input           [31:0]              in_src2_data,

    output                              out_ready,
    output                              out_valid,
    
    output  reg                         out_rf_we,
    output  reg                         out_csr_wen,
    output  reg     [1:0]               out_wb_sel,
    output  reg                         out_csr_op_sel,
    
    output  reg                         out_is_ecall,
    output  reg                         out_is_mret,
    output  reg                         out_is_ebreak,
    output  reg                         out_is_jalr,
    output  reg                         out_is_jal,
    output  reg                         out_is_branch,
    output  reg                         out_is_load,
    output  reg                         out_is_store,
    output  reg                         out_trap_valid,

    output          [2:0]               out_branch_op,
    output          [2:0]               out_load_size,
    output          [2:0]               out_store_size,

    output  reg     [1:0]               out_alu_src2_sel,
    output  reg     [1:0]               out_alu_src1_sel,
    output  reg     [3:0]               out_alu_op,
    output          [4:0]               out_src1,
    output          [4:0]               out_src2,
    output          [4:0]               out_rd,
    output          [31:0]              out_imm,
    output          [31:0]              out_shamt,
    output          [11:0]              out_csr_addr,

    output          [31:0]              out_src1_data,
    output          [31:0]              out_src2_data
);

wire    [31:0]  immI, immS, immB, immU, immJ;

wire    [6:0]   opcode;
wire    [6:0]   funct7;
wire    [2:0]   funct3;

assign opcode = in_inst[6:0];
assign funct3 = in_inst[14:12];
assign funct7 = in_inst[31:25];

assign out_src1 = in_inst[19:15];
assign out_src2 = in_inst[24:20];
assign out_src1_data = in_src1_data;
assign out_src2_data = in_src2_data;
assign out_rd   = in_inst[11:7];

assign immI = {{20{in_inst[31]}},in_inst[31:20]};
assign immU = {in_inst[31:12],{12{1'b0}}};
assign immS = {{20{in_inst[31]}},in_inst[31:25],in_inst[11:7]};
assign immB = {{20{in_inst[31]}}, in_inst[7], in_inst[30:25] ,in_inst[11:8] ,1'b0};
assign immJ = {{12{in_inst[31]}}, in_inst[19:12], in_inst[20], in_inst[30:21], 1'b0};//out_imm[20|10:1|11|19:12]
assign out_shamt = {{27{1'b0}}, in_inst[24:20]};
assign out_csr_addr = in_inst[31:20];

assign out_branch_op = funct3;
assign out_load_size = funct3;
assign out_store_size = funct3;






always @(*) begin
    case (opcode)
        7'b0010011: out_imm = immI;
        7'b1100111: out_imm = immI;
        7'b0000011: out_imm = immI;
        7'b0110111: out_imm = immU;
        7'b0010111: out_imm = immU;
        7'b0100011: out_imm = immS;
        7'b1100011: out_imm = immB;
        7'b1101111: out_imm = immJ;

        default:    out_imm = 32'b0;
    endcase
end


always @(*) begin
    out_ready = 1;
    out_valid = in_valid;
    out_is_ecall = 1'b0;
    out_is_mret = 1'b0;
    out_is_ebreak = 1'b0;
    out_alu_op = `NPC_ALU_ADD;
    out_csr_op_sel = `CSR_WRITE;
    out_alu_src1_sel = `NPC_RS1_DATA;
    out_alu_src2_sel = 0;
    out_is_jalr = 0;
    out_is_jal = 0;
    out_is_load = 0;
    out_is_store = 0;
    out_is_branch = 0;
    out_trap_valid = 0;
    out_csr_wen = 0;
    out_rf_we = 0;
    out_wb_sel = `NPC_ALU;
    if(in_valid == 1'b1) begin
        if(opcode == 7'b0110011) begin
            out_rf_we = 1;
            out_wb_sel = `NPC_ALU;
            out_alu_src1_sel = `NPC_RS1_DATA;
            out_alu_src2_sel = `NPC_RS2_DATA;
            if(funct3 == 3'b000)begin
                if(funct7 == 7'b0000000) out_alu_op = `NPC_ALU_ADD;
                if(funct7 == 7'b0100000) out_alu_op = `NPC_ALU_SUB;
            end
            if(funct3 == 3'b001) out_alu_op = `NPC_ALU_SLL;
            if(funct3 == 3'b010) out_alu_op = `NPC_ALU_SLT;
            if(funct3 == 3'b011) out_alu_op = `NPC_ALU_SLTU;
            if(funct3 == 3'b100) out_alu_op = `NPC_ALU_XOR;
            if(funct3 == 3'b110) out_alu_op = `NPC_ALU_OR;
            if(funct3 == 3'b101) begin
                if(funct7 == 7'b0000000) out_alu_op = `NPC_ALU_SRL;
                if(funct7 == 7'b0100000) out_alu_op = `NPC_ALU_SRA;
            end
            if(funct3 == 3'b111) out_alu_op = `NPC_ALU_AND;
        end
        if(opcode == 7'b0010011) begin
            out_rf_we = 1;
            out_wb_sel = `NPC_ALU;
            out_alu_src1_sel = `NPC_RS1_DATA;
            out_alu_src2_sel = `NPC_IMM;
            if (funct3 == 3'b000) out_alu_op = `NPC_ALU_ADD; //addi
            if (funct3 == 3'b001) out_alu_op = `NPC_ALU_SLL; //slli
            if (funct3 == 3'b010) out_alu_op = `NPC_ALU_SLT;
            if (funct3 == 3'b011) out_alu_op = `NPC_ALU_SLTU; //sltiu
            if (funct3 == 3'b100) out_alu_op = `NPC_ALU_XOR;//xori
            if (funct3 == 3'b110) out_alu_op = `NPC_ALU_OR;//ori
            if (funct3 == 3'b101) begin
                out_alu_src2_sel = `NPC_SHAMT;
                if(funct7 == 7'b0000000) out_alu_op = `NPC_ALU_SRL;//srli
                if(funct7 == 7'b0100000) out_alu_op = `NPC_ALU_SRA;//srai
            end
            if(funct3 == 3'b111) out_alu_op = `NPC_ALU_AND;
        end
        if(opcode == 7'b1101111)begin // jal
            out_rf_we = 1;
            out_wb_sel = `NPC_PC4;
            out_alu_src1_sel = `NPC_CUR_PC;
            out_alu_src2_sel = `NPC_IMM;
         out_alu_op = `NPC_ALU_ADD;
            out_is_jal = 1;
        end
        if(opcode == 7'b1100111 && funct3 == 3'b000) begin//jalr
            out_rf_we = 1;
            out_wb_sel = `NPC_PC4;
            out_alu_src1_sel = `NPC_RS1_DATA;
            out_alu_src2_sel = `NPC_IMM;
         out_alu_op = `NPC_ALU_ADD;
            out_is_jalr = 1;
        end
        if (opcode == 7'b1100011) begin // branch
            out_rf_we = 0;
            out_alu_src1_sel = `NPC_CUR_PC;
            out_alu_src2_sel = `NPC_IMM;
            out_is_branch = 1;
        end

        if(opcode == 7'b0110111) begin//lui
            out_rf_we = 1;
            out_wb_sel = `NPC_ALU;
            out_alu_src1_sel = `NPC_ZERO;
            out_alu_src2_sel = `NPC_IMM;
         out_alu_op = `NPC_ALU_ADD;
        end
        if(opcode == 7'b0010111) begin //auipc
            out_rf_we = 1;
            out_wb_sel = `NPC_ALU;
            out_alu_src1_sel = `NPC_CUR_PC;
            out_alu_src2_sel = `NPC_IMM;
         out_alu_op = `NPC_ALU_ADD;
        end
        if (opcode == 7'b0000011) begin// lb/lh/lw/lbu/lhu
            out_rf_we = 1;
            out_wb_sel = `NPC_MEM;
            if(in_valid == 1'b1)begin
                out_is_load = 1'b1;
            end
            else out_is_load = 1'b0;
            out_alu_src1_sel = `NPC_RS1_DATA;
            out_alu_src2_sel = `NPC_IMM;
            out_alu_op = `NPC_ALU_ADD;
        end
        if (opcode == 7'b0100011) begin // sb/sh/sw
            out_alu_src1_sel = `NPC_RS1_DATA;
            out_alu_src2_sel = `NPC_IMM;
         out_alu_op = `NPC_ALU_ADD;
            out_is_store = 1;
        end
        
        if(in_inst == 32'b0000_0000_0000_0000_0000_0000_0111_0011) begin
            out_is_ecall = 1'b1;
            out_trap_valid = 1;
        end
        if(in_inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011) begin
            out_is_ebreak = 1'b1;
        end
        if(in_inst == 32'b0011_0000_0010_0000_0000_0000_0111_0011) begin
            out_is_mret = 1'b1;
            out_trap_valid = 1;
        end
        if(opcode == 7'b1110011) begin//priortiy
            if(funct3 == 3'b001)begin //CSRRW
                if(out_rd != 0) out_rf_we = 1;
                out_wb_sel = `NPC_CSR;
                out_csr_wen = 1;
                out_csr_op_sel = `CSR_WRITE;
            end
            if(funct3 == 3'b010)begin //CSRRS
                out_csr_wen = 1;
                if(out_rd != 0) out_rf_we = 1;
                out_wb_sel = `NPC_CSR;
                if(out_src1 != 0) out_csr_wen = 0;
                out_csr_op_sel = `CSR_SET;
            end
        end
    end

end

endmodule

