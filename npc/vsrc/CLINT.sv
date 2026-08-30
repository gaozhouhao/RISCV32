module CLINT (
    input               clk,
    input               reset,
    AXI_IF.slaver       axi    
);

logic   [31:0]  mtime_lo, mtime_hi;
always @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        {mtime_hi, mtime_lo} <= 64'b0;
    end
    else begin
        {mtime_hi, mtime_lo} <= {mtime_hi, mtime_lo} + 64'd100;
    end
end


always @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        axi.arready <= 1'b0;
        axi.rvalid <= 1'b0;
    end
    else begin
        if(axi.arvalid) begin
            //$display("%x", axi.araddr);
            if(axi.araddr == 32'h48)
                axi.rdata <= mtime_lo;
            else if(axi.araddr == 32'h4c)
                axi.rdata <= mtime_hi;
            else
                $fatal("Unexpected CLINT read");
            axi.rresp <= 0;
            axi.rvalid <= 1;
        end
        else if(axi.rready) begin
            axi.rvalid <= 0;
        end
        axi.arready <= 1'b1;
    end
end


endmodule
