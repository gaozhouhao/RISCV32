module mydesign (
    input                   clk,
    input                   in_reset,
    input       [31:0]      in_wdata,
    input       [4:0]       in_waddr,
    input                   in_lsu_rf_we,
    output                  out_wb_done,
    output                  out_wb_done_flag,
    input       [4:0]       in_raddr1,
    input       [4:0]       in_raddr2,
    output      [31:0]      out_rdata1,
    output      [31:0]      out_rdata2,

    input                   in_lsu_to_rf_valid,
    output                  out_lsu_to_rf_ready,
    input                   in_rf_to_ifu_ready,
    output                  out_rf_to_ifu_valid
);

    // input registers
    reg             reset;
    reg   [31:0]    wdata;
    reg   [4:0]     waddr;
    reg             lsu_rf_we;
    reg   [4:0]     raddr1;
    reg   [4:0]     raddr2;
    reg             lsu_to_rf_valid;
    reg             rf_to_ifu_ready;

    // DUT outputs
    wire  [31:0]    rdata1;
    wire  [31:0]    rdata2;
    wire            wb_done;
    wire            wb_done_flag;
    wire            lsu_to_rf_ready;
    wire            rf_to_ifu_valid;

    // output registers
    reg   [31:0]    rdata1_reg;
    reg   [31:0]    rdata2_reg;
    reg             wb_done_reg;
    reg             wb_done_flag_reg;
    reg             lsu_to_rf_ready_reg;
    reg             rf_to_ifu_valid_reg;

    always @(posedge clk) begin
        // input FF
        reset           <= in_reset;
        wdata           <= in_wdata;
        waddr           <= in_waddr;
        lsu_rf_we       <= in_lsu_rf_we;
        raddr1          <= in_raddr1;
        raddr2          <= in_raddr2;
        lsu_to_rf_valid <= in_lsu_to_rf_valid;
        rf_to_ifu_ready <= in_rf_to_ifu_ready;

        // output FF
        rdata1_reg          <= rdata1;
        rdata2_reg          <= rdata2;
        wb_done_reg         <= wb_done;
        wb_done_flag_reg    <= wb_done_flag;
        lsu_to_rf_ready_reg <= lsu_to_rf_ready;
        rf_to_ifu_valid_reg <= rf_to_ifu_valid;
    end

    WBU wbu (
        .clk             (clk),
        .reset           (reset),

        .wdata           (wdata),
        .waddr           (waddr),
        .lsu_rf_we       (lsu_rf_we),

        .wb_done         (wb_done),
        .wb_done_flag    (wb_done_flag),

        .raddr1          (raddr1),
        .raddr2          (raddr2),
        .rdata1          (rdata1),
        .rdata2          (rdata2),

        .lsu_to_rf_valid (lsu_to_rf_valid),
        .lsu_to_rf_ready (lsu_to_rf_ready),

        .rf_to_ifu_valid (rf_to_ifu_valid),
        .rf_to_ifu_ready (rf_to_ifu_ready)
    );

    assign out_rdata1          = rdata1_reg;
    assign out_rdata2          = rdata2_reg;
    assign out_wb_done         = wb_done_reg;
    assign out_wb_done_flag    = wb_done_flag_reg;
    assign out_exu_to_rf_ready = exu_to_rf_ready_reg;
    assign out_lsu_to_rf_ready = lsu_to_rf_ready_reg;
    assign out_rf_to_ifu_valid = rf_to_ifu_valid_reg;

endmodule