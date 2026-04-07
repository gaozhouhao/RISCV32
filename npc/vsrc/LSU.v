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
    output                              lsu_to_rf_valid,

    input       reg     [31:0]          redirect_pc,
    input       reg                     redirect_valid,
    output      reg     [31:0]          redirect_pc_r,
    output      reg                     redirect_valid_r
);

import "DPI-C" function int unsigned pmem_read(input int unsigned  raddr);
import "DPI-C" function void pmem_write(
    input int unsigned waddr, input int unsigned wdata, input byte wmask);

reg     [7:0]   random_num;
LFSR lfsr(
    .clk(clk),
    .random_num(random_num)
);

assign exu_to_lsu_ready = 1'b1;
reg [ 1:0] lsu_wb_sel;
reg [31:0] lsu_alu_result;

reg exu_to_lsu_valid_r;
reg lsu_is_load, lsu_is_store;
always @(posedge clk) begin
    exu_to_lsu_valid_r <= exu_to_lsu_valid;
    if(reset == 0) begin
        lsu_is_load <= 0;
        lsu_is_store <= 0;
        lsu_alu_result <= 0;
        lsu_addr <= 0;
        lsu_wen <= 0;
        lsu_wb_sel <= 0;
        lsu_rf_we <= 0;
        redirect_pc_r <= 0;
        redirect_valid_r <= 0;
    end
    else if (exu_to_lsu_valid)begin
        lsu_is_load <= is_load;
        lsu_is_store  <= is_store;
        lsu_alu_result <= alu_result; 
        lsu_addr <= alu_result;
        if(is_load == 1) lsu_wen <= 0;
        else lsu_wen <= 1;
        lsu_wb_sel <= wb_sel;
        lsu_rf_we <= exu_we | is_load;
        redirect_pc_r <= redirect_pc;
        redirect_valid_r <= redirect_valid;
    end
end

reg [7:0]   resp_busy;
parameter IDLE = 2'b00, WAIT_READY = 2'b01, WAIT = 2'b10, BUSY = 2'b11;
reg             lsu_is_valid;
reg     [1:0]   state, next_state;

always @(*) begin
    lsu_to_rf_valid = 0;
    lsu_reqValid = 0;
    case (state)
        IDLE: begin
            if(lsu_is_load || lsu_is_store) begin
                next_state = WAIT_READY;
                lsu_reqValid = 1;
            end
            else begin
                next_state = IDLE;
                lsu_to_rf_valid = exu_to_lsu_valid_r;
            end
        end
        WAIT_READY: begin
            next_state = lsu_reqReady ? WAIT : WAIT_READY; 
            lsu_reqValid = 1;
        end
        WAIT: begin
            next_state = lsu_respValid ? BUSY:WAIT;
        end
        BUSY: begin
            next_state = (resp_busy == 1) ? IDLE : BUSY;
            //lsu_rf_we = lsu_is_load;
            lsu_to_rf_valid = lsu_respReady;

        end
        default:;
    endcase
end

always @(posedge clk) begin
    if(lsu_respValid && state == WAIT)
        resp_busy <= random_num + 2;
    if(resp_busy > 0)
        resp_busy <= resp_busy - 1;
    lsu_respReady <= (resp_busy == 1 && lsu_respValid);


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
    if(lsu_is_load) begin
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
    else case (lsu_wb_sel)
        `NPC_ALU: wb = lsu_alu_result;
        `NPC_PC4: wb = pc + 32'h4;
        `NPC_CSR: begin
            wb = csr_output_data;
            if(csr_op_sel == `CSR_WRITE)csr_input_data = src1_data;
            if(csr_op_sel == `CSR_SET)csr_input_data = csr_output_data | src1_data;
        end
        default: wb = 32'b0;
    endcase
end

always @(posedge clk) begin
    if(exu_to_lsu_valid)
    case (funct3)
        3'b000: begin //sb
            lsu_wdata <= {4{src2_data[7:0]}};
            lsu_wmask <= 4'h01 << alu_result[1:0];
        end
        3'b001: begin //sh
            lsu_wdata <= {16'b0, src2_data[15:0]} << (alu_result[1:0] * 8);
            lsu_wmask <= 4'h03 << alu_result[1:0];
        end
        3'b010: begin
            lsu_wdata <= src2_data;
            lsu_wmask <= 4'h0f;//sw
        end
        default: begin
            lsu_wmask <= 4'b0;
            lsu_wdata <= src2_data;
        end
    endcase
end

endmodule
