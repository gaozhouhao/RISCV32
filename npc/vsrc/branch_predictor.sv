
`include "params.vh"

module branch_predictor (
    input                               clk,
    input                               reset,

    input  [31:0]                       ifu_pc_i,
    output [31:0]                       ifu_pred_pc_o,

    input                               exu_update_en_i,
    input  [31:0]                       exu_pc_i,
    input  [31:0]                       exu_target_i,
    input                               exu_taken_i
);

    parameter ADDR_WIDTH = 32;

    localparam int OFFSET_WIDTH = 2;
    localparam int INDEX_WIDTH  = 5;

    localparam int CACHE_NUM_LINES = 2 ** INDEX_WIDTH;
    localparam int TAG_WIDTH = ADDR_WIDTH - OFFSET_WIDTH - INDEX_WIDTH;


    wire [INDEX_WIDTH-1:0] ifu_index;
    wire [TAG_WIDTH-1:0]   ifu_tag;

    assign ifu_index = ifu_pc_i[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH];
    assign ifu_tag   = ifu_pc_i[ADDR_WIDTH-1:OFFSET_WIDTH+INDEX_WIDTH];

    wire [INDEX_WIDTH-1:0] exu_index;
    wire [TAG_WIDTH-1:0]   exu_tag;

    assign exu_index = exu_pc_i[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH];
    assign exu_tag   = exu_pc_i[ADDR_WIDTH-1:OFFSET_WIDTH+INDEX_WIDTH];


    reg [TAG_WIDTH-1:0]         tag_array     [0:CACHE_NUM_LINES-1];
    reg [ADDR_WIDTH-1:0]        target_array  [0:CACHE_NUM_LINES-1];
    reg [1:0]                   counter_array [0:CACHE_NUM_LINES-1];
    reg [CACHE_NUM_LINES-1:0]   valid_array;


    wire ifu_hit;
    wire exu_hit;

    assign ifu_hit = valid_array[ifu_index] && tag_array[ifu_index] == ifu_tag;
    assign exu_hit = valid_array[exu_index] && tag_array[exu_index] == exu_tag;

    assign ifu_pred_pc_o = (ifu_hit && counter_array[ifu_index][1])
                         ? target_array[ifu_index]
                         : ifu_pc_i + 32'd4;


    always @(posedge clk) begin
        if (reset == 1'b1) begin
            valid_array <= {CACHE_NUM_LINES{1'b0}};
        end
        else begin
            if (exu_update_en_i == 1'b1) begin
                if (exu_hit) begin
                    if (exu_taken_i == 1'b1) begin
                        if (counter_array[exu_index] < 2'b11) begin
                            counter_array[exu_index] <= counter_array[exu_index] + 1'b1;
                        end
                    end
                    else begin
                        if (counter_array[exu_index] > 2'b00) begin
                            counter_array[exu_index] <= counter_array[exu_index] - 1'b1;
                        end
                    end
                end
                else if (exu_taken_i == 1'b1) begin
                    valid_array[exu_index] <= 1'b1;
                    tag_array[exu_index] <= exu_tag;
                    target_array[exu_index] <= exu_target_i;
                    counter_array[exu_index] <= 2'b10;
                end
            end
        end
    end

endmodule
