`include "params.vh"

module Xbar(
    input               clk,
    input               reset,
    AXI_IF.slaver       axi_arb,
    AXI_IF.master       axi_mem,
    AXI_IF.master       axi_uart,    
    AXI_IF.master       axi_clint    
);

// import  addr_map_pkg::*;

parameter   IDLE = 2'b00, UART = 2'b01, SRAM = 2'b10, CLINT = 2'b11;
logic   [1:0]   sel_rd, sel_wr;
logic   [1:0]   owner_rd, owner_wr;

always @(*) begin
    sel_rd = IDLE;
    if(axi_arb.araddr >= `UART_BASE && axi_arb.araddr <= `UART_END)
        sel_rd = UART;
    else if(axi_arb.araddr >= `SRAM_BASE && axi_arb.araddr <= `SRAM_END)
        sel_rd = SRAM;
    else if(axi_arb.araddr >= `CLINT_BASE && axi_arb.araddr <= `CLINT_END)begin
        sel_rd = CLINT;
    end
    else
        sel_rd = IDLE;
end

always @(posedge clk) begin
    if(axi_arb.arvalid && axi_arb.arready) begin
        owner_rd <= sel_rd;
    end
    if(axi_arb.rvalid && axi_arb.rready) begin
        owner_rd <= IDLE;
    end
end
/*
always @(posedge clk) begin
    if((axi_arb.araddr >= `CLINT_BASE && axi_arb.araddr <= CLINT_END))begin
        $display("addr:%x", axi_arb.araddr);
    end
end
*/
assign  axi_arb.arready = sel_rd == UART ? axi_uart.arready :
                          sel_rd == SRAM ? axi_mem.arready :
                          sel_rd == CLINT ? axi_clint.arready :
                          0;
assign axi_uart.arvalid = (sel_rd == UART) ? axi_arb.arvalid : 0;
assign axi_uart.araddr = (sel_rd == UART) ? (axi_arb.araddr - `UART_BASE) : 0;
assign axi_uart.rready = (owner_rd == UART) ? axi_arb.rready : 0;

assign axi_mem.arvalid = (sel_rd == SRAM) ? axi_arb.arvalid : 0;
assign axi_mem.araddr = (sel_rd == SRAM) ? (axi_arb.araddr - `SRAM_BASE) : 0;
assign axi_mem.rready = (owner_rd == SRAM) ? axi_arb.rready : 0;

