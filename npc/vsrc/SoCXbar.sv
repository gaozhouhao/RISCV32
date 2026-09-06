`include "params.vh"

module SoCXbar (
    input logic clk,
    input logic reset,

    AXI_IF.slaver   axi_arb,
    AXI_IF.master   axi_soc,
    AXI_IF.master   axi_clint
);

typedef enum logic [1:0] {
    SLAVE_IDLE,
    SLAVE_SOC,
    SLAVE_CLINT
} slave_owner_t;

slave_owner_t read_slave;


//READ
always@(posedge clk) begin
    if (reset == 1'b1) begin
        read_slave <= SLAVE_IDLE;
    end
    if(axi_arb.arvalid && axi_arb.arready) begin
        if (axi_arb.araddr >= `CLINT_BASE && axi_arb.araddr <  `CLINT_END)
            read_slave <= SLAVE_CLINT;
        else
            read_slave <= SLAVE_SOC;

    end
    else if(axi_arb.rvalid && axi_arb.rready) begin
        if (read_slave == SLAVE_SOC) begin
            if (axi_arb.rlast == 1'b1)
                read_slave <= SLAVE_IDLE;
        end
        else if (read_slave == SLAVE_CLINT)
            read_slave <= SLAVE_IDLE;
    end
end


/////////////////////////
// Arbiter Fan Out
/////////////////////////
always@(*) begin

    // default
    axi_clint.awvalid = 1'h0;
    axi_clint.awaddr = 32'h0;
    axi_clint.wvalid = 1'h0;
    axi_clint.wstrb = 4'h0;
    axi_clint.wdata = 32'h0;
    axi_clint.bready = 1'h0;
    axi_clint.araddr  = 32'b0;
    axi_clint.arvalid = 1'b0;
    axi_clint.rready  = 1'b0;

    axi_soc.araddr  = 0;
    axi_soc.arvalid = 0;
    axi_soc.arburst = 0;
    axi_soc.arlen   = 0;
    axi_soc.arsize  = 0;
    axi_soc.rready  = 0;

    axi_soc.awaddr  = 0;
    axi_soc.awvalid = 0;
    axi_soc.wdata   = 0;
    axi_soc.wstrb   = 0;
    axi_soc.wvalid  = 0;
    axi_soc.bready  = 0;

    case (read_slave)
        SLAVE_CLINT: begin
            axi_arb.rdata = axi_clint.rdata;
            axi_arb.rresp = axi_clint.rresp;
            axi_arb.rvalid = axi_clint.rvalid;
            axi_clint.rready = axi_arb.rready;
        end
        SLAVE_SOC: begin
            axi_arb.rdata = axi_soc.rdata;
            axi_arb.rresp = axi_soc.rresp;
            axi_arb.rvalid = axi_soc.rvalid;
            axi_arb.rlast  = axi_soc.rlast;
            axi_soc.rready = axi_arb.rready;
        end
        SLAVE_IDLE: begin
            axi_arb.rdata = 32'b0;
            axi_arb.rresp = 2'b0;
            axi_arb.rvalid = 1'b0;
            axi_soc.rready = axi_arb.rready;
        end
        default: ;
    endcase

    axi_arb.awready = axi_soc.awready;
    axi_arb.wready = axi_soc.wready;
    axi_arb.bresp = axi_soc.bresp;
    axi_arb.bvalid = axi_soc.bvalid;
    // CLINT
    if (axi_arb.araddr >= `CLINT_BASE && axi_arb.araddr < `CLINT_END) begin
        axi_clint.araddr = (axi_arb.araddr - `CLINT_BASE);
        axi_clint.arvalid = axi_arb.arvalid;
        axi_arb.arready = axi_clint.arready;
    end
    // SoC
    else begin
        axi_soc.araddr  = axi_arb.araddr;
        axi_soc.arvalid = axi_arb.arvalid;
        axi_soc.arburst = axi_arb.arburst;
        axi_soc.arlen   = axi_arb.arlen;
        axi_soc.arsize  = axi_arb.arsize;
        axi_arb.arready = axi_soc.arready;

    end
    

        axi_soc.awvalid = axi_arb.awvalid;
        axi_soc.awaddr = axi_arb.awaddr;

        axi_soc.wvalid = axi_arb.wvalid;
        axi_soc.wstrb = axi_arb.wstrb;
        axi_soc.wdata = axi_arb.wdata;

        axi_soc.bready = axi_arb.bready;
end



endmodule
