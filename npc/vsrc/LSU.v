`include "params.vh"

module LSU(
    input                               clk,
    input                               sen,
    input       reg                     is_load,
    input       reg                     is_store,
    input       reg     [31:0]          pc,

    input               [ 1:0]          wb_sel, 
    input       reg     [ 2:0]          funct3,
    input       wire    [ 2:0]          nextpc_sel,
    output      reg     [31:0]          next_pc,
    input       reg                     branch_taken,
    
    input               [31:0]          alu_result,
    input       wire    [31:0]          src1_data,
    input       wire    [31:0]          src2_data,

    input                               csr_op_sel,
    output      reg     [31:0]          csr_input_data,
    output      reg     [31:0]          csr_output_data,
    input       wire    [31:0]          mtvec_data,
    input       wire    [31:0]          mepc_data,

    output      reg     [31:0]          wb,

    output      reg                     lsu_reqValid,
    input       reg                     lsu_respValid,
    input       reg     [31:0]          lsu_rdata,
    output      reg     [31:0]          lsu_addr,
    output                              lsu_wen,
    output      reg     [31:0]          lsu_wdata,
    output      reg     [ 3:0]          lsu_wmask,
    
    output                              exu_to_lsu_valid,
    output                              exu_to_lsu_ready,
    input                               lsu_to_rf_ready,
    output                              lsu_to_rf_valid
);

import "DPI-C" function int unsigned pmem_read(input int unsigned  raddr);
import "DPI-C" function void pmem_write(
    input int unsigned waddr, input int unsigned wdata, input byte wmask);

assign exu_to_lsu_ready = 1'b1;

parameter IDLE = 1'b0, WAIT = 1'b1;
reg lsu_is_valid;
reg state, next_state;

always @(*) begin
    lsu_to_rf_valid = lsu_respValid;
    lsu_reqValid = 0;
    case (state)
        IDLE: begin
            if(exu_to_lsu_valid) begin
                next_state = WAIT;
                lsu_reqValid = 1;
                if(is_load) lsu_wen = 0;
                else lsu_wen = 1;
            end
            else begin
                next_state = IDLE;
                //lsu_to_rf_valid = 0;
            end
        end
        WAIT: begin
            next_state = lsu_respValid? IDLE:WAIT;
        end
        default:;
    endcase
end

always @(posedge clk) begin
    state <= next_state;
end

always @(*) begin
    case (funct3)
        3'b000: begin //sb
            lsu_wdata = {4{src2_data[7:0]}};
            lsu_wmask = 4'h01 << alu_result[1:0];
        end
        3'b001: begin //sh
            lsu_wdata = {16'b0, src2_data[15:0]} << (alu_result[1:0] * 8);
            lsu_wmask = 4'h03 << alu_result[1:0];
        end
        3'b010: begin
            lsu_wdata = src2_data;
            lsu_wmask = 4'h0f;//sw
        end
        default: begin
            lsu_wmask = 4'b0;
            lsu_wdata = src2_data;
        end
    endcase
end

always @(*) begin
    lsu_addr = alu_result;
    lsu_wen = sen;
end


endmodule
