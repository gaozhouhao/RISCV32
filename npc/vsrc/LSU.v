`include "params.vh"

module LSU(
    input                               clk,
    input                               reset,
    input                               sen,
    input                               exu_we,
    output      reg                     lsu_rf_we,
    input       reg                     is_load,
    input       reg                     is_store,
    input       reg     [31:0]          pc,

    input               [ 1:0]          wb_sel, 
    input       reg     [ 2:0]          funct3,
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
    input       reg                     lsu_reqReady,
    input       reg                     lsu_respValid,
    output      reg                     lsu_respReady,
    input       reg     [31:0]          lsu_rdata,
    output      reg     [31:0]          lsu_addr,
    output      reg                     lsu_wen,
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
reg [ 1:0] lsu_wb_sel;
reg [31:0] lsu_alu_result;
always @(*) begin
    lsu_addr = 0;
    lsu_wen = 0;
    if(exu_to_lsu_valid) begin
        lsu_addr = alu_result;
        if(is_load == 1) lsu_wen = 0;
        else lsu_wen = 1;
    end
end

reg lsu_is_load, lsu_is_store;
always @(posedge clk) begin
    if(reset == 0) begin
        lsu_is_load <= 0;
        lsu_is_store <= 0;
        lsu_alu_result <= 0;
    end
    else if (exu_to_lsu_valid)begin
        lsu_is_load <= is_load;
        lsu_is_store  <= is_store;
        lsu_alu_result <= alu_result; 
    end
end

parameter IDLE = 2'b00, WAIT_READY = 2'b01, WAIT = 2'b10;
reg             lsu_is_valid;
reg     [1:0]   state, next_state;

always @(*) begin
    lsu_to_rf_valid = 0;
    lsu_rf_we = 0;
    lsu_reqValid = 0;
    lsu_wb_sel = 0;
    case (state)
        IDLE: begin
            if(is_load || is_store) begin
                next_state = WAIT;
                lsu_reqValid = 1;
            end
            else begin
                next_state = WAIT_READY;
                lsu_to_rf_valid = exu_to_lsu_valid;
                lsu_rf_we = exu_we;
                lsu_wb_sel = wb_sel;
            end
        end
        WAIT_READY: begin
           next_state = lsu_reqReady ? WAIT : WAIT_READY; 
        end
        WAIT: begin
            next_state = lsu_respValid? IDLE:WAIT;
            lsu_to_rf_valid = lsu_respValid;
            lsu_rf_we = lsu_is_load;
            if(lsu_is_load)lsu_wb_sel = `NPC_MEM;
        end
        default:;
    endcase
end

always @(posedge clk) begin
    if(reset == 0)
        state <= IDLE;
    else
        state <= next_state;
end

reg [7:0] byte1, byte2;
reg [31:0] word;
always @(*) begin
    byte1 = 8'b0;
    byte2 = 8'b0;
    word = 32'b0;
    csr_input_data = 32'b0;
    case (lsu_wb_sel)
        `NPC_ALU: wb = alu_result;
        `NPC_MEM: begin
            word = (lsu_rdata >> (lsu_alu_result[1:0]*8));
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
        `NPC_PC4: wb = pc + 32'h4;
        `NPC_CSR: begin
            wb = csr_output_data;
            if(csr_op_sel == `CSR_WRITE)csr_input_data = src1_data;
            if(csr_op_sel == `CSR_SET)csr_input_data = csr_output_data | src1_data;
        end
        default: wb = 32'b0;
    endcase
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

endmodule
