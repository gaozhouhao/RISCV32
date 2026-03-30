module MEM(
    input                               clk,

    output      reg                     ifu_respValid,
    input       reg                     ifu_reqValid,
    input               [31:0]          ifu_raddr,
    output      reg     [31:0]          ifu_rdata,
    
    output      reg                     lsu_respValid,
    input       reg                     lsu_reqValid,
    input               [31:0]          lsu_addr,
    input                               lsu_wen,
    input               [31:0]          lsu_wdata,
    input               [ 3:0]          lsu_wmask,
    output      reg     [31:0]          lsu_rdata
);

import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
import "DPI-C" function void pmem_write (
    input int unsigned  waddr, input int unsigned wdata, input byte wmask
);


parameter IDLE = 2'b00, WAIT = 2'b01, RESP = 2'b10;
reg [7:0] busy1;
reg [1:0] state1, next_state1;
always @(posedge clk) begin
    if(ifu_reqValid == 1) busy1 <= 10;
    else busy1 <= busy1 - 1;
    state1 <= next_state1;
end

always @(*) begin
    case (state1) 
        IDLE: next_state1 = ifu_reqValid ? WAIT : IDLE;
        WAIT: next_state1 = (busy1 == 1) ? RESP : WAIT;
        RESP: next_state1 = IDLE;
        default:;
    endcase
end

always @(posedge clk) begin
    ifu_rdata <= (state1==RESP) ? pmem_read(ifu_raddr) : 32'b0;
    ifu_respValid <= (state1==RESP);
end
//////////////////////////////////////////////
reg [7:0] busy2;
reg [1:0] state2, next_state2;
always @(posedge clk)  begin
    if(state2 == IDLE) busy2 <= 5;
    else busy2 <= busy2 - 1;
    state2 <= next_state2;
end
always @(*) begin
    next_state2 = (busy2 == 20) ? IDLE : WAIT;
end
always @(posedge clk) begin
    lsu_rdata <= (next_state2 == IDLE && !lsu_wen)? pmem_read(lsu_addr) : 32'b0;
    if(state2 == IDLE && lsu_wen) begin
        pmem_write(lsu_addr, lsu_wdata, {4'b0, lsu_wmask});
    end 

    lsu_respValid <= (state2 == IDLE);
end

endmodule

