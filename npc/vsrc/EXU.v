module EXU (
    input                       clk,
    input   wire    [1:0]       nextpc_sel, 
    input   wire    [1:0]       wb_sel,
    input   wire    [1:0]       alu_src1_sel,
    input   reg                 ALUSrc,
    input   reg     [2:0]       ALUop,
    input   reg                 is_ebreak,
        
    input   reg     [31:0]      pc,
    input   wire    [31:0]      src1_data,
    input   wire    [31:0]      src2_data,
    input   wire    [4:0]       rd,
    input   reg     [31:0]      imm,

    input   reg     [2:0]       funct3,
    input                       sen,

    output  reg     [31:0]      wb,
    output  reg     [31:0]      next_pc
);

reg    [31:0]  alu_src1;
reg    [31:0]  alu_src2;
reg    [31:0]  alu_result;

reg    [7:0]   wmask;

import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
import "DPI-C" function void pmem_write(
    input int unsigned waddr, input int unsigned wdata, input byte wmask);

localparam [1:0]
    src_ALU = 2'b00,
    src_MEM = 2'b01,
    src_PC4 = 2'b10,
    src_No  = 2'b11;

localparam [1:0]
    src_data = 2'b00,
    cur_pc   = 2'b01,
    src_zero = 2'b10;

always @(*) begin
    case (ALUop)
        3'b001: alu_result = alu_src1 + alu_src2;
        default:alu_result = 32'b0;
    endcase
end

always @(*) begin
    case (alu_src1_sel)
        default: alu_src1 = src1_data;
        cur_pc:  alu_src1 = pc;
        src_zero:alu_src1 = 32'b0;
    endcase
    
    alu_src2 = ALUSrc?imm:src2_data;
end

always @(*) begin
    case (wb_sel)
        src_ALU: wb = alu_result;
        src_PC4: wb = pc + 32'h4;
        src_MEM: case (funct3)
            3'b010: wb = pmem_read(alu_result);
            3'b100: wb = (pmem_read(alu_result) >> (alu_result[1:0]*8)) & 32'hff;
            default:wb = 32'b0;
        endcase
        default: wb = 32'b0;
    endcase
    case (nextpc_sel)
        src_ALU: next_pc = alu_result;
        src_PC4: next_pc = pc + 32'h4;
        default: next_pc = 32'b0;
    endcase
end

reg    [31:0]  store_data;
always @(*) begin
    store_data = src2_data;
    case (funct3)
        3'b010: wmask = 8'h0f;
        3'b000: begin
            store_data = {4{src2_data[7:0]}};
            case (alu_result[1:0])
                2'b00:  wmask = 8'h01;
                2'b01:  wmask = 8'h02;
                2'b10:  wmask = 8'h04;
                2'b11:  wmask = 8'h08;
            endcase
        end
        default: begin
            wmask = 8'b0;
            store_data = src2_data;
        end
    endcase
end


always @(posedge clk) begin
    if (sen == 1'b1) begin
        pmem_write(alu_result, store_data, wmask);
    end
end


import "DPI-C" function void ebreak(input bit is_ebreak);

always @(posedge clk) begin
    ebreak(is_ebreak);
end


endmodule
