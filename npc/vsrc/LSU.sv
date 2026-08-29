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

    typedef enum logic [2:0] {
        LSU_IDLE,
        LSU_READ_ADDR,
        LSU_WAIT_R,
        LSU_WRITE_REQ,
        LSU_WAIT_B,
        LSU_DONE
    } lsu_state_t;
    lsu_state_t lsu_state;
    assign out_ready = (lsu_state == LSU_IDLE) && !out_valid;

    always @(posedge clk) begin
        if (reset) begin
            lsu_state <= LSU_IDLE;
        end
        else begin
            case (lsu_state)
                LSU_IDLE: begin
                    if (in_valid && out_ready && in_is_load)
                        lsu_state <= LSU_READ_ADDR;
                    else if (in_valid && out_ready && in_is_store)
                        lsu_state <= LSU_WRITE_REQ;
                end
                LSU_READ_ADDR: begin
                    if (ar_fire)    lsu_state <= LSU_WAIT_R;
                end
                LSU_WAIT_R: begin
                    if (r_fire) lsu_state <= LSU_DONE;
                end
                LSU_WRITE_REQ: begin
                    if (aw_fire && w_fire)  lsu_state <= LSU_WAIT_B;
                end
                LSU_WAIT_B: begin
                    if (b_fire) lsu_state <= LSU_DONE;
                end
                LSU_DONE: begin
                    if (out_valid && in_ready)  lsu_state <= LSU_IDLE;
                end
                default:;
            endcase
        end
    end

    reg [31:0]  mem_addr;
    reg exu_to_lsu_valid_r;
    reg is_load, is_store;
    reg [ 2:0]  load_size, store_size;
    always @(posedge clk) begin
        if (in_valid && out_ready)begin
            is_load <= in_is_load;
            is_store <= in_is_store;
            load_size <= in_load_size;
            store_size <= in_store_size;
            mem_addr <= in_mem_addr;

            out_rd <= in_rd;
            out_src1 <= in_src1;
            out_src2 <= in_src2;
            out_rf_we <= in_rf_we;
            out_redirect_pc <= in_redirect_pc;
            out_redirect_valid <= in_redirect_valid;
        end
    end

    wire    aw_fire, w_fire, ar_fire, b_fire, r_fire;
    assign  aw_fire = axi.awvalid && axi.awready;
    assign  w_fire = axi.wvalid && axi.wready;
    assign  ar_fire = axi.arvalid && axi.arready;
    assign  b_fire = axi.bvalid && axi.bready;
    assign  r_fire = axi.rvalid && axi.rready;
    wire in_fire  = in_valid && out_ready;
    wire out_fire = out_valid && in_ready;

    always @(posedge clk) begin
        if (reset) begin
            out_valid <= 1'b0;
        end
        else if (r_fire || b_fire) begin
            out_valid <= 1'b1;
        end
        else if (in_fire && !in_is_load && !in_is_store) begin
            out_valid <= 1'b1;
        end
        else if (out_fire) begin
            out_valid <= 1'b0;
        end
    end



    ///////////////////////////////////////
    // AR Channel
    ///////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            axi.arvalid <= 1'b0;
        end
        else begin
            if (lsu_state == LSU_IDLE && in_valid && out_ready && in_is_load) begin
                axi.araddr  <= in_mem_addr;
                axi.arvalid <= 1'b1;
            end
            else if (ar_fire) begin
                axi.arvalid <= 1'b0;
            end
        end
    end
    ///////////////////////////////////////
    // R Channel
    ///////////////////////////////////////
    assign axi.rready = (lsu_state == LSU_WAIT_R);

    wire [31:0] word;
    assign word = axi.rdata >> (mem_addr[1:0] * 8);
    always @(posedge clk) begin
        if (r_fire) begin
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
        if (in_fire && !in_is_load && !in_is_store) begin
            out_wb_data <= in_wb_data;
    end
    end

    ///////////////////////////////////////
    // AW Channel
    ///////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            axi.awvalid <= 1'b0;
        end
        else begin
            if (lsu_state == LSU_IDLE && in_valid && out_ready && in_is_store) begin
                axi.awaddr  <= in_mem_addr;
                axi.awvalid <= 1'b1;
            end
            else if (aw_fire) begin
                axi.awvalid <= 1'b0;
            end
        end
    end

    ///////////////////////////////////////
    // W Channel
    ///////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            axi.wvalid <= 1'b0;
        end
        else begin
            if (lsu_state == LSU_IDLE && in_valid && out_ready && in_is_store) begin
                axi.wvalid <= 1'b1;
                case (in_store_size)
                    3'b000: begin //sb
                        axi.wdata <= {4{in_store_data[7:0]}};
                        axi.wstrb <= 4'b0001 << in_mem_addr[1:0];
                    end
                    3'b001: begin //sh
                        axi.wdata <= {16'b0, in_store_data[15:0]} << (in_mem_addr[1:0] * 8);
                        axi.wstrb <= 4'b0011 << in_mem_addr[1:0];
                    end
                    3'b010: begin
                        axi.wdata <= in_store_data;
                        axi.wstrb <= 4'b1111;//sw
                    end
                    default: begin
                        axi.wstrb <= 4'b0;
                        axi.wdata <= in_store_data;
                    end
                endcase
            end
            else if (w_fire) begin
                axi.wvalid <= 1'b0;
                `ifdef CONFIG_MTRACE
                    $display("Write:\t0x%08x", axi.awaddr);
                `endif
            end
        end
    end

    ///////////////////////////////////////
    // B Channel
    ///////////////////////////////////////
   assign axi.bready = (lsu_state == LSU_WAIT_B);
    always @(posedge clk) begin
        if(b_fire) begin
            perf_event(PERF_LSU_STORE);
        end
    end

endmodule
