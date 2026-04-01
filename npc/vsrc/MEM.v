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

reg     [31:0]  mem_ifu_raddr;
reg     [31:0]  mem_lsu_addr;
reg             mem_lsu_wen;
reg     [31:0]  mem_lsu_wdata;
reg     [ 3:0]  mem_lsu_wmask;


import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
import "DPI-C" function void pmem_write (
    input int unsigned  waddr, input int unsigned wdata, input byte wmask
);


parameter IDLE = 2'b00, WAIT = 2'b01, RESP = 2'b10;
reg [7:0] busy1;
reg [1:0] state1, next_state1;
always @(posedge clk) begin
    if(ifu_reqValid == 1) begin
        busy1 <= 0;
        mem_ifu_raddr <= ifu_raddr;
    end
    else if (state1 == WAIT) busy1 <= busy1 - 1;
    state1 <= next_state1;
end

always @(*) begin
    case (state1) 
        //IDLE: next_state1 = ifu_reqValid ? ((busy1 == 0) ? IDLE : WAIT) : IDLE;
        IDLE: next_state1 = ifu_reqValid ? WAIT : IDLE;
        WAIT: next_state1 = (busy1 == 0) ? RESP : WAIT;
        RESP: next_state1 = IDLE;
        default:;
    endcase
end

always @(posedge clk) begin
    ifu_rdata <= (state1==WAIT && busy1 == 0) ? pmem_read(mem_ifu_raddr) : 32'b0;
    ifu_respValid <= (state1 == WAIT && busy1 == 0);
end
//////////////////////////////////////////////
reg [7:0] busy2;
reg [1:0] state2, next_state2;
always @(posedge clk)  begin
    if(lsu_reqValid == 1) begin
        busy2 <= 0;
        mem_lsu_addr <= lsu_addr;
        mem_lsu_wen <= lsu_wen;
        mem_lsu_wdata <= lsu_wdata;
        mem_lsu_wmask <= lsu_wmask;
    end
    else if (state2 == WAIT) busy2 <= busy2 - 1;
    state2 <= next_state2;
end
always @(*) begin
    case (state2)
        IDLE: next_state2 = lsu_reqValid ? WAIT : IDLE;
        WAIT: next_state2 = (busy2 == 0) ? RESP : WAIT;
        RESP: next_state2 = IDLE;
        default:;
    endcase
end
always @(posedge clk) begin
    lsu_rdata <= (state2 == RESP && !mem_lsu_wen)? pmem_read(mem_lsu_addr) : 32'b0;
    if(state2 == RESP && mem_lsu_wen) begin
        pmem_write(mem_lsu_addr, mem_lsu_wdata, {4'b0, mem_lsu_wmask});
    end 

    lsu_respValid <= (state2 == RESP);
end

endmodule

