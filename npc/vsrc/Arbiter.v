module Arbiter (
    input logic clk,
    input logic reset,

    AXI_IF.slaver   axi_ifu,
    AXI_IF.slaver   axi_lsu,
    AXI_IF.master   axi_arb
);

typedef enum logic [1:0] {
    IDLE,
    LSU,
    IFU
} owner_t;

owner_t read_owner;
owner_t write_owner;
//READ
always@(posedge clk) begin
    if(axi_arb.arvalid && axi_arb.arready) begin
        if(axi_lsu.arvalid) read_owner <= LSU;
        else if(axi_ifu.arvalid) read_owner <= IFU;
    end
    
    if(axi_arb.rvalid && axi_arb.rready) begin
        read_owner <= IDLE;
    end
end
//WRITE
always@(posedge clk) begin
    if(axi_arb.awvalid && axi_arb.awready) begin
        if(axi_lsu.awvalid) write_owner <= LSU;
        else if(axi_ifu.awvalid) write_owner <= IFU;
    end
    
    if(axi_arb.bvalid && axi_arb.bready) begin
        write_owner <= IDLE;
    end
end
always@(*) begin
    // default
    axi_ifu.arready = 0;
    axi_ifu.rdata   = (read_owner == IFU) ? axi_arb.rdata : 0;
    axi_ifu.rresp   = (read_owner == IFU) ? axi_arb.rresp : 0;
    axi_ifu.rvalid  = 0;

    axi_ifu.awready = 0;
    axi_ifu.wready  = 0;
    axi_ifu.bresp   = (write_owner == IFU) ? axi_arb.bresp : 0;
    axi_ifu.bvalid  = 0;

    axi_lsu.arready = 0;
    axi_lsu.rdata   = (read_owner == LSU) ? axi_arb.rdata : 0;
    axi_lsu.rresp   = (read_owner == LSU) ? axi_arb.rresp : 0;
    axi_lsu.rvalid  = 0;

    axi_lsu.awready = 0;
    axi_lsu.wready  = 0;
    axi_lsu.bresp   = (read_owner == LSU) ? axi_arb.bresp : 0;
    axi_lsu.bvalid  = 0;

    // master default
    axi_arb.araddr  = 0;
    axi_arb.arvalid = 0;
    axi_arb.rready  = 0;

    axi_arb.awaddr  = 0;
    axi_arb.awvalid = 0;

    axi_arb.wdata   = 0;
    axi_arb.wstrb   = 0;
    axi_arb.wvalid  = 0;

    axi_arb.bready  = 0;

    // READ
    // LSU priority

    if (axi_lsu.arvalid || read_owner == LSU) begin
        axi_arb.araddr  = axi_lsu.araddr;
        axi_arb.arvalid = axi_lsu.arvalid;
        axi_lsu.arready = axi_arb.arready;

        axi_lsu.rdata   = axi_arb.rdata;
        axi_lsu.rresp   = axi_arb.rresp;
        axi_lsu.rvalid  = axi_arb.rvalid;

        axi_arb.rready  = axi_lsu.rready;
    end
    else if (axi_ifu.arvalid || read_owner == IFU) begin
        axi_arb.araddr  = axi_ifu.araddr;
        axi_arb.arvalid = axi_ifu.arvalid;
        axi_ifu.arready = axi_arb.arready;

        axi_ifu.rdata   = axi_arb.rdata;
        axi_ifu.rresp   = axi_arb.rresp;
        axi_ifu.rvalid  = axi_arb.rvalid;

        axi_arb.rready  = axi_ifu.rready;
    end

    // WRITE
    // only LSU writes
    if(axi_lsu.awvalid || write_owner == LSU) begin
        axi_arb.awaddr  = axi_lsu.awaddr;
        axi_arb.awvalid = axi_lsu.awvalid;
        axi_lsu.awready = axi_arb.awready;

        axi_arb.wdata   = axi_lsu.wdata;
        axi_arb.wstrb   = axi_lsu.wstrb;
        axi_arb.wvalid  = axi_lsu.wvalid;
        axi_lsu.wready  = axi_arb.wready;

        axi_lsu.bresp   = axi_arb.bresp;
        axi_lsu.bvalid  = axi_arb.bvalid;
        axi_arb.bready  = axi_lsu.bready;
    end
end

endmodule