assign axi_clint.arvalid = (sel_rd == CLINT) ? axi_arb.arvalid : 0;
assign axi_clint.araddr = (sel_rd == CLINT) ? (axi_arb.araddr - `CLINT_BASE) : 0;
assign axi_clint.rready = (owner_rd == CLINT) ? axi_arb.rready : 0;

assign axi_arb.rdata = (owner_rd == UART) ? axi_uart.rdata :
                       (owner_rd == SRAM) ? axi_mem.rdata :
                       (owner_rd == CLINT) ? axi_clint.rdata :
                       0;
assign axi_arb.rresp = (owner_rd == UART) ? axi_uart.rresp :
                       (owner_rd == SRAM) ? axi_mem.rresp :
                       (owner_rd == CLINT) ? axi_clint.rresp :
                       0;
assign axi_arb.rvalid = (owner_rd == UART) ? axi_uart.rvalid :
                        (owner_rd == SRAM) ? axi_mem.rvalid :
                        (owner_rd == CLINT) ? axi_clint.rvalid :
                        0;
///////////
logic fire_aw, fire_w;
assign fire_aw = axi_arb.awvalid && axi_arb.awready;
assign fire_w = axi_arb.wvalid && axi_arb.wready;
logic got_aw, got_w;
logic sent_aw, sent_w;
always @(*) begin
    sel_wr = IDLE;
    if(axi_arb.awaddr >= `UART_BASE && axi_arb.awaddr <= `UART_END)begin
        sel_wr = UART;
    end
    else if(axi_arb.awaddr >= `SRAM_BASE && axi_arb.awaddr <= `SRAM_END)
        sel_wr = SRAM;
    else if(axi_arb.awaddr >= `CLINT_BASE && axi_arb.awaddr <= `CLINT_END)
        sel_wr = CLINT;
    else begin
        sel_wr = IDLE;
    end
end

always @(posedge clk) begin
    if(fire_aw) begin
        owner_wr <= sel_wr;
    end
    if(fire_aw) got_aw <= 1;
    if(fire_w) got_w <= 1;
    if(axi_uart.awvalid && axi_uart.awready || axi_mem.awvalid && axi_mem.awready) sent_aw <= 1;
    if(axi_uart.wvalid && axi_uart.wready || axi_mem.wvalid && axi_mem.wready) sent_w <= 1;
    if(axi_arb.bvalid && axi_arb.bready) begin
        owner_wr <= IDLE;
    end
end

logic   [31:0]  wdata_r;
logic   [ 3:0]  wstrb_r;
always @(posedge clk) begin
    if(fire_w && !got_aw && !fire_aw && !got_w) begin
        wdata_r <= axi_arb.wdata;
        wstrb_r <= axi_arb.wstrb;
        got_w <= 1;
    end
end

assign axi_arb.awready = (sel_wr == UART) ? axi_uart.awready :
                         (sel_wr == SRAM) ? axi_mem.awready :
                         (sel_wr == CLINT) ? axi_clint.awready :
                         0;
                         
always @(*) begin
    if(fire_aw) begin
        axi_arb.wready = (sel_wr == UART) ? axi_uart.wready :
                         (sel_wr == SRAM) ? axi_mem.wready :
                         (sel_wr == CLINT) ? axi_clint.wready :
                         0;
    end
    else if(got_aw) begin
        axi_arb.wready = (owner_wr == UART) ? axi_uart.wready :
                         (owner_wr == SRAM) ? axi_mem.wready :
                         (owner_wr == CLINT) ? axi_clint.wready :
                         0;    
    end
    else begin
        axi_arb.wready = !got_w;
    end
end


always @(*) begin
    if(fire_w) begin
        if(got_aw) begin
            axi_uart.wvalid = (owner_wr == UART) ? axi_arb.wvalid : 0;
            axi_uart.wdata = (owner_wr == UART) ? axi_arb.wdata : 0;
            axi_uart.wstrb = (owner_wr == UART) ? axi_arb.wstrb : 0;

            axi_mem.wvalid = (owner_wr == SRAM) ? axi_arb.wvalid : 0;
            axi_mem.wdata = (owner_wr == SRAM) ? axi_arb.wdata : 0;
            axi_mem.wstrb = (owner_wr == SRAM) ? axi_arb.wstrb : 0;
        
            axi_clint.wvalid = (owner_wr == CLINT) ? axi_arb.wvalid : 0;
            axi_clint.wdata = (owner_wr == CLINT) ? axi_arb.wdata : 0;
            axi_clint.wstrb = (owner_wr == CLINT) ? axi_arb.wstrb : 0;
        end
        else if(fire_aw) begin
            axi_uart.wvalid = (sel_wr == UART) ? axi_arb.wvalid : 0;
            axi_uart.wdata = (sel_wr == UART) ? axi_arb.wdata : 0;
            axi_uart.wstrb = (sel_wr == UART) ? axi_arb.wstrb : 0;

            axi_mem.wvalid = (sel_wr == SRAM) ? axi_arb.wvalid : 0;
            axi_mem.wdata = (sel_wr == SRAM) ? axi_arb.wdata : 0;
            axi_mem.wstrb = (sel_wr == SRAM) ? axi_arb.wstrb : 0;

            axi_clint.wvalid = (sel_wr == CLINT) ? axi_arb.wvalid : 0;
            axi_clint.wdata = (sel_wr == CLINT) ? axi_arb.wdata : 0;
            axi_clint.wstrb = (sel_wr == CLINT) ? axi_arb.wstrb : 0;
        end
        else begin
            axi_uart.wvalid = 0;
            axi_uart.wdata = 0;
            axi_uart.wstrb = 0;
            axi_mem.wvalid = 0;
            axi_mem.wdata = 0;
            axi_mem.wstrb = 0;
            axi_clint.wvalid = 0;
            axi_clint.wdata = 0;
            axi_clint.wstrb = 0;
        end
    end
    else if(got_w) begin
        if(fire_aw) begin
            axi_mem.wvalid = (sel_wr == SRAM) ? 1 : 0;
            axi_mem.wdata = (sel_wr == SRAM) ? wdata_r : 0;
            axi_mem.wstrb = (sel_wr == SRAM) ? wstrb_r : 0;

            axi_uart.wvalid = (sel_wr == UART) ? 1 : 0;
            axi_uart.wdata = (sel_wr == UART) ? wdata_r : 0;
            axi_uart.wstrb = (sel_wr == UART) ? wstrb_r : 0;

            axi_clint.wvalid = (sel_wr == CLINT) ? 1 : 0;
            axi_clint.wdata = (sel_wr == CLINT) ? wdata_r : 0;
            axi_clint.wstrb = (sel_wr == CLINT) ? wstrb_r : 0;
        end
        else if(got_aw) begin
            axi_mem.wvalid = (owner_wr == SRAM) ? !sent_w : 0;
            axi_mem.wdata = (owner_wr == SRAM) ? wdata_r : 0;
            axi_mem.wstrb = (owner_wr == SRAM) ? wstrb_r : 0;

            axi_uart.wvalid = (owner_wr == UART) ? !sent_w : 0;
            axi_uart.wdata = (owner_wr == UART) ? wdata_r : 0;
            axi_uart.wstrb = (owner_wr == UART) ? wstrb_r : 0;           
            
            axi_clint.wvalid = (owner_wr == CLINT) ? !sent_w : 0;
            axi_clint.wdata = (owner_wr == CLINT) ? wdata_r : 0;
            axi_clint.wstrb = (owner_wr == CLINT) ? wstrb_r : 0;       
        end
        else begin
            axi_mem.wvalid = 0;
            axi_mem.wdata = 0;
            axi_mem.wstrb = 0;

            axi_uart.wvalid = 0;
            axi_uart.wdata = 0;
            axi_uart.wstrb = 0;
            
            axi_clint.wvalid = 0;
            axi_clint.wdata = 0;
            axi_clint.wstrb = 0;
        end
    end
    else begin
        axi_mem.wvalid = 0;
        axi_mem.wdata = 0;
        axi_mem.wstrb = 0;
        
        axi_uart.wvalid = 0;
        axi_uart.wdata = 0;
        axi_uart.wstrb = 0;

        axi_clint.wvalid = 0;
        axi_clint.wdata = 0;
        axi_clint.wstrb = 0;
    end
end

assign axi_uart.awvalid = (sel_wr == UART) ? axi_arb.awvalid : 0;
assign axi_uart.awaddr = (sel_wr == UART) ? (axi_arb.awaddr - `UART_BASE) : 0;
assign axi_uart.bready = (owner_wr == UART) ? axi_arb.bready : 0;

