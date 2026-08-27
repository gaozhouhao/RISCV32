module IDU_EXU_Reg (

    input                       clk,
    input                       reset,
    input                       in_valid,

    input   reg                 in_rf_we,
    input   reg                 in_csr_wen,
    input   reg     [ 1:0]      in_wb_sel,
    input   reg                 in_csr_op_sel,

    input   reg                 in_is_ecall,
    input   reg                 in_is_mret,
    input   reg                 in_is_ebreak,
    input   reg                 in_is_jalr,
    input   reg                 in_is_jal,
    input   reg                 in_is_branch,
    input   reg                 in_is_load,
    input   reg                 in_is_store,
    input   reg                 in_trap_valid,

    input           [ 2:0]      in_branch_op,
    input   reg     [ 3:0]      in_alu_op,
    input   reg     [ 1:0]      in_alu_src2_sel,
    input   reg     [ 1:0]      in_alu_src1_sel,
    input           [ 4:0]      in_src1,
    input           [ 4:0]      in_src2,
    input           [ 4:0]      in_rd,
    input           [31:0]      in_imm,
    input           [31:0]      in_shamt,
    input           [11:0]      in_csr_addr,
    input           [31:0]      in_src1_data,
    input           [31:0]      in_src2_data,

    output                      out_valid,
    
    output  reg                 out_rf_we,
    output  reg                 out_csr_wen,
    output  reg     [ 1:0]      out_wb_sel,
    output  reg                 out_csr_op_sel,
    
    output  reg                 out_is_ecall,
    output  reg                 out_is_mret,
    output  reg                 out_is_ebreak,
    output  reg                 out_is_jalr,
    output  reg                 out_is_jal,
    output  reg                 out_is_branch,
    output  reg                 out_is_load,
    output  reg                 out_is_store,
    output  reg                 out_trap_valid,

    output          [ 2:0]      out_branch_op,
    output  reg     [ 3:0]      out_alu_op,

    output  reg     [ 1:0]      out_alu_src2_sel,
    output  reg     [ 1:0]      out_alu_src1_sel,
    output          [ 4:0]      out_src1,
    output          [ 4:0]      out_src2,
    output          [ 4:0]      out_rd,
    output          [31:0]      out_imm,
    output          [31:0]      out_shamt,
    output          [11:0]      out_csr_addr,
    output          [31:0]      out_src1_data,
    output          [31:0]      out_src2_data
);

    always @(posedge clk) begin
        if (reset) begin
            out_valid           <= 1'b0     ;
            out_rf_we           <= 1'b0     ;
            out_csr_wen         <= 1'b0     ;
            out_wb_sel          <= 2'b0     ;
            out_csr_op_sel      <= 1'b0     ;
            out_is_ecall        <= 1'b0     ;
            out_is_mret         <= 1'b0     ;
            out_is_ebreak       <= 1'b0     ;
            out_is_jalr         <= 1'b0     ;
            out_is_jal          <= 1'b0     ;
            out_is_branch       <= 1'b0     ;
            out_is_load         <= 1'b0     ;
            out_is_store        <= 1'b0     ;
            out_trap_valid      <= 1'b0     ;
            out_branch_op       <= 3'b0     ;
            out_alu_op          <= 4'b0     ;
            out_alu_src2_sel    <= 2'b0     ;
            out_alu_src1_sel    <= 2'b0     ;
            out_src1            <= 5'b0     ;
            out_src2            <= 5'b0     ;
            out_rd              <= 5'b0     ;
            out_imm             <= 32'b0    ;
            out_shamt           <= 32'b0    ;
            out_csr_addr        <= 12'b0    ;
            out_src1_data       <= 32'b0    ;
            out_src2_data       <= 32'b0    ;
        end

        else begin
            out_valid           <= in_valid         ;
            out_rf_we           <= in_rf_we         ;
            out_csr_wen         <= in_csr_wen       ;
            out_wb_sel          <= in_wb_sel        ;
            out_csr_op_sel      <= in_csr_op_sel    ;
            out_is_ecall        <= in_is_ecall      ;
            out_is_mret         <= in_is_mret       ;
            out_is_ebreak       <= in_is_ebreak     ;
            out_is_jalr         <= in_is_jalr       ;
            out_is_jal          <= in_is_jal        ;
            out_is_branch       <= in_is_branch     ;
            out_is_load         <= in_is_load       ;
            out_is_store        <= in_is_store      ;
            out_trap_valid      <= in_trap_valid    ;
            out_branch_op       <= in_branch_op     ;
            out_alu_op          <= in_alu_op        ;
            out_alu_src2_sel    <= in_alu_src2_sel  ;
            out_alu_src1_sel    <= in_alu_src1_sel  ;
            out_src1            <= in_src1          ;
            out_src2            <= in_src2          ;
            out_rd              <= in_rd            ;
            out_imm             <= in_imm           ;
            out_shamt           <= in_shamt         ;
            out_csr_addr        <= in_csr_addr      ;
            out_src1_data       <= in_src1_data     ;
            out_src2_data       <= in_src2_data     ;
        end
    end


endmodule
