module IFU(
    input                               clk,
    input                               reset,
    AXI_IF.master                       axi,
    
    input                               in_wb_done,
    input   reg     [31:0]              in_redirect_pc,
    input   reg                         in_redirect_valid,
    input                               in_ready,
    input                               in_valid,

    output  reg     [31:0]              pc,
    output  reg     [31:0]              out_inst,
    
    output                              out_valid,
    output                              out_ready
);

    import perf_pkg::*;

    import "DPI-C" function void get_inst(input int inst);

    parameter   IDLE = 1'b0, WAIT = 1'b1;
    reg         state, next_state;

    initial pc = 32'h30000000;

    reg inst_valid;
    wire inst_done/* verilator public_flat_rd */;
    assign inst_done = in_wb_done;
    assign out_ready = (state == IDLE);

    always @(posedge clk) begin
        if (reset == 1) inst_valid <= 1'b0;
            axi.rready <= (~reset);
        if(axi.rvalid & axi.rready) begin
            out_inst <= axi.rdata;
            out_valid <= 1;
            get_inst(axi.rdata);
            perf_event(PERF_IFU_FETCH);
            inst_valid <= 1'b1;
        end
        else begin
            out_inst <= out_inst;
            out_valid <= 0;
            inst_valid <= 1'b0;
        end
    end

    always @(*) begin
        axi.arvalid = 0;
        case(state)
            IDLE: begin
                next_state = (inst_done || start_up == 0) ? WAIT : IDLE;
                axi.arvalid = 0;
            end
            WAIT: begin
            next_state = axi.arready ? IDLE : WAIT;
                axi.arvalid = 1;
            end
        endcase
    end


    always @(*) begin
        axi.araddr = pc;
    end

    reg start_up;
    always @(posedge clk) begin
        if(reset == 1) begin
            state <= IDLE;
            start_up <= 0;
        end
        else begin
            state <= next_state;
            if((state == IDLE && in_ready == 1 && in_wb_done) || start_up == 0) begin
                start_up <= 1;
            end
        end
    end

    wire    [31:0]  next_pc/* verilator public_flat_rd */;
    assign next_pc = in_redirect_valid ? in_redirect_pc : pc + 4;

    always @(posedge clk) begin
        if(inst_done)
            pc <= next_pc;
        else 
            pc <= pc;
    end

endmodule
