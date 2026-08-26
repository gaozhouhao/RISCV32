module CSR(
    input               [11:0]  csr_addr,
    input                       csr_wen,
    input                       is_ecall,
    input       reg     [31:0]  pc,
    input                       clk,

    output      reg     [31:0]  csr_rdata,
    input       reg     [31:0]  csr_wdata,
    output      reg     [31:0]  mtvec_data,
    output      reg     [31:0]  mepc_data
);

reg     [31:0]      mcycle/* verilator public_flat_rd */;
reg     [31:0]      mcycleh/* verilator public_flat_rd */;
reg     [31:0]      mvendorid/* verilator public_flat_rd */;
reg     [31:0]      marchid/* verilator public_flat_rd */;

reg     [31:0]      mstatus/* verilator public_flat_rd */; //0x300
reg     [31:0]      mtvec/* verilator public_flat_rd */; //0x305
reg     [31:0]      mepc/* verilator public_flat_rd */; //0x341
reg     [31:0]      mcause/* verilator public_flat_rd */; //0x342

initial mvendorid = 32'h79737978;
initial marchid = 32'h17F4E2E;

always @(*) begin
    mtvec_data = mtvec;
    mepc_data = mepc;
end


always @(*) begin
    case (csr_addr)
        12'hB00: csr_rdata = mcycle;
        12'hB80: csr_rdata = mcycleh;
        12'hF11: csr_rdata = mvendorid;
        12'hF12: csr_rdata = marchid;
        12'h300: csr_rdata = mstatus;
        12'h305: csr_rdata = mtvec;
        12'h341: csr_rdata = mepc;
        12'h342: csr_rdata = mcause;
        default: csr_rdata = csr_rdata;
    endcase
end


always @(posedge clk) begin
    if(is_ecall) begin
        mepc <= pc;
        mcause <= 32'd11;
    end
    else if(csr_wen) begin
        case (csr_addr)
            12'hB00: mcycle <= csr_wdata;
            12'hB80: mcycleh <= csr_wdata;
            12'h300: mstatus <= csr_wdata;
            12'h305: mtvec <= csr_wdata;
            12'h341: mepc <= csr_wdata;
            12'h342: mcause <= csr_wdata;
            default: ;
        endcase
    end
    {mcycleh, mcycle} <= {mcycleh, mcycle} + 1'b1;

end


endmodule
