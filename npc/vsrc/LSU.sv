`include "params.vh"
module LSU(
    input                               clk,
    input                               reset,
    AXI_IF.master                       axi,
    input                               in_rf_we,
    input       reg                     in_is_load,
    input       reg                     in_is_store,
    input       reg     [31:0]          pc,

    input       reg     [31:0]          in_redirect_pc,
    input       reg                     in_redirect_valid,
    input                               in_valid,
    input                               in_ready,

    input       reg     [ 2:0]          in_load_size,
    input               [31:0]          in_mem_addr,
    input       wire    [31:0]          in_store_data,
    input       wire    [31:0]          in_wb_data,

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

    reg     [7:0]   random_num;
    LFSR lfsr(
        .clk(clk),
        .random_num(random_num)
    );

    assign out_ready = 1'b1;
    reg [31:0] lsu_in_mem_addr;


    reg exu_to_lsu_valid_r;
    reg lsu_is_load, lsu_is_store;
    always @(posedge clk) begin
        exu_to_lsu_valid_r <= in_valid;
        out_redirect_valid <= in_redirect_valid;
        if(reset == 1) begin
            lsu_is_load <= 0;
            lsu_is_store <= 0;
            lsu_in_mem_addr <= 0;
            axi.araddr <= 0;
            axi.awaddr <= 0;
            out_rf_we <= 0;
            out_redirect_pc <= 0;
        end
        else if (in_valid)begin
            lsu_is_load <= in_is_load;
            lsu_is_store  <= in_is_store;
            lsu_in_mem_addr <= in_mem_addr; 
            axi.araddr <= in_mem_addr;
            axi.awaddr <= in_mem_addr;
            out_rf_we <= in_rf_we | in_is_load;
            out_redirect_pc <= in_redirect_pc;
        end
    end
    reg     is_busy;
    reg [7:0]   resp_busy;
    parameter IDLE = 1'b0, WAIT = 1'b1;
    reg             lsu_is_valid;
    reg     state, next_state;
    reg     state_l, next_state_l;
    reg     state_w, next_state_w;
    reg     state_aw, next_state_aw;

    reg     is_load_store, store_done, load_done;
    assign out_valid = load_done || 
                            store_done || 
                            out_redirect_valid ||
                            ((~lsu_is_load && ~ lsu_is_store) && exu_to_lsu_valid_r);
    always_comb begin
        case (state_l)
            IDLE: begin
                axi.arvalid = 0;
                if(exu_to_lsu_valid_r && lsu_is_load) begin
                    next_state_l = WAIT;
                end
                else
                    next_state_l = IDLE;
            end
            WAIT: begin
                next_state_l = axi.arready ? IDLE : WAIT;
                axi.arvalid = 1;    
            end
        endcase
    end

    always @(*) begin
        axi.rready = (~is_busy && ~reset);
        if(axi.rvalid && axi.rready && ~is_busy) begin
            perf_event(PERF_LSU_LOAD);
            load_done = 1;
        end
        else
            load_done = 0;
    end
    ///////////////////////////////////////
    //WRITE
    ///////////////////////////////////////
    always_comb begin
        case (state_aw)
            IDLE: begin
                axi.awvalid = 0;
                if(in_valid && in_is_store) begin
                    next_state_aw = WAIT;
                end
                else
                    next_state_aw = IDLE;
            end
            WAIT: begin
                next_state_aw = axi.awready ? IDLE : WAIT;
                axi.awvalid = 1;    
                if(axi.awaddr > 32'h0f002000 && axi.awaddr < 32'h10000000) begin
                    $display("try to write to invalid sram addres: %h", axi.awaddr);
                    $fatal("try to write to invalid sram addres: %h", axi.awaddr);
                end
            end
        endcase
    end

    always_comb begin
        case (state_w)
            IDLE: begin
                axi.wvalid = 0;
                if(in_valid && in_is_store) begin
                    next_state_w = WAIT;
                end
                else
                    next_state_w = 0;
            end
            WAIT: begin
                next_state_w = axi.wready ? IDLE : WAIT;
                axi.wvalid = 1;
            end
        endcase
    end


    always @(posedge clk) begin
        state_aw <= next_state_aw;
        state_w <= next_state_w;
        state_l <= next_state_l;
        `ifdef CONFIG_MTRACE
            if (axi.arvalid && axi.arready)
                $display("Read:\t0x%08x", axi.araddr);
            if (axi.awvalid && axi.awready)
                $display("Write:\t0x%08x", axi.awaddr);
            // if (axi.rvalid && axi.rready)
            //     $display("RData:\t0x%08x", axi.rdata);
            // if (axi.wvalid && axi.wready)
            //     $display("WData:\t0x%08x strb=%b", axi.wdata, axi.wstrb);
        `endif
    end

    always @(*) begin
        axi.bready = (~is_busy && ~reset);
        if(axi.bvalid && axi.bready && ~is_busy) begin
            perf_event(PERF_LSU_STORE);
            store_done = 1;
        end
        else
            store_done = 0;
    end

    always @(posedge clk) begin
        if(reset == 1)
            state <= IDLE;
        else
            state <= next_state;
    end

    reg [7:0] byte1, byte2;
    reg [31:0] word;
    always @(*) begin
        byte1 = 8'b0;
        byte2 = 8'b0;
        word = 32'b0;
        //csr_input_data = 32'b0;
        if(lsu_is_load) begin
            word = (axi.rdata >> (lsu_in_mem_addr[1:0]*8));
            case (in_load_size)
            3'b000: begin
                byte1 = word[7:0];
                out_wb_data = {{24{byte1[7]}}, byte1}; //lb
            end
            3'b001: begin//lh
                {byte2, byte1} = word[15:0];
                out_wb_data = {{16{byte2[7]}}, byte2, byte1};
            end
            3'b010: out_wb_data = word; //lw
            3'b100: out_wb_data = word & 32'hff;//lbu
            3'b101: out_wb_data = word & 32'hffff; //lhu
            default:out_wb_data = 32'b0;
        endcase
        end
        else 
            out_wb_data = in_wb_data;
    end

    always @(posedge clk) begin
        if(in_valid)
        case (in_load_size)
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

endmodule
