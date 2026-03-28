module IFU(
    input                               is_jalr,
    input                               is_load,
    input                               clk,
    input           [31:0]              next_pc,
    output  reg     [31:0]              inst,
    input                               id_done,
    input                               exe_done,
    input                               wb_done,
    output  reg     [31:0]              pc,

    input                               ifu_to_idu_ready,
    output                              ifu_to_idu_valid,
    output                              rf_to_ifu_ready,
    input                               rf_to_ifu_valid,
    output                              csr_to_ifu_ready,
    input                               csr_to_ifu_valid,
    
    input   reg                         ifu_respValid,
    output  reg                         ifu_reqValid,
    output  reg     [31:0]              ifu_raddr,
    input   reg     [31:0]              ifu_rdata
);

parameter   idle = 1'b0, wait_ready = 1'b1;
reg         state, next_state;

initial pc = 32'h80000000;


reg fetch_req;
assign fetch_req = id_done|exe_done|wb_done;


reg ifu_valid;
initial ifu_valid = 1;
always @(posedge clk) begin
    ifu_valid <= 0;
end

always @(*) begin
    if(ifu_respValid) inst = ifu_rdata;
    else inst = inst;
    case(state)
        idle: next_state = wait_ready;
        wait_ready: next_state = (rf_to_ifu_valid|ifu_valid)?idle:wait_ready;
    endcase
end

always @(*) begin
    case(state)
        idle: begin
            ifu_raddr = pc;
            ifu_reqValid = 1;
        end
        wait_ready: begin
            ifu_raddr = 0;
            ifu_reqValid = 0;
        end
    endcase
end


always @(posedge clk) begin
    //$display("pc:%x", pc);
    state <= next_state;
    case(next_state)
        wait_ready: begin
            ifu_to_idu_valid <= 1'b1;
        end
        idle: begin
            ifu_to_idu_valid <= 1'b0;
        end
    endcase
end

always @(posedge clk) begin
    if(is_jalr)
        pc <= next_pc & ~32'b1;
    else if(rf_to_ifu_valid)
        pc <= next_pc;
    else 
        pc <= pc;
end

endmodule
