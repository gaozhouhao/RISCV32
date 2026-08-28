`include "params.vh"
module LSU(
    input                               clk,
    input                               reset,
    input       reg     [31:0]          pc,
    AXI_IF.master                       axi,
    input                               in_rf_we,
    input       reg                     in_is_load,
    input       reg                     in_is_store,
    
    input               [ 4:0]          in_src1,
    input               [ 4:0]          in_src2,
    input               [ 4:0]          in_rd,
    input       reg     [31:0]          in_redirect_pc,
    input       reg                     in_redirect_valid,
    input                               in_valid,
    input                               in_ready,

    input       reg     [ 2:0]          in_load_size,
    input       reg     [ 2:0]          in_store_size,
    input               [31:0]          in_mem_addr,
    input       wire    [31:0]          in_store_data,
    input       wire    [31:0]          in_wb_data,

    output              [ 4:0]          out_rd,
    output              [ 4:0]          out_src1,
    output              [ 4:0]          out_src2,
    output      reg     [31:0]          out_wb_data,
    output      reg                     out_rf_we,
    output                              out_valid,
    output                              out_ready,
    output      reg     [31:0]          out_redirect_pc,
    output      reg                     out_redirect_valid
);

    import perf_pkg::*;

    import "DPI-C" function int unsigned pmem_read(input int unsigned  raddr);
    import "DPI-C" function void pmem_write(
        input int unsigned waddr, input int unsigned wdata, input byte wmask);

    assign out_ready = (state_l == IDLE) && (state_w == IDLE) && (state_aw == IDLE);
    reg         lsu_valid;
    reg [31:0]  mem_addr;
    reg [31:0]  store_data;
    reg exu_to_lsu_valid_r;
    reg is_load, is_store;
    reg [ 2:0]  load_size, store_size;
    always @(posedge clk) begin
        if (in_valid && out_ready)begin
            lsu_valid <= 1'b1;
            is_load <= in_is_load;
            is_store <= in_is_store;
            load_size <= in_load_size;
            store_size <= in_store_size;
            mem_addr <= in_mem_addr;
            store_data <= in_store_data;
            out_rd <= in_rd;
            out_src1 <= in_src1;
            out_src2 <= in_src2;
            out_rf_we <= in_rf_we;
            out_redirect_pc <= in_redirect_pc;
            out_redirect_valid <= in_redirect_valid;
        end
        if (out_valid && in_ready)
            lsu_valid <= 1'b0;
    end

    parameter IDLE = 1'b0, WAIT = 1'b1;
    reg     state_l;
    reg     state_w;
    reg     state_aw;

    wire    store_fire, load_fire;
    assign  store_fire = axi.bvalid && axi.bready;
    assign  load_fire = axi.rvalid && axi.rready;
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            out_valid <= 1'b0;
        end
        else if (load_fire || store_fire) begin
            out_valid <= 1'b1;
        end
        else if (~in_is_load && ~in_is_store) begin
            out_valid <= in_valid;
        end
        else if (out_valid && in_ready) begin
            out_valid <= 1'b0;
        end
    end

    ///////////////////////////////////////
    // AR Channel
    ///////////////////////////////////////
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            state_l <= IDLE;
        end
        else begin
            case (state_l)
                IDLE: begin
                    if (lsu_valid && is_load) begin
                        axi.arvalid <= 1'b1;
                        axi.araddr <= mem_addr;
                        state_l <= WAIT;
                    end
                end
                WAIT: begin
                    if (axi.arvalid && axi.arready) begin
                        axi.arvalid <= 1'b0;
                        state_l <= IDLE;
                    end
                end
            endcase
        end
    end
    ///////////////////////////////////////
    // R Channel
    ///////////////////////////////////////
    wire [31:0] word;
    assign word = axi.rdata >> (mem_addr[1:0] * 8);
    assign axi.rready = (state_l == IDLE);
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            out_wb_data <= 32'b0;
        end
        else if (is_load == 1'b1)begin
            if (axi.rvalid && axi.rready) begin
                `ifdef CONFIG_MTRACE
                    $display("Read:\t0x%08x", axi.araddr);
                `endif
                perf_event(PERF_LSU_LOAD);
                case (load_size)
                    3'b000: out_wb_data <= {{24{word[7]}}, word[7:0]}; //lb
                    3'b001: out_wb_data <= {{16{word[15]}}, word[15:0]};//lh
                    3'b010: out_wb_data <= word; //lw
                    3'b100: out_wb_data <= word & 32'hff;//lbu
                    3'b101: out_wb_data <= word & 32'hffff; //lhu
                    default:out_wb_data <= 32'b0;
                endcase
            end
        end
        else begin
            out_wb_data <= in_wb_data;
        end
    end

    ///////////////////////////////////////
    // AW Channel
    ///////////////////////////////////////
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            state_aw <= IDLE;
        end
        else begin
            case (state_aw)
                IDLE: begin
                    if (lsu_valid && is_store) begin
                        axi.awvalid <= 1'b1;
                        axi.awaddr <= mem_addr;
                        state_aw <= WAIT;
                    end
                end
                WAIT: begin
                    if (axi.awvalid && axi.awready) begin
                        axi.awvalid <= 1'b0;
                        state_aw <= IDLE;
                        if(axi.awaddr > 32'h0f002000 && axi.awaddr < 32'h10000000) begin
                            $display("try to write to invalid sram addres: %h", axi.awaddr);
                            $fatal("try to write to invalid sram addres: %h", axi.awaddr);
                        end
                    end
                end
            endcase
        end
    end

    ///////////////////////////////////////
    // W Channel
    ///////////////////////////////////////
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            state_w <= IDLE;
        end
        else begin
            case (state_w)
                IDLE: begin
                    if(lsu_valid && is_store) begin
                        axi.wvalid <= 1'b1;
                        case (store_size)
                            3'b000: begin //sb
                                axi.wdata <= {4{store_data[7:0]}};
                                axi.wstrb <= 4'b0001 << mem_addr[1:0];
                            end
                            3'b001: begin //sh
                                axi.wdata <= {16'b0, store_data[15:0]} << (mem_addr[1:0] * 8);
                                axi.wstrb <= 4'b0011 << mem_addr[1:0];
                            end
                            3'b010: begin
                                axi.wdata <= store_data;
                                axi.wstrb <= 4'b1111;//sw
                            end
                            default: begin
                                axi.wstrb <= 4'b0;
                                axi.wdata <= store_data;
                            end
                        endcase
                        state_w <= WAIT;
                    end
                end
                WAIT: begin
                    if (axi.wvalid && axi.wready) begin
                    `ifdef CONFIG_MTRACE
                        $display("Write:\t0x%08x", axi.awaddr);
                    `endif
                        axi.wvalid <= 1'b0;
                        state_w <= IDLE;
                    end
                end
            endcase
        end
    end

    ///////////////////////////////////////
    // B Channel
    ///////////////////////////////////////
    assign axi.bready = (state_aw == IDLE) && (state_w == IDLE);
    always @(posedge clk) begin
        if(axi.bvalid && axi.bready) begin
            perf_event(PERF_LSU_STORE);
        end
    end

endmodule
