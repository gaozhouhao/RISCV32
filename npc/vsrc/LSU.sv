`include "params.vh"
module LSU(
    input                               clk,
    input                               reset,
    input                               exu_we,
    output      reg                     lsu_rf_we,
    input       reg                     is_load,
    input       reg                     is_store,
    input       reg     [31:0]          pc,

    input               [ 1:0]          wb_sel, 
    input       reg     [ 2:0]          funct3,
    
    input               [31:0]          alu_result,
    input       wire    [31:0]          src2_data,
    input       wire    [31:0]          csr_wdata,


    output      reg     [31:0]          wb,
    AXI_IF.master                       axi,
    
    output                              exu_to_lsu_valid,
    output                              exu_to_lsu_ready,
    input                               lsu_to_rf_ready,
    output                              lsu_to_rf_valid,

    input       reg     [31:0]          redirect_pc,
    input       reg                     redirect_valid,
    output      reg     [31:0]          redirect_pc_r,
    output      reg                     redirect_valid_r
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

    assign exu_to_lsu_ready = 1'b1;
    reg [ 1:0] lsu_wb_sel;
    reg [31:0] lsu_alu_result;
    reg [31:0] lsu_csr_wdata;

    reg exu_to_lsu_valid_r;
    reg lsu_is_load, lsu_is_store;
    always @(posedge clk) begin
        exu_to_lsu_valid_r <= exu_to_lsu_valid;
        redirect_valid_r <= redirect_valid;
        if(reset == 1) begin
            lsu_is_load <= 0;
            lsu_is_store <= 0;
            lsu_alu_result <= 0;
            lsu_csr_wdata <= 0;
            axi.araddr <= 0;
            axi.awaddr <= 0;
            lsu_wb_sel <= 0;
            lsu_rf_we <= 0;
            redirect_pc_r <= 0;
        end
        else if (exu_to_lsu_valid)begin
            lsu_is_load <= is_load;
            lsu_is_store  <= is_store;
            lsu_alu_result <= alu_result; 
            lsu_csr_wdata <= csr_wdata;
            axi.araddr <= alu_result;
            axi.awaddr <= alu_result;
            lsu_wb_sel <= wb_sel;
            lsu_rf_we <= exu_we | is_load;
            redirect_pc_r <= redirect_pc;
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
    assign lsu_to_rf_valid = load_done || 
                            store_done || 
                            redirect_valid_r ||
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
                if(exu_to_lsu_valid && is_store) begin
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
                if(exu_to_lsu_valid && is_store) begin
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
            word = (axi.rdata >> (lsu_alu_result[1:0]*8));
            case (funct3)
            3'b000: begin
                byte1 = word[7:0];
                wb = {{24{byte1[7]}}, byte1}; //lb
            end
            3'b001: begin//lh
                {byte2, byte1} = word[15:0];
                wb = {{16{byte2[7]}}, byte2, byte1};
            end
            3'b010: wb = word; //lw
            3'b100: wb = word & 32'hff;//lbu
            3'b101: wb = word & 32'hffff; //lhu
            default:wb = 32'b0;
        endcase
        end
        else case (lsu_wb_sel)
            `NPC_ALU: wb = lsu_alu_result;
            `NPC_PC4: wb = pc + 32'h4;
            `NPC_CSR: begin
            wb = lsu_csr_wdata;
            end
            default: wb = 32'b0;
        endcase
    end

    always @(posedge clk) begin
        if(exu_to_lsu_valid)
        case (funct3)
            3'b000: begin //sb
                axi.wdata <= {4{src2_data[7:0]}};
                axi.wstrb <= 4'b0001 << alu_result[1:0];
            end
            3'b001: begin //sh
                axi.wdata <= {16'b0, src2_data[15:0]} << (alu_result[1:0] * 8);
                axi.wstrb <= 4'b0011 << alu_result[1:0];
            end
            3'b010: begin
                axi.wdata <= src2_data;
                axi.wstrb <= 4'b1111;//sw
            end
            default: begin
                axi.wstrb <= 4'b0;
                axi.wdata <= src2_data;
            end
        endcase
    end

endmodule
