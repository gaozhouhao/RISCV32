module IFU(
    input                               is_jalr,
    input                               is_load,
    input                               clk,
    input                               reset,
    input           [31:0]              next_pc,
    output  reg     [31:0]              inst,
    input                               id_done,
    input                               exe_done,
    input                               wb_done,
    output  reg     [31:0]              pc,
    output  reg                         inst_done,

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

parameter   IDLE = 1'b0, WAIT = 1'b1;
reg         state, next_state;

initial pc = 32'h80000000;

reg fetch_req;
assign fetch_req = id_done|exe_done|wb_done;


reg ifu_valid;
initial ifu_valid = 1;
always @(posedge clk) begin
    if(ifu_respValid) inst <= ifu_rdata;
    else inst <= inst;
    ifu_to_idu_valid <= ifu_respValid;
end

always @(*) begin
    case(state)
        IDLE: next_state = wb_done ? WAIT : IDLE;
        WAIT: next_state = (ifu_respValid)? IDLE : WAIT;
    endcase
end

always @(*) begin
    ifu_raddr = pc;
end

always @(posedge clk) begin
    if(reset == 0) begin
        state <= IDLE;
        ifu_reqValid <= 0;
    end
    else begin
        state <= next_state;
    
        if(state == IDLE && ifu_to_idu_ready == 1 && wb_done) begin
            //ifu_to_idu_valid <= 1'b1;
            ifu_reqValid <= 1;
        end
        else begin
            ifu_reqValid <= 0;
            //ifu_to_idu_valid <= 0;
        end
    end
end

always @(posedge clk) begin
    if(is_jalr)
        pc <= next_pc & ~32'b1;
    else if(wb_done && state == IDLE)
        pc <= next_pc;
    else 
        pc <= pc;
end

always @(*) begin
    inst_done = is_jalr || (wb_done && state == IDLE);
end

endmodule
