`include "params.vh"
module IDU(
    input                   clk,
    input                   reset,
    input   reg     [31:0]  in_inst,
    input                   in_valid,
    input                   in_ready,

    input           [31:0]  in_src1_data,
    input           [31:0]  in_src2_data,

    output                  out_ready,
    output                  out_valid,
    
    output  reg             out_rf_we,
    output  reg             out_csr_wen,
    output  reg     [ 1:0]  out_wb_sel,
    output  reg             out_csr_op_sel,
    
    output  reg             out_is_ecall,
    output  reg             out_is_mret,
    output  reg             out_is_ebreak,
    output  reg             out_is_jalr,
    output  reg             out_is_jal,
    output  reg             out_is_branch,
    output  reg             out_is_load,
    output  reg             out_is_store,
    output  reg             out_trap_valid,

    output          [ 2:0]  out_branch_op,
    output          [ 2:0]  out_load_size,
    output          [ 2:0]  out_store_size,

    output  reg     [ 1:0]  out_alu_src2_sel,
    output  reg     [ 1:0]  out_alu_src1_sel,
    output  reg     [ 3:0]  out_alu_op,
    output          [ 4:0]  out_src1,
    output          [ 4:0]  out_src2,
    output          [ 4:0]  out_rd,
    output          [31:0]  out_imm,
    output          [31:0]  out_shamt,
    output          [11:0]  out_csr_addr,

    output          [31:0]  out_src1_data,
    output          [31:0]  out_src2_data,
    output          [ 4:0]  idu_decode_src1,
    output          [ 4:0]  idu_decode_src2
);

`ifdef VERILATOR
    import perf_pkg::*;
`endif
wire    [31:0]  immI, immS, immB, immU, immJ;

wire    [6:0]   opcode;
wire    [6:0]   funct7;
wire    [2:0]   funct3;

assign opcode = in_inst[6:0];
assign funct3 = in_inst[14:12];
assign funct7 = in_inst[31:25];

assign src1 = in_inst[19:15];
assign src2 = in_inst[24:20];
assign idu_decode_src1 = src1;
assign idu_decode_src2 = src2;
assign src1_data = in_src1_data;
assign src2_data = in_src2_data;
assign rd   = in_inst[11:7];

assign immI = {{20{in_inst[31]}},in_inst[31:20]};
assign immU = {in_inst[31:12],{12{1'b0}}};
assign immS = {{20{in_inst[31]}},in_inst[31:25],in_inst[11:7]};
assign immB = {{20{in_inst[31]}}, in_inst[7], in_inst[30:25] ,in_inst[11:8] ,1'b0};
assign immJ = {{12{in_inst[31]}}, in_inst[19:12], in_inst[20], in_inst[30:21], 1'b0};//out_imm[20|10:1|11|19:12]
assign shamt = {{27{1'b0}}, in_inst[24:20]};
assign csr_addr = in_inst[31:20];

assign branch_op = funct3;
assign load_size = funct3;
assign store_size = funct3;
assign out_ready = in_ready;


reg             rf_we       ;
reg             csr_wen     ;
reg     [ 1:0]  wb_sel      ;
reg             csr_op_sel  ;
reg             is_ecall    ;
reg             is_mret     ;
reg             is_ebreak   ;
reg             is_jalr     ;
reg             is_jal      ;
reg             is_branch   ;
reg             is_load     ;
reg             is_store    ;
reg             trap_valid  ;
reg     [ 2:0]  branch_op   ;
reg     [ 2:0]  load_size   ;
reg     [ 2:0]  store_size  ;
reg     [ 1:0]  alu_src2_sel;
reg     [ 1:0]  alu_src1_sel;
reg     [ 3:0]  alu_op      ;
reg     [ 4:0]  src1        ;
reg     [ 4:0]  src2        ;
reg     [ 4:0]  rd          ;
reg     [31:0]  imm         ;
reg     [31:0]  shamt       ;
reg     [11:0]  csr_addr    ;
reg     [31:0]  src1_data   ;
reg     [31:0]  src2_data   ;

`ifdef VERILATOR
always @(posedge clk) begin
    if (out_valid && !in_ready) perf_event(PERF_IDU_STALL);
    if (out_valid && in_ready) begin
        if (out_is_jal || out_is_jalr) perf_event(PERF_JUMP);
    end