assign axi_mem.awvalid = (sel_wr == SRAM) ? axi_arb.awvalid : 0;
assign axi_mem.awaddr = (sel_wr == SRAM) ? (axi_arb.awaddr - `SRAM_BASE) : 0;
assign axi_mem.bready = (owner_wr == SRAM) ? axi_arb.bready : 0;

assign axi_clint.awvalid = (sel_wr == CLINT) ? axi_arb.awvalid : 0;
assign axi_clint.awaddr = (sel_wr == CLINT) ? (axi_arb.awaddr - `CLINT_BASE) : 0;
assign axi_clint.bready = (owner_wr == CLINT) ? axi_arb.bready : 0;

assign axi_arb.bvalid = (owner_wr == UART) ? axi_uart.bvalid :
                        (owner_wr == SRAM) ? axi_mem.bvalid :
                        (owner_wr == CLINT) ? axi_clint.bvalid :
                        0;
assign axi_arb.bresp = (owner_wr == UART) ? axi_uart.bresp :
                       (owner_wr == SRAM) ? axi_mem.bresp :
                       (owner_wr == CLINT) ? axi_clint.bresp :
                       0;
always @(posedge clk) begin
    if(axi_arb.bvalid && axi_arb.bready) begin
        got_w <= 0;
        got_aw <= 0;
        sent_w <= 0;
        sent_aw <= 0;
    end  
end

endmodule
