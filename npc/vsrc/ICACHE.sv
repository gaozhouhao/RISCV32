`include "params.vh"
module ICACHE(
    input                               clk,
    input                               reset,
    input                               in_icache_flush,
    AXI_IF.slaver                       axi_in,
    AXI_IF.master                       axi_out
);

`ifdef VERILATOR
    import perf_pkg::*;
    import "DPI-C" function void get_inst(input int inst);
`endif

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    localparam BYTE_NUM     = DATA_WIDTH / 8;
    localparam BYTE_OFFSET_WIDTH = $clog2(BYTE_NUM);


    localparam int OFFSET_WIDTH = 4;
    localparam int INDEX_WIDTH  = 2;

    localparam int CACHE_LINE_BYTES = 2 ** OFFSET_WIDTH;
    localparam int CACHE_NUM_LINES  = 2 ** INDEX_WIDTH;
    localparam int CACHE_SIZE_BYTES = CACHE_LINE_BYTES * CACHE_NUM_LINES;

    localparam int TAG_WIDTH    = ADDR_WIDTH - OFFSET_WIDTH - INDEX_WIDTH;

    reg [ADDR_WIDTH-1:0] req_addr;
    reg [ADDR_WIDTH-1:0] refill_addr;

    wire [TAG_WIDTH-1:0] tag;
    wire [INDEX_WIDTH-1:0] index;
    wire [OFFSET_WIDTH-1:0] offset;

    assign tag    = axi_in.araddr[ADDR_WIDTH-1:OFFSET_WIDTH+INDEX_WIDTH];
    assign index  = axi_in.araddr[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH];
    assign offset = axi_in.araddr[OFFSET_WIDTH-1:0];

    wire [INDEX_WIDTH-1:0] refill_index;
    wire [TAG_WIDTH-1:0]   refill_tag;
    wire [OFFSET_WIDTH-1:0] refill_offset;

    assign refill_index  = refill_addr[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH];
    assign refill_tag    = refill_addr[ADDR_WIDTH-1:OFFSET_WIDTH+INDEX_WIDTH];
    assign refill_offset = refill_addr[OFFSET_WIDTH-1:0];

    wire [INDEX_WIDTH-1:0] req_index;
    wire [OFFSET_WIDTH-1:0] req_offset;
    wire [TAG_WIDTH-1:0] req_tag;

    assign req_index    = req_addr[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH];
    assign req_tag      = req_addr[ADDR_WIDTH-1:OFFSET_WIDTH+INDEX_WIDTH];
    assign req_offset   = req_addr[OFFSET_WIDTH-1:0];


    reg [TAG_WIDTH-1:0] tag_array [0:CACHE_NUM_LINES-1];
    reg [CACHE_LINE_BYTES*8-1:0] data_array [0:CACHE_NUM_LINES-1];
    reg [CACHE_NUM_LINES-1:0] valid_array;

    localparam REFILL_CNT_WIDTH =
        (OFFSET_WIDTH == BYTE_OFFSET_WIDTH)
        ? 1
        : OFFSET_WIDTH - BYTE_OFFSET_WIDTH;
    reg [REFILL_CNT_WIDTH-1:0] refill_cnt;
    localparam WORDS_PER_LINE = 1 << (OFFSET_WIDTH - BYTE_OFFSET_WIDTH);

    localparam IDLE = 3'b000;
    localparam RESP = 3'b001;
    localparam SEND_AR = 3'b011;
    localparam WAIT_R = 3'b100;
    reg [2:0] state;

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            refill_addr <= 0;
            valid_array <= {CACHE_NUM_LINES{1'b0}};
            axi_in.rvalid <= 1'b0;
            axi_out.arvalid <= 1'b0;
            state <= IDLE;
        end
        else if (in_icache_flush == 1'b1) begin
            valid_array <= {CACHE_NUM_LINES{1'b0}};
        end
        else begin
            case (state)
                IDLE: begin
                    if (axi_in.arvalid && axi_in.arready) begin
                        `ifdef VERILATOR
                            perf_event(PERF_ICACHE_ACCESS);
                        `endif
                        if (valid_array[index] && tag_array[index] == tag) begin
                            axi_in.rdata <= data_array[index][offset * 8 +: DATA_WIDTH];
                            axi_in.rvalid <= 1'b1;
                            axi_in.rresp <= 2'b00;
                            state <= RESP;
                            `ifdef VERILATOR
                                perf_event(PERF_ICACHE_HIT);
                                perf_event(PERF_ICACHE_HIT_CYCLES);
                            `endif
                        end
                        else begin
                            `ifdef VERILATOR
                                perf_event(PERF_ICACHE_MISS);
                                perf_event(PERF_ICACHE_MISS_CYCLES);
                            `endif
                            refill_cnt <= 0;
                            req_addr <= axi_in.araddr;
                            refill_addr <= {axi_in.araddr[ADDR_WIDTH-1:OFFSET_WIDTH], {{OFFSET_WIDTH}{1'b0}}} ; // align to cache line
                            axi_out.araddr <= {axi_in.araddr[ADDR_WIDTH-1:OFFSET_WIDTH], {{OFFSET_WIDTH}{1'b0}}};
                            axi_out.arvalid <= 1'b1;
                            axi_out.arburst <= 2'b01;
                            axi_out.arlen <= (1 << (OFFSET_WIDTH - BYTE_OFFSET_WIDTH)) - 1;
                            axi_out.arsize <= 3'b010;
                            state <= SEND_AR;
                        end
                    end
                end
                RESP: begin
                    if (axi_in.rvalid && axi_in.rready) begin
                        axi_in.rvalid <= 1'b0;
                        state <= IDLE;
                    end
                end
                SEND_AR: begin
                    `ifdef VERILATOR
                        perf_event(PERF_ICACHE_MISS_CYCLES);
                    `endif
                    if (axi_out.arvalid && axi_out.arready) begin
                        axi_out.arvalid <= 1'b0;
                        axi_out.arburst <= 2'b0;
                        axi_out.arlen <= 8'b0;
                        axi_out.arsize <= 3'b0;
                        state <= WAIT_R;
                    end
                end
                WAIT_R: begin
                    `ifdef VERILATOR
                        perf_event(PERF_ICACHE_MISS_CYCLES);
                    `endif
                    if (axi_out.rvalid && axi_out.rready) begin
                        data_array[refill_index][refill_offset * 8 +: DATA_WIDTH] <= axi_out.rdata;
                        if (axi_out.rlast == 1'b1) begin
                            valid_array[refill_index] <= 1'b1;
                            tag_array[refill_index] <= refill_tag;
                            if (req_addr == refill_addr) begin
                                axi_in.rdata <= axi_out.rdata;
                            end
                            else begin
                                axi_in.rdata <= data_array[req_index][req_offset*8 +: DATA_WIDTH];
                            end
                            axi_in.rvalid <= 1'b1;
                            axi_in.rresp <= 2'b00;
                            state <= RESP;
                        end
                        else begin
                            refill_addr <= refill_addr + BYTE_NUM;
                            state <= WAIT_R;
                            refill_cnt <= refill_cnt + 1'b1;
                        end
                    end
                end
                default: ;
            endcase
        end
    end

    assign axi_in.arready = (state == IDLE);
    assign axi_out.rready = (state == WAIT_R);


endmodule

