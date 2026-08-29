`include "params.vh"
module EXU (
    input                       clk,
    input                       reset,
    input   reg     [31:0]      pc,
    input   wire    [ 1:0]      in_wb_sel,
    input   wire    [ 1:0]      in_alu_src1_sel,
    input   reg     [ 1:0]      in_alu_src2_sel,
    input   reg     [ 3:0]      in_alu_op,
    input           [ 4:0]      in_src1,
    input           [ 4:0]      in_src2,
    input   reg                 in_rf_we,

    input   reg                 in_is_ebreak,
    input   reg                 in_is_load,
    input   reg                 in_is_store,
    input   reg                 in_is_branch,
    input   reg                 in_is_jalr,
    input   reg                 in_is_jal,
    input                       in_is_ecall,
    input                       in_is_mret,
    input   reg                 in_trap_valid,

    input                       in_csr_wen,
    input                       in_csr_op_sel,
    input           [11:0]      in_csr_addr,
    input   wire    [31:0]      in_src1_data,
    input   wire    [31:0]      in_src2_data,
    input   wire    [4:0]       in_rd,
    input   reg     [31:0]      in_imm,
    input           [31:0]      in_shamt,
    input   reg     [2:0]       in_branch_op,
    input   reg     [ 2:0]      in_load_size,
    input   reg     [ 2:0]      in_store_size,
    input                       in_valid,
    input                       in_ready,

    output  reg                 out_is_load,
    output  reg                 out_is_store,
    output          [ 2:0]      out_load_size,
    output          [ 2:0]      out_store_size,
    output  reg     [31:0]      out_wb_data,
    output  reg     [31:0]      out_store_data,
    output  reg     [31:0]      out_mem_addr,
    output                      out_redirect_valid,
    output  reg     [31:0]      out_redirect_pc,
    output                      out_rf_we,
    output          [ 4:0]      out_src1,
    output          [ 4:0]      out_src2,
    output          [ 4:0]      out_rd,
    output                      out_ready,
    output                      out_valid
);
import perf_pkg::*;
import "DPI-C" function void ebreak(input bit is_ebreak);

always @(posedge clk) begin
    if (out_valid && !in_ready) perf_event(PERF_EXU_STALL);
    if (out_valid && in_ready) begin
        if (in_is_branch && branch_taken) perf_event(PERF_BRANCH_TAKEN);
    end
end

reg     [31:0]      jalr_target;
reg     [31:0]      jal_target;
reg     [31:0]      trap_pc;
reg     [31:0]      branch_target;

always @(posedge clk) begin
        if (reset) begin
            out_valid <= 1'b0;
        end
        else begin
            if (in_valid & out_ready) begin
                perf_event(PERF_EXU_DONE);
                out_valid <= 1'b1;
                ebreak(in_is_ebreak);
                out_is_load         <= in_is_load       ;
                out_is_store        <= in_is_store      ;
                out_load_size       <= in_load_size     ;
                out_store_size      <= in_store_size    ;
                out_rf_we           <= in_rf_we         ;
                out_src1            <= in_src1          ;
                out_src2            <= in_src2          ;
                out_rd              <= in_rd            ;
                out_mem_addr        <= alu_result       ;
                out_store_data      <= store_data       ;
                out_wb_data         <= wb_data          ;

                out_redirect_valid  <= redirect_valid;
                out_redirect_pc     <= redirect_pc;
            end
            else if (out_valid & in_ready) begin
                out_valid <= 1'b0;
            end
        end
    end


wire    [31:0]  redirect_pc;
wire            redirect_valid;
reg     [31:0]  wb_data;
wire    [31:0]  store_data;
wire    [31:0]  alu_result;
reg             branch_taken;
reg     [31:0]  alu_src1;
reg     [31:0]  alu_src2;
reg     [ 3:0]  alu_flags;

always @(*) begin
    alu_src1 = in_src1_data;
    alu_src2 = in_src2_data;

    case (in_alu_src1_sel)
        `NPC_RS1_DATA: alu_src1 = in_src1_data;
        `NPC_CUR_PC:  alu_src1 = pc;
        `NPC_ZERO:  alu_src1 = 32'b0;
        default:;
    endcase
    
    case (in_alu_src2_sel)
        `NPC_RS2_DATA:    alu_src2 = in_src2_data;
        `NPC_IMM:   alu_src2 = in_imm;
        `NPC_SHAMT: alu_src2 = in_shamt;
        default:;
    endcase
end

ALU alu(
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .alu_src1_sel(in_alu_src1_sel),
    .alu_src2_sel(in_alu_src2_sel),
    .alu_op(in_alu_op),
    .src1_data(in_src1_data),
    .src2_data(in_src2_data),
    .alu_result(alu_result),
    .alu_flags(alu_flags)
);

assign out_ready = in_ready;
assign store_data = in_is_store ? in_src2_data : 32'b0;

import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
import "DPI-C" function void pmem_write(
    input int unsigned waddr, input int unsigned wdata, input byte wmask);

always @(*) begin
    case (in_branch_op)
        3'b000: branch_taken = alu_flags[`ALU_FLAG_ZERO];//beq
        3'b001: branch_taken = ~alu_flags[`ALU_FLAG_ZERO];//bne
        3'b100: branch_taken = alu_flags[`ALU_FLAG_NEGATIVE] ^ alu_flags[`ALU_FLAG_OVERFLOW];//blt
        3'b101: branch_taken = ~(alu_flags[`ALU_FLAG_NEGATIVE] ^ alu_flags[`ALU_FLAG_OVERFLOW]);//bge
        3'b110: branch_taken = ~alu_flags[`ALU_FLAG_NOBORROW];//bltu
        3'b111: branch_taken = alu_flags[`ALU_FLAG_NOBORROW];//bgeu
        default:branch_taken = 0;
    endcase
end

always @(*) begin
    case (in_wb_sel)
        `NPC_ALU: wb_data = alu_result;
        `NPC_PC4: wb_data = pc + 32'h4;
        `NPC_CSR: wb_data = csr_rdata;
        `NPC_MEM: wb_data = 32'b0;
    endcase
end

assign redirect_valid =
           in_is_jal
        |  in_is_jalr
        | (in_is_branch && branch_taken)
        | in_trap_valid;


assign redirect_pc =
        in_trap_valid              ? trap_pc       :
        in_is_jal                  ? jal_target    :
        in_is_jalr                 ? jalr_target   :
        (in_is_branch & branch_taken)    ? branch_target :
                                  32'b0;

wire [31:0] mtvec_data, mepc_data;
always @(*) begin
    jal_target = 0;
    jalr_target = 0;
    branch_target = 0; 
    trap_pc = 0;
    if(in_is_jal)
        jal_target = in_imm + pc;
    if(in_is_jalr)
        jalr_target = (in_imm + in_src1_data) & ~1;
    if(in_is_branch)
        branch_target = in_imm + pc;
    if(in_is_ecall)
        trap_pc = mtvec_data;
    if(in_is_mret)
        trap_pc = mepc_data;
end

wire    [31:0]  csr_rdata;
wire    [31:0]  csr_wdata = (in_csr_op_sel == `CSR_WRITE) ? in_src1_data : (csr_rdata | in_src1_data);
CSR csr(
    .clk(clk),
    .pc(pc),
    .csr_addr(in_csr_addr),
    .csr_wen(in_csr_wen && in_valid && out_ready),
    .is_ecall(in_is_ecall && in_valid && out_ready),
    .csr_rdata(csr_rdata),
    .csr_wdata(csr_wdata),
    .mtvec_data(mtvec_data),
    .mepc_data(mepc_data)
);


endmodule
