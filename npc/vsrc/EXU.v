`include "params.vh"
module EXU (
    input                       clk,
    input   wire    [2:0]       nextpc_sel, 
    input   wire    [1:0]       wb_sel,
    input   wire    [1:0]       alu_src1_sel,
    input   reg     [ 1:0]       alu_src2_sel,
    input   reg     [ 3:0]      ALUop,
    output          [31:0]      alu_result,
    output  reg     [31:0]      next_pc,
/*
    output  reg     [31:0]      jalr_target,
    output  reg     [31:0]      jal_target,
    output  reg     [31:0]      branch_target,
    */
    input                       sen,

    output  reg                 branch_taken,

    input                       csr_op_sel,
    input   reg                 is_ebreak,
    input   reg                 is_csr,
    input   reg                 is_load,
    input   reg                 is_store,
        
    input   reg     [31:0]      pc,
    input   wire    [31:0]      src1_data,
    input   wire    [31:0]      src2_data,
    input   wire    [4:0]       rd,
    input   reg     [31:0]      imm,
    input           [31:0]      shamt,
    input   reg     [2:0]       funct3,
    output  reg     [31:0]      wb,
    
    input   wire    [31:0]      mtvec_data,
    input   wire    [31:0]      mepc_data,
    output  reg     [31:0]      csr_input_data,
    output  reg     [31:0]      csr_output_data,

    //output  reg     [31:0]      next_pc,
    input                       idu_to_exu_valid,
    output                      idu_to_exu_ready,
    output                      exu_to_rf_valid,
    input                       exu_to_rf_ready,
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
    exu_to_lsu_valid = idu_to_exu_valid && (is_load || is_store);
    exu_to_rf_valid = idu_to_exu_valid && (!is_load && !is_store);
end

/*
reg [7:0] byte1, byte2;
reg [31:0] word;
always @(*) begin
    byte1 = 8'b0;
    byte2 = 8'b0;
    next_pc = 32'b0;
    word = 32'b0;
    csr_input_data = 32'b0;
    case (wb_sel)
        `NPC_ALU: wb = alu_result;
        `NPC_PC4: wb = pc + 32'h4;
        `NPC_MEM: begin
            word = (pmem_read(alu_result) >> (alu_result[1:0]*8));
            //word = (lsu_rdata >> (alu_result[1:0]*8));
            case (funct3)
            3'b000: begin
                byte1 = word[7:0];
                wb = {{24{byte1[7]}}, byte1}; //lb
            end
            3'b001: begin//lh
                 {byte2, byte1} = word[15:0];
                 wb = {{16{byte2[7]}}, byte2, byte1};
            end
            3'b010: wb = word; //lw
            3'b100: wb = word & 32'hff;//lbu
            3'b101: wb = word & 32'hffff; //lhu
            default:wb = 32'b0;
        endcase
        end
        `NPC_CSR: begin
            wb = csr_output_data;
            if(csr_op_sel == `CSR_WRITE)csr_input_data = src1_data;
            if(csr_op_sel == `CSR_SET)csr_input_data = csr_output_data | src1_data;
        end
        default: wb = 32'b0;
    endcase
        case (nextpc_sel)
            `PCSEL_JALR: next_pc = alu_result;
            `PCSEL_JAL: next_pc = alu_result;
            `PCSEL_PC4: next_pc = pc + 32'd4;
            `PCSEL_BR:  next_pc = branch_taken?alu_result:(pc + 32'd4);
            `PCSEL_MTVEC:  next_pc = mtvec_data;
            `PCSEL_MEPC:  next_pc = mepc_data;
            default: ;
        endcase
end
*/

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

endmodule
