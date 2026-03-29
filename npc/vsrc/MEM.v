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

reg [7:0] busy1;
reg state, next_state;
initial busy1 = 5;
always @(posedge clk) begin
    state <= next_state;
end

always @(posedge clk) begin
    
    /*
    if(state1 == 0) begin
        if(ifu_reqValid) begin
            state1 <= ~state1;
            busy1 <= 8'h5;
        end
    end
    else begin
        busy1 <= busy1 - 1;
        if(busy1 == 0) state1 <= ~state1;
    end
    
    ifu_rdata <= (busy1 == 0) ? pmem_read(ifu_raddr) : 32'b0;
    ifu_respValid <= (busy1 == 0);
    */
    ifu_rdata <= ifu_reqValid ? pmem_read(ifu_raddr) : 32'b0;
    ifu_respValid <= ifu_reqValid;
end

integer busy2 = 0;
always @(posedge clk) begin
    lsu_rdata <= (lsu_reqValid && !lsu_wen) ? pmem_read(lsu_addr) : 32'b0;
    if (lsu_reqValid && lsu_wen) begin
        pmem_write(lsu_addr, lsu_wdata, {4'b0,lsu_wmask});
    end
    lsu_respValid <= lsu_reqValid;
end

endmodule

