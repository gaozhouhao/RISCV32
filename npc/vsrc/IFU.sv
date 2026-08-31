`include "params.vh"
module IFU(
    input                               clk,
    input                               reset,
    AXI_IF.master                       axi,

    input                               in_wb_done,
    input       [31:0]                  in_redirect_pc,
    input                               in_redirect_valid,
    input                               in_ready,
    input                               in_valid,

    output reg  [31:0]                  pc/* verilator public_flat_rd */,
    output reg  [31:0]                  out_inst,

    output reg                          out_valid/* verilator public_flat_rd */,
    output                              out_ready
);

`ifdef VERILATOR
    import perf_pkg::*;
    import "DPI-C" function void get_inst(input int inst);
`endif


// `ifdef ARCH_NPC
//     
//     import "DPI-C" function int unsigned pmem_read(input int unsigned  raddr);

//     reg start_up;
//     assign out_ready = !reset;

//     always @(posedge clk) begin
//         if (reset == 1'b1) begin
//             out_valid <= 1'b0;
//             start_up <= 1'b0;
//         end
//         else begin
//             start_up <= 1'b1;
//             if (allow_fetch) begin
//                 out_valid <= 1'b1;
//                 get_inst(pmem_read(fetch_pc));
//                 out_inst <= pmem_read(fetch_pc);
//             end
//             else if (out_valid && in_ready) begin
//                 out_valid <= 1'b0;
//             end
//         end
//     end

// `elsif ARCH_YSYXSOC

    localparam IDLE    = 2'b00;
    localparam SEND_AR = 2'b01;
    localparam WAIT_R  = 2'b10;
`ifdef VERILATOR
    always @(posedge clk) begin
        if (!reset) begin
            perf_event(PERF_CYCLE);
            if (out_valid && !in_ready)
                perf_event(PERF_IFU_STALL);
            if (state == WAIT_R && !(axi.rvalid && axi.rready))
                perf_event(PERF_IFU_MEM_WAIT);
        end
    end
`endif

    reg [1:0] state;
    reg start_up;

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
                    if (allow_fetch) begin
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
                `ifdef VERILATOR
                    get_inst(axi.rdata);
                    perf_event(PERF_IFU_FETCH);
                `endif
            end
            else if (out_valid && in_ready) begin
                out_valid <= 1'b0;
            end
        end
    end
    
// `endif


    wire allow_fetch/* verilator public_flat_rd */;
    wire inst_done/* verilator public_flat_rd */;
    assign inst_done = in_wb_done;
    assign allow_fetch = in_wb_done || !start_up;

    wire [31:0] next_pc/* verilator public_flat_rd */;

    assign next_pc = in_redirect_valid ? in_redirect_pc : pc + 32'd4;
    wire [31:0] fetch_pc;
    assign fetch_pc = in_wb_done ? next_pc : pc;

    always @(posedge clk) begin
        if (reset) begin
            pc <= `RESET_PC;
        end
        else if (inst_done) begin
            pc <= next_pc;

        end
    end



endmodule

