module UART(
    input                               clk,
    input                               reset,    
    AXI_IF.slaver                       axi
);

logic   is_busy_ar, is_busy_aw, is_busy_w;
logic   aw_fire, w_fire, b_fire;
logic   [31:0]  mem_waddr;
logic   [31:0]  mem_wdata;
logic   [ 7:0]  mem_wmask;
logic   [31:0]  mem_addr;

always@(posedge clk) begin
    assert (~axi.arvalid) else $fatal("Unexpected UART read");
end

assign aw_fire = axi.awvalid && axi.awready;
assign w_fire = axi.wvalid && axi.wready;
assign b_fire = axi.bvalid && axi.bready;

assign axi.awready = !aw_got;
assign axi.wready  = !w_got;
logic   aw_got, w_got;

always_ff @(posedge clk) begin
    if (reset == 1) begin
        aw_got <= 0;
        w_got  <= 0;
        axi.bvalid <= 0;
    end 
    else begin
        if (aw_fire) begin
            mem_waddr <= axi.awaddr;
            aw_got <= 1;
        end
        if (w_fire) begin
            mem_wdata <= axi.wdata;
            mem_wmask <= {4'b0, axi.wstrb};
            w_got  <= 1;
        end
        if (aw_got && w_got) begin
            axi.bvalid <= 1;
            axi.bresp <= 1;
        end

        if (b_fire) begin
            $write("%c", mem_wdata[7:0]);
            axi.bvalid <= 0;
            axi.bresp <= 1;
            aw_got <= 0;
            w_got  <= 0;
        end
    end
end

endmodule

