`include "params.vh"
module EXU (
    input                       clk,
    input   wire    [1:0]       wb_sel,
    input   wire    [1:0]       alu_src1_sel,
    input   reg     [ 1:0]       alu_src2_sel,
    input   reg     [ 3:0]      ALUop,
    output          [31:0]      alu_result,
    input   reg                 idu_we,
    output                      exu_we,
    input                       sen,

    output  reg                 branch_taken,

    input   reg                 is_ebreak,
    input   reg                 is_load,
    input   reg                 is_store,
    input   reg                 is_branch,
    input   reg                 is_jalr,
    input   reg                 is_jal,

    input   reg                 trap_valid,

    input                       is_csr,
    input                       csr_wen,
    input                       csr_op_sel,
    input           [11:0]      csr_addr,
    input                       is_ecall,
    input                       is_mret,
    //input           [31:0]      csr_rdata,
    output          [31:0]      csr_wdata,

    input   reg     [31:0]      pc,
    input   wire    [31:0]      src1_data,
    input   wire    [31:0]      src2_data,
    input   wire    [4:0]       rd,
    input   reg     [31:0]      imm,
    input           [31:0]      shamt,
    input   reg     [2:0]       funct3,
    output  reg     [31:0]      wb,
    
    //input   wire    [31:0]      mtvec_data,
    //input   wire    [31:0]      mepc_data,
    output                      redirect_valid,
    output  reg     [31:0]      redirect_pc,

    input                       idu_to_exu_valid,
    output                      idu_to_exu_ready,
    input                       exu_to_lsu_ready,
    output                      exu_to_lsu_valid
);


ALU alu(
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .alu_src1_sel(alu_src1_sel),
    .alu_src2_sel(alu_src2_sel),
    .ALUop(ALUop),
    .src1_data(src1_data),
    .src2_data(src2_data),
    .alu_result(alu_result),
    .alu_flags(alu_flags)
);

reg     [31:0]  alu_src1;
reg     [31:0]  alu_src2;
reg     [3:0]   alu_flags;
reg     [7:0]   wmask;

assign exu_we = idu_we;

import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
import "DPI-C" function void pmem_write(
    input int unsigned waddr, input int unsigned wdata, input byte wmask);

always @(*) begin
    case (funct3)
        3'b000: branch_taken = alu_flags[`ALU_FLAG_ZERO];//beq
        3'b001: branch_taken = ~alu_flags[`ALU_FLAG_ZERO];//bne
        3'b100: branch_taken = alu_flags[`ALU_FLAG_NEGATIVE] ^ alu_flags[`ALU_FLAG_OVERFLOW];//blt
        3'b101: branch_taken = ~(alu_flags[`ALU_FLAG_NEGATIVE] ^ alu_flags[`ALU_FLAG_OVERFLOW]);//bge
        3'b110: branch_taken = ~alu_flags[`ALU_FLAG_NOBORROW];//bltu
        3'b111: branch_taken = alu_flags[`ALU_FLAG_NOBORROW];//bgeu
        default:branch_taken = 0;
    endcase
end

assign redirect_valid =
           is_jal
        |  is_jalr
        | (is_branch && branch_taken)
        | trap_valid;

reg     [31:0]      jalr_target;
reg     [31:0]      jal_target;
reg     [31:0]      trap_pc;
reg     [31:0]      branch_target;
assign redirect_pc =
        trap_valid              ? trap_pc       :
        is_jal                  ? jal_target    :
        is_jalr                 ? jalr_target   :
        (is_branch && branch_taken)    ? branch_target :
                                  32'b0;

wire [31:0] mtvec_data, mepc_data;
always @(*) begin
    jal_target = 0;
    jalr_target = 0;
    branch_target = 0; 
    trap_pc = 0;
    if(is_jal)
        jal_target = imm + pc;
    if(is_jalr)
        jalr_target = (imm + src1_data) & ~1;
    if(is_branch)
        branch_target = imm + pc;
    if(is_ecall)
        trap_pc = mtvec_data;
    if(is_mret)
        trap_pc = mepc_data;
end



always @(*) begin
    alu_src1 = src1_data;
    alu_src2 = src2_data;

    case (alu_src1_sel)
        `NPC_RS1_DATA: alu_src1 = src1_data;
        `NPC_CUR_PC:  alu_src1 = pc;
        `NPC_ZERO:  alu_src1 = 32'b0;
        default:;
    endcase
    
    case (alu_src2_sel)
        `NPC_RS2_DATA:    alu_src2 = src2_data;
        `NPC_IMM:   alu_src2 = imm;
        `NPC_SHAMT: alu_src2 = shamt;
        default:;
    endcase
end

always @(*) begin
    exu_to_lsu_valid = idu_to_exu_valid;
end


import "DPI-C" function void ebreak(input bit is_ebreak);

reg    [31:0]  store_data;
always @(posedge clk) begin
    if(idu_to_exu_valid == 1'b1) begin

        //else lsu_wen <= 1'b0;
        ebreak(is_ebreak);
        //exu_to_wbu_valid = 1'b1;
        //exu_to_lsu_valid = 1'b1;
    end
    else begin
        //exu_to_wbu_valid = 1'b0;
        //exu_to_lsu_valid = 1'b0;
    end
end


wire    [31:0] csr_rdata;
assign csr_wdata = (csr_op_sel == `CSR_WRITE) ? src1_data : (csr_rdata | src1_data);

CSR csr(
    .clk(clk),
    .pc(pc),
    .csr_addr(csr_addr),
    .csr_wen(csr_wen),
    .is_ecall(is_ecall),
    .csr_rdata(csr_rdata),
    .csr_wdata(csr_wdata),
    .mtvec_data(mtvec_data),
    .mepc_data(mepc_data)
);




endmodule
