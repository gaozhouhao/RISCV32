`include "params.vh"
module ICACHE(
    input                               clk,
    input                               reset,
    AXI_IF.slaver                       axi_in,
    AXI_IF.master                       axi_out
);

`ifdef VERILATOR
    import perf_pkg::*;
    import "DPI-C" function void get_inst(input int inst);
`endif

    localparam int OFFSET_WIDTH = 2;
    localparam int INDEX_WIDTH  = 4;

    localparam int CACHE_LINE_BYTES = 2 ** OFFSET_WIDTH;
    localparam int CACHE_NUM_LINES  = 2 ** INDEX_WIDTH;
    localparam int CACHE_SIZE_BYTES = CACHE_LINE_BYTES * CACHE_NUM_LINES;

    localparam int TAG_WIDTH    = 32 - OFFSET_WIDTH - INDEX_WIDTH;

    wire [TAG_WIDTH-1:0] tag;
    wire [INDEX_WIDTH-1:0] index;
    wire [OFFSET_WIDTH-1:0] offset;

    assign tag    = axi_in.araddr[31:OFFSET_WIDTH+INDEX_WIDTH];
    assign index  = axi_in.araddr[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH];
    assign offset = axi_in.araddr[OFFSET_WIDTH-1:0];

    reg [TAG_WIDTH-1:0] tag_array [0:CACHE_NUM_LINES-1];
    reg [CACHE_LINE_BYTES*8-1:0] data_array [0:CACHE_NUM_LINES-1];
    reg [CACHE_NUM_LINES-1:0] valid_array;

    localparam IDLE = 3'b000;
    localparam CACHE_HIT = 3'b001;
    localparam CACHE_MISS = 3'b010;
    localparam SEND_AR = 3'b011;
    localparam WAIT_R = 3'b100;
    localparam SEND_R = 3'b101;
    reg [2:0] state;
    reg [31:0]  req_addr;
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            valid_array <= {CACHE_NUM_LINES{1'b0}};
            axi_in.rvalid <= 1'b0;
            axi_out.arvalid <= 1'b0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (axi_in.arvalid && axi_in.arready) begin
                        `ifdef VERILATOR
                            perf_event(PERF_ICACHE_ACCESS);
                        `endif
                        if (valid_array[index] && tag_array[index] == tag) begin
                            axi_in.rdata <= data_array[index];
                            axi_in.rvalid <= 1'b1;
                            axi_in.rresp <= 2'b00;
                            state <= CACHE_HIT;
                            `ifdef VERILATOR
                                perf_event(PERF_ICACHE_HIT);
                                perf_event(PERF_ICACHE_HIT_CYCLES);
                            `endif
                        end
                        else begin
                            state <= CACHE_MISS;
                            `ifdef VERILATOR
                                perf_event(PERF_ICACHE_MISS);
                                perf_event(PERF_ICACHE_MISS_CYCLES);
                            `endif
                            req_addr <= axi_in.araddr;
                        end
                    end
                end
                CACHE_HIT: begin
                    if (axi_in.rvalid && axi_in.rready) begin
                        axi_in.rvalid <= 1'b0;
                        state <= IDLE;
                    end
                end
                CACHE_MISS: begin
                    `ifdef VERILATOR
                        perf_event(PERF_ICACHE_MISS_CYCLES);
                    `endif
                    axi_out.araddr <= req_addr;
                    axi_out.arvalid <= 1'b1;
                    state <= SEND_AR;
                end
                SEND_AR: begin
                    `ifdef VERILATOR
                        perf_event(PERF_ICACHE_MISS_CYCLES);
                    `endif
                    if (axi_out.arvalid && axi_out.arready) begin
                        axi_out.arvalid <= 1'b0;
                        state <= WAIT_R;
                    end
                end
                WAIT_R: begin
                    `ifdef VERILATOR
                        perf_event(PERF_ICACHE_MISS_CYCLES);
                    `endif
                    if (axi_out.rvalid && axi_out.rready) begin
                        data_array[req_addr[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH]] <= axi_out.rdata;
                        tag_array[req_addr[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH]] <= req_addr[31:OFFSET_WIDTH+INDEX_WIDTH];
                        valid_array[req_addr[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH]] <= 1'b1;
                        axi_in.rdata <= axi_out.rdata;
                        axi_in.rvalid <= 1'b1;
                        axi_in.rresp <= 2'b00;
                        state <= SEND_R;
                    end
                end
                SEND_R: begin
                    if (axi_in.rvalid && axi_in.rready) begin
                        axi_in.rvalid <= 1'b0;
                        state <= IDLE;
                    end
                end
                default: ;
            endcase
        end
    end

    assign axi_in.arready = (state == IDLE);
    assign axi_out.rready = (state == WAIT_R);


endmodule

