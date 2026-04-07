module IFU(
    input                               is_jalr,
    input                               is_load,
    input                               clk,
    input                               reset,
    output  reg     [31:0]              inst,
    input                               id_done,
    input                               exe_done,
    input                               wb_done,
    output  reg     [31:0]              pc,
    output  reg                         inst_done,

    input   reg     [31:0]              redirect_pc,
    input   reg                         redirect_valid,

    input                               ifu_to_idu_ready,
    output                              ifu_to_idu_valid,
    output                              rf_to_ifu_ready,
    input                               rf_to_ifu_valid,
    output                              csr_to_ifu_ready,
    input                               csr_to_ifu_valid,
    
    input   reg                         ifu_respValid,
    output  reg                         ifu_respReady,
    output  reg                         ifu_reqValid,
    input   reg                         ifu_reqReady,
    output  reg     [31:0]              ifu_raddr,
    input   reg     [31:0]              ifu_rdata
);

reg     [7:0]   random_num;
LFSR lfsr(
    .clk(clk),
    .random_num(random_num)
);

reg     [7:0]   resp_busy;
parameter   IDLE = 2'b00, WAIT_READY = 2'b01, WAIT = 2'b10, BUSY = 2'b11;
reg     [1:0]        state, next_state;

initial pc = 32'h80000000;

reg fetch_req;
assign fetch_req = id_done|exe_done|wb_done;


reg ifu_valid;
initial ifu_valid = 1;
always @(posedge clk) begin
    if(ifu_respValid) inst <= ifu_rdata;
    else inst <= inst;
end

always @(*) begin
    ifu_reqValid = 0;
    ifu_to_idu_valid = 0;
    ifu_respReady = 0;
    case(state)
        IDLE: begin
            next_state = (wb_done || start_up == 0) ? WAIT_READY : IDLE;
            ifu_reqValid = 1;
        end
        WAIT_READY: begin
            next_state = ifu_reqReady ? WAIT : WAIT_READY;
            ifu_reqValid = 1;
        end
        WAIT: begin
            next_state = (ifu_respValid)? BUSY : WAIT;
        end
        BUSY: begin
            next_state = (resp_busy == 1) ? IDLE : BUSY;
            ifu_to_idu_valid = (resp_busy == 1);
            ifu_respReady = (resp_busy == 1);
        end
    endcase
end

always @(*) begin
    ifu_raddr = pc;
    inst_done = is_jalr || wb_done;
end

reg start_up;
always @(posedge clk) begin
    if(reset == 0) begin
        state <= IDLE;
        start_up <= 0;
    end
    else begin
        state <= next_state;
    //if(state == WAIT && ifu_respValid) resp_busy <= random_num + 1;
    if(state == WAIT && ifu_respValid) resp_busy <= 1;
    if(resp_busy > 0) resp_busy <= resp_busy - 1; 
        if((state == IDLE && ifu_to_idu_ready == 1 && wb_done) || start_up == 0) begin
            //ifu_to_idu_valid <= 1'b1;
            start_up <= 1;
        end
        else begin
            //ifu_to_idu_valid <= 0;
        end
    end
end

wire    [31:0]  next_pc;
assign next_pc = redirect_valid ? redirect_pc : pc + 4;

always @(posedge clk) begin
    if(inst_done)
        pc <= next_pc;
    else 
        pc <= pc;
end

endmodule
