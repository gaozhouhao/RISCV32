`include "params.vh"
module IFU(
    input                   clk,
    input                   reset,
    AXI_IF.master           axi,

    input                   in_fencei_done,
    input       [31:0]      in_redirect_pc,
    input                   in_redirect_fire,
    input                   in_ready,

    output reg  [31:0]      out_pc/* verilator public_flat_rd */,
    output reg  [31:0]      out_inst,
    output reg              out_icache_flush,

    output                  out_valid/* verilator public_flat_rd */,

    output reg              out_exception_valid,
    output reg  [31:0]      out_exception_cause
);

`ifdef VERILATOR
    import perf_pkg::*;
    import "DPI-C" function void get_inst(input int inst);
`endif

`ifdef VERILATOR
    always @(posedge clk) begin
        if (!reset) begin
            perf_event(PERF_CYCLE);
            if (out_valid && !in_ready)
                perf_event(PERF_IFU_STALL);
            if (axi_state == AXI_WAIT_R && !(axi.rvalid && axi.rready))
                perf_event(PERF_IFU_MEM_WAIT);
            if (axi.rvalid && axi.rready)begin
                get_inst(axi.rdata);
                perf_event(PERF_IFU_FETCH);
            end
        end
    end

    always @(posedge clk) begin
        if (!reset && ifu_out_fire) begin
            // $display(
            //     "[PIPE] stage=IFU->IDU pc=%08x inst=%08x valid=%b ready=%b time=%0t",
            //     out_pc, out_inst, out_valid, in_ready, $time
            // );

            if (!out_exception_valid &&
                ((out_pc == 32'h00000000) ||
                (out_inst == 32'h00000000))) begin
                $error(
                    "[PIPE ERROR] stage=IFU->IDU pc=%08x inst=%08x valid=%b ready=%b time=%0t",
                    out_pc, out_inst, out_valid, in_ready, $time
                );
                $fatal(1);
            end
        end
    end

    always @(posedge clk) begin
        if (!reset && ifu_r_fire) begin
            // $display(
            //     "[PIPE] stage=IFU-AXI-R pc=%08x inst=%08x valid=%b ready=%b time=%0t",
            //     fetch_pc, axi.rdata, axi.rvalid, axi.rready, $time
            // );

            if ((fetch_pc == 32'h00000000) ||
                (axi.rdata == 32'h00000000)) begin
                $error(
                    "[PIPE ERROR] stage=IFU-AXI-R pc=%08x inst=%08x valid=%b ready=%b time=%0t",
                    fetch_pc, axi.rdata, axi.rvalid, axi.rready, $time
                );
                $fatal(1);
            end
        end
    end
`endif

    reg exception_pending;
    wire fetch_pc_misaligned = |fetch_pc[1:0];

    wire ifu_out_fire;
    assign ifu_out_fire = out_valid && in_ready;
    wire ifu_ar_fire = axi.arvalid && axi.arready;
    wire ifu_r_fire  = axi.rvalid && axi.rready;

    reg [31:0] outstanding_pc;
    reg outstanding_stale;

    wire drop_response = ifu_r_fire && (outstanding_stale || in_redirect_fire);

    typedef enum logic [1:0] {
        AXI_IDLE,
        AXI_SEND_AR,
        AXI_WAIT_R
    } axi_state_t;
    axi_state_t axi_state;

    reg [31:0] fetch_pc;
    assign axi.araddr  = outstanding_pc;
    assign axi.arvalid = (axi_state == AXI_SEND_AR);
    assign axi.rready = (axi_state == AXI_WAIT_R) && (!out_valid || in_ready);

    
    always @(posedge clk) begin
        if (reset) begin
            axi_state    <= AXI_IDLE;
            outstanding_pc <= `RESET_PC;
            outstanding_stale <= 1'b0;
        end
        else begin
            case (axi_state)
                AXI_IDLE: begin
                    outstanding_stale <= 1'b0;
                    if (ifu_state == IFU_EMPTY &&
                        fencei_state == FENCEI_IDLE &&
                        !in_fencei_done &&
                        !in_redirect_fire &&
                        !fetch_pc_misaligned &&
                        !exception_pending) begin
                        axi_state    <= AXI_SEND_AR;
                        outstanding_pc <= fetch_pc;
                    end
                end
                AXI_SEND_AR: begin
                    if (in_redirect_fire) begin
                        outstanding_stale <= 1'b1;
                    end
                    if (ifu_ar_fire)
                        axi_state <= AXI_WAIT_R;
                end
                AXI_WAIT_R: begin
                    if (ifu_r_fire) begin
                        axi_state <= AXI_IDLE;
                        outstanding_stale <= 1'b0;
                    end
                    else if (in_redirect_fire) begin
                        outstanding_stale <= 1'b1;
                    end
                end
                default: ;
            endcase
        end
    end


    typedef enum logic {
        FENCEI_IDLE,
        FENCEI_BUSY
    } fencei_state_t;
    fencei_state_t fencei_state;

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            fencei_state <= FENCEI_IDLE;
            out_icache_flush <= 1'b0;
        end
        else begin
            case (fencei_state)
                FENCEI_IDLE: begin
                    if (in_fencei_done) begin
                        fencei_state <= FENCEI_BUSY;
                        out_icache_flush <= 1'b1;
                    end
                end
                FENCEI_BUSY: begin
                    fencei_state <= FENCEI_IDLE;
                    out_icache_flush <= 1'b0;
                end
            endcase
        end
    end
    


    typedef enum logic {
        IFU_EMPTY,
        IFU_VALID
    } ifu_state_t;
    ifu_state_t ifu_state;

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            ifu_state <= IFU_EMPTY;

            fetch_pc <= `RESET_PC;
            out_pc <= 32'b0;
            out_inst <= 32'b0;
            out_exception_valid <= 1'b0;
            out_exception_cause <= 32'b0;
            exception_pending <= 1'b0;
        end
        else if (in_redirect_fire) begin
            ifu_state <= IFU_EMPTY;
            fetch_pc <= in_redirect_pc;
            out_exception_valid <= 1'b0;
            out_exception_cause <= 32'b0;
            exception_pending <= 1'b0;
        end
        else begin
            case (ifu_state)
                IFU_EMPTY: begin
                    if (fetch_pc_misaligned && !exception_pending) begin
                        ifu_state           <= IFU_VALID;
                        out_pc              <= fetch_pc;
                        out_inst            <= 32'b0;
                        out_exception_valid <= 1'b1;
                        out_exception_cause <= 32'd0;
                        exception_pending   <= 1'b1;
                    end
                    else if (ifu_r_fire) begin
                        if (drop_response) begin
                            ifu_state <= IFU_EMPTY;
                        end
                        else begin
                            ifu_state <= IFU_VALID;
                            fetch_pc <= outstanding_pc + 32'd4;
                            out_inst  <= axi.rdata;
                            out_pc <= outstanding_pc;
                            out_exception_valid <= 1'b0;
                            out_exception_cause <= 32'b0;
                        end
                    end
                end
                IFU_VALID: begin
                    if (ifu_out_fire) begin
                        ifu_state <= IFU_EMPTY;
                        out_exception_valid <= 1'b0;
                    end
                end
            endcase
        end 
    end

    assign out_valid = (ifu_state == IFU_VALID) && !in_redirect_fire;
    wire ifu_empty /* verilator public_flat_rd */;
    assign ifu_empty = (ifu_state == IFU_EMPTY);

endmodule
