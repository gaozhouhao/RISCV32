`ifndef NPC_PARAMS_VH
`define NPC_PARAMS_VH

`ifndef ARCH_NPC
`ifndef ARCH_YSYXSOC
    `define ARCH_YSYXSOC
`endif
`endif

// RESET_PC
`ifndef RESET_PC
    `ifdef ARCH_NPC
        `define RESET_PC 32'h8000_0000
    `elsif ARCH_YSYXSOC
        `define RESET_PC 32'h3000_0000
    `endif
`endif

// Global width
`define NPC_XLEN 32

// Memory map
//`define NPC_PMEM_BASE 32'h8000_0000
//`define NPC_PMEM_SIZE 32'h0800_0000  // example 128MB

// Next PC source
`define PCSEL_JALR  3'd0   // 
`define PCSEL_JAL   3'd1   // PC + imm_b (B-type)
`define PCSEL_PC4   3'd2   // PC + imm_j (J-type)
`define PCSEL_BR    3'd3   // (rs1 + imm_i) & ~1
`define PCSEL_MTVEC 3'd4
`define PCSEL_MEPC  3'd5
`define PCSEL_C_PC  3'd6   //current PC

// RD write back source/ Next PC source
`define NPC_ALU         2'd0
`define NPC_MEM         2'd1
`define NPC_PC4         2'd2
`define NPC_CSR         2'd3

// CSR write back source
`define CSR_SOURCE_REG         1'd0
`define CSR_SOURCE_IMM         1'd1

// CSR operation
`define CSR_WRITE        1'd0
`define CSR_SET          1'd1

// ALU src1 date_source
`define NPC_RS1_DATA    2'd0//src_data
`define NPC_CUR_PC      2'd1//current pc
`define NPC_ZERO        2'd2
`define NPC_CSR         2'd3

//ALU src2 data_source
`define NPC_RS2_DATA    2'd0
`define NPC_IMM         2'd1
`define NPC_SHAMT       2'd2

// ALU ops
`define NPC_ALU_ADD   4'd0
`define NPC_ALU_SUB   4'd1
`define NPC_ALU_AND   4'd2
`define NPC_ALU_OR    4'd3
`define NPC_ALU_XOR   4'd4
`define NPC_ALU_SLL   4'd5
`define NPC_ALU_SRL   4'd6
`define NPC_ALU_SRA   4'd7
`define NPC_ALU_SLT   4'd8
`define NPC_ALU_SLTU  4'd9

// flags bit positions (alu_flags[3:0])
`define ALU_FLAG_ZERO      0
`define ALU_FLAG_NEGATIVE  1
`define ALU_FLAG_NOBORROW  2
`define ALU_FLAG_OVERFLOW  3



`define  UART_BASE   32'h1000_0000
`define  UART_END    32'h1000_0FFF

`define  SRAM_BASE   32'h8000_0000
`define  SRAM_END    32'h80ff_ffff

`ifdef ARCH_NPC

`define  CLINT_BASE  32'ha000_0000
`define  CLINT_END   32'ha000_02ff

`elsif ARCH_YSYXSOC

`define  CLINT_BASE  32'h0200_0000
`define  CLINT_END   32'h0200_02ff

`endif



`define PERF_IFU_FETCH 0
`define PERF_LSU_LOAD  1
`define PERF_LSU_STORE 2
`define PERF_EXU_DONE  3

`endif