end
`endif

always @(posedge clk) begin
    if (reset == 1'b1) begin
        out_valid <= 1'b0;
    end
    else if (in_valid & out_ready) begin
        out_valid           <=  1'b1            ;
        out_rf_we           <=  rf_we           ;
        out_csr_wen         <=  csr_wen         ;
        out_wb_sel          <=  wb_sel          ;
        out_csr_op_sel      <=  csr_op_sel      ;
        out_is_ecall        <=  is_ecall        ;
        out_is_mret         <=  is_mret         ;
        out_is_ebreak       <=  is_ebreak       ;
        out_is_jalr         <=  is_jalr         ;
        out_is_jal          <=  is_jal          ;
        out_is_branch       <=  is_branch       ;
        out_is_load         <=  is_load         ;
        out_is_store        <=  is_store        ;
        out_trap_valid      <=  trap_valid      ;
        out_branch_op       <=  branch_op       ;
        out_load_size       <=  load_size       ;
        out_store_size      <=  store_size      ;
        out_alu_src2_sel    <=  alu_src2_sel    ;
        out_alu_src1_sel    <=  alu_src1_sel    ;
        out_alu_op          <=  alu_op          ;
        out_src1            <=  src1            ;
        out_src2            <=  src2            ;
        out_rd              <=  rd              ;
        out_imm             <=  imm             ;
        out_shamt           <=  shamt           ;
        out_csr_addr        <=  csr_addr        ;
        out_src1_data       <=  src1_data       ;
        out_src2_data       <=  src2_data       ;

    end
    else if (out_valid & in_ready) begin
        out_valid <= 1'b0;
    end
end


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
    is_ecall = 1'b0;
    is_mret = 1'b0;
    is_ebreak = 1'b0;
    alu_op = `NPC_ALU_ADD;
    csr_op_sel = `CSR_WRITE;
    alu_src1_sel = `NPC_RS1_DATA;
    alu_src2_sel = 0;
    is_jalr = 0;
    is_jal = 0;
    is_load = 0;
    is_store = 0;
    is_branch = 0;
    trap_valid = 0;
    csr_wen = 0;
    rf_we = 0;
    wb_sel = `NPC_ALU;
    if(in_valid && out_ready) begin
        if(opcode == 7'b0110011) begin
            rf_we = 1;
            wb_sel = `NPC_ALU;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_RS2_DATA;
            if(funct3 == 3'b000)begin
                if(funct7 == 7'b0000000) alu_op = `NPC_ALU_ADD;
                if(funct7 == 7'b0100000) alu_op = `NPC_ALU_SUB;
            end
            if(funct3 == 3'b001) alu_op = `NPC_ALU_SLL;
            if(funct3 == 3'b010) alu_op = `NPC_ALU_SLT;
            if(funct3 == 3'b011) alu_op = `NPC_ALU_SLTU;
            if(funct3 == 3'b100) alu_op = `NPC_ALU_XOR;
            if(funct3 == 3'b110) alu_op = `NPC_ALU_OR;
            if(funct3 == 3'b101) begin
                if(funct7 == 7'b0000000) alu_op = `NPC_ALU_SRL;
                if(funct7 == 7'b0100000) alu_op = `NPC_ALU_SRA;
            end
            if(funct3 == 3'b111) alu_op = `NPC_ALU_AND;
        end
        if(opcode == 7'b0010011) begin
            rf_we = 1;
            wb_sel = `NPC_ALU;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            if (funct3 == 3'b000) alu_op = `NPC_ALU_ADD; //addi
            if (funct3 == 3'b001) alu_op = `NPC_ALU_SLL; //slli
            if (funct3 == 3'b010) alu_op = `NPC_ALU_SLT;
            if (funct3 == 3'b011) alu_op = `NPC_ALU_SLTU; //sltiu
            if (funct3 == 3'b100) alu_op = `NPC_ALU_XOR;//xori
            if (funct3 == 3'b110) alu_op = `NPC_ALU_OR;//ori
            if (funct3 == 3'b101) begin
                alu_src2_sel = `NPC_SHAMT;
                if(funct7 == 7'b0000000) alu_op = `NPC_ALU_SRL;//srli
                if(funct7 == 7'b0100000) alu_op = `NPC_ALU_SRA;//srai
            end
            if(funct3 == 3'b111) alu_op = `NPC_ALU_AND;
        end
        if(opcode == 7'b1101111)begin // jal
            rf_we = 1;
            wb_sel = `NPC_PC4;
            alu_src1_sel = `NPC_CUR_PC;
            alu_src2_sel = `NPC_IMM;
            alu_op = `NPC_ALU_ADD;
            is_jal = 1;
        end
        if(opcode == 7'b1100111 && funct3 == 3'b000) begin//jalr
            rf_we = 1;
            wb_sel = `NPC_PC4;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            alu_op = `NPC_ALU_ADD;
            is_jalr = 1;
        end
        if (opcode == 7'b1100011) begin // branch
            rf_we = 0;
            alu_src1_sel = `NPC_CUR_PC;
            alu_src2_sel = `NPC_IMM;
            is_branch = 1;
        end

        if(opcode == 7'b0110111) begin//lui
            rf_we = 1;
            wb_sel = `NPC_ALU;
            alu_src1_sel = `NPC_ZERO;
            alu_src2_sel = `NPC_IMM;
            alu_op = `NPC_ALU_ADD;
        end
        if(opcode == 7'b0010111) begin //auipc
            rf_we = 1;
            wb_sel = `NPC_ALU;
            alu_src1_sel = `NPC_CUR_PC;
            alu_src2_sel = `NPC_IMM;
            alu_op = `NPC_ALU_ADD;
        end
        if (opcode == 7'b0000011) begin// lb/lh/lw/lbu/lhu
            rf_we = 1;
            wb_sel = `NPC_MEM;
            if(in_valid == 1'b1)begin
                is_load = 1'b1;
            end
            else is_load = 1'b0;
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            alu_op = `NPC_ALU_ADD;
        end
        if (opcode == 7'b0100011) begin // sb/sh/sw
            alu_src1_sel = `NPC_RS1_DATA;
            alu_src2_sel = `NPC_IMM;
            alu_op = `NPC_ALU_ADD;
            is_store = 1;
        end
        
        if(in_inst == 32'b0000_0000_0000_0000_0000_0000_0111_0011) begin
            is_ecall = 1'b1;
            trap_valid = 1;
        end
        if(in_inst == 32'b0000_0000_0001_0000_0000_0000_0111_0011) begin
            is_ebreak = 1'b1;
        end
        if(in_inst == 32'b0011_0000_0010_0000_0000_0000_0111_0011) begin
            is_mret = 1'b1;
            trap_valid = 1;
        end
        if(opcode == 7'b1110011) begin//priortiy
            if(funct3 == 3'b001)begin //CSRRW
                if(rd != 0) rf_we = 1;
                wb_sel = `NPC_CSR;
                csr_wen = 1;
                csr_op_sel = `CSR_WRITE;
            end
            if(funct3 == 3'b010)begin //CSRRS
                csr_wen = 1;
                if(rd != 0) rf_we = 1;
                wb_sel = `NPC_CSR;
                if(src1 == 0) csr_wen = 0;
                csr_op_sel = `CSR_SET;
            end
        end
    end

end

endmodule

