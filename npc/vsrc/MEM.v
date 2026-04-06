module MEM(
    input                               clk,

    output      reg                     ifu_respValid,
    input       reg                     ifu_reqValid,
    input               [31:0]          ifu_raddr,
    output      reg     [31:0]          ifu_rdata,
    
    output      reg                     lsu_respValid,
    input       reg                     lsu_respReady,
    input       reg                     lsu_reqValid,
    output      reg                     lsu_reqReady,
    input               [31:0]          lsu_addr,
    input                               lsu_wen,
    input               [31:0]          lsu_wdata,
    input               [ 3:0]          lsu_wmask,
    output      reg     [31:0]          lsu_rdata
);

reg     [7:0]   random_num;
LFSR lfsr(
    .clk(clk),
    .random_num(random_num)
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

reg [7:0] busy1;
always @(posedge clk) begin
    if(ifu_reqValid == 1) begin
        busy1 <= random_num + 1;
        mem_ifu_raddr <= ifu_raddr;
    end
    else if (busy1 > 0)
        busy1 <= busy1 - 1;
end

always @(*) begin
    ifu_rdata = (busy1 == 1) ? pmem_read(mem_ifu_raddr) : 32'b0;
    ifu_respValid = (busy1 == 1);
end
//////////////////////////////////////////////
parameter IDLE = 2'b00, BUSY = 2'b01, WAIT = 2'b10, WAIT_READY = 2'b11;
reg     [1:0]   state, next_state;

reg [7:0] busy2;
reg [7:0] busy3;
reg [7:0]   req_busy2;
always @(*) begin
    case(state) 
        IDLE: begin
            next_state = lsu_reqValid ? BUSY : IDLE;
        end
        BUSY: begin
            next_state = (req_busy2 == 1) ? WAIT : BUSY;
        end
        WAIT: begin
            next_state = (busy3 == 1) ? WAIT_READY : WAIT;
        end
        WAIT_READY: begin
            next_state = lsu_respReady ? IDLE : WAIT_READY;
        end
    endcase
    lsu_rdata = (state == WAIT_READY) ? pmem_read(mem_lsu_addr) : 0;
end

always @(posedge clk) begin
    state <= next_state;
    //if(lsu_reqValid && state == IDLE)   busy2 <= random_num + 1;    
    if(lsu_reqValid && state == IDLE)   req_busy2 <= random_num + 1; 
    
    if(req_busy2 > 0) req_busy2 <= req_busy2 - 1;
    
    if(req_busy2 == 1) begin
        lsu_reqReady <= 1;
        busy3 <= random_num + 1;
        mem_lsu_addr <= lsu_addr;
        mem_lsu_wen <= lsu_wen;
        mem_lsu_wdata <= lsu_wdata;
        mem_lsu_wmask <= lsu_wmask;
    end
    else
        lsu_reqReady <= 0;
    
    if(req_busy2 == 1) busy3 <= random_num + 1;
    if(busy3 > 0) busy3 <= busy3 - 1;
    if(busy3 == 1) lsu_respValid <= 1;
    if(lsu_respReady == 1) lsu_respValid <= 0;
end
/*
always @(posedge clk)  begin
    if(lsu_reqValid == 1) begin
        busy2 <= random_num + 1;

    end
    if(busy2 == 1) begin
        busy3 <= random_num + 1;
        lsu_reqReady <= 1;
        mem_lsu_addr <= lsu_addr;
        mem_lsu_wen <= lsu_wen;
        mem_lsu_wdata <= lsu_wdata;
        mem_lsu_wmask <= lsu_wmask;
    end
    else begin
        lsu_reqReady <= 0;
    end
    if(busy2 > 0) busy2 <= busy2 - 1;
    if(busy3 > 0) busy3 <= busy3 - 1;
end

always @(*) begin
    lsu_rdata = (!mem_lsu_wen && busy2 == 1) ? pmem_read(mem_lsu_addr) : 32'b0;
    if(busy2 == 1 && mem_lsu_wen) begin
        pmem_write(mem_lsu_addr, mem_lsu_wdata, {4'b0, mem_lsu_wmask});
    end 

    lsu_respValid = (busy2 == 1);
end
*/
endmodule

