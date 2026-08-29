module IFU(
    input                               clk,
    input                               reset,
    AXI_IF.master                       axi,

    input                               in_wb_done,
    input       [31:0]                  in_redirect_pc,
    input                               in_redirect_valid,
    input                               in_ready,
    input                               in_valid,

    output reg  [31:0]                  pc,
    output reg  [31:0]                  out_inst,

    output reg                          out_valid,
    output                              out_ready
);

    import perf_pkg::*;
    import "DPI-C" function void get_inst(input int inst);

    localparam IDLE    = 2'b00;
    localparam SEND_AR = 2'b01;
    localparam WAIT_R  = 2'b10;

    always @(posedge clk) begin
        if (!reset) begin
            perf_event(PERF_CYCLE);

            if (out_valid && !in_ready)
                perf_event(PERF_IFU_STALL);

            if (state == WAIT_R && !(axi.rvalid && axi.rready))
                perf_event(PERF_IFU_MEM_WAIT);
        end
    end


    reg [1:0] state;
    reg start_up;

    wire inst_done;
    assign inst_done = in_wb_done;
    assign out_ready = (state == IDLE);
    assign axi.araddr  = pc;
    assign axi.arvalid = (state == SEND_AR);
    assign axi.rready = (state == WAIT_R) && (!out_valid || in_ready);



    always @(posedge clk) begin
        if (reset) begin
            state    <= IDLE;
            start_up <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (!start_up || inst_done) begin
                        state    <= SEND_AR;
                        start_up <= 1'b1;
                    end
                end
                SEND_AR: begin
                    if (axi.arvalid && axi.arready)
                        state <= WAIT_R;
                end
                WAIT_R: begin
                    if (axi.rvalid && axi.rready)
                        state <= IDLE;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            out_valid <= 1'b0;
            out_inst  <= 32'b0;
        end
        else begin
            if (axi.rvalid && axi.rready) begin
                out_inst  <= axi.rdata;
                out_valid <= 1'b1;
                get_inst(axi.rdata);
                perf_event(PERF_IFU_FETCH);
            end
            else if (out_valid && in_ready) begin
                out_valid <= 1'b0;
            end
        end
    end

    wire [31:0] next_pc;

    assign next_pc = in_redirect_valid ? in_redirect_pc : pc + 32'd4;

    always @(posedge clk) begin
        if (reset)
            pc <= 32'h30000000;
        else if (inst_done)
            pc <= next_pc;
    end



endmodule

