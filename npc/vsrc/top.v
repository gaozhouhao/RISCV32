module top(
    input   clk,
    input   reset,
    output  [31:0]  pc
);

wire    [31:0]  inst;
wire    [31:0]  next_pc;

wire            ifu_reqValid;
wire            ifu_respValid;
wire    [31:0]  ifu_raddr;
wire    [31:0]  ifu_rdata;

wire            ifu_to_idu_ready;
wire            ifu_to_idu_valid;
wire            idu_to_exu_ready;
wire            idu_to_exu_valid;
wire            exu_to_rf_ready;
wire            exu_to_rf_valid;
wire            exu_to_lsu_valid;
wire            exu_to_lsu_ready;
wire            lsu_to_rf_valid;
wire            lsu_to_rf_ready;
wire            rf_to_ifu_valid;
wire            rf_to_ifu_ready;

wire            exu_to_csr_valid;
wire            exu_to_csr_ready;
wire            csr_to_ifu_valid;
wire            csr_to_ifu_ready;

wire            id_done;
wire            wb_done;
wire            wb_done_flag;
wire            exe_done;
wire            is_ecall;
wire            is_ebreak;
wire            is_jalr;
wire            is_csr;
wire            is_load;
wire            is_store;
wire            idu_we;
wire            exu_we;
wire            lsu_rf_we;
wire            sen;
wire            csr_wen;

wire    [2:0]   nextpc_sel;
wire    [1:0]   wb_sel;
wire            csr_op_sel;
wire    [1:0]   alu_src1_sel;
wire    [1:0]   alu_src2_sel;
wire    [3:0]   ALUop;
wire    [31:0]  alu_result;

wire            branch_taken;

wire    [4:0]   src1;
wire    [4:0]   src2;
wire    [4:0]   rd;
wire    [31:0]  imm;
wire    [31:0]  shamt;
wire    [11:0]  csr_addr;

wire    [31:0]  src1_data;
wire    [31:0]  src2_data;
reg     [31:0]  csr_output_data;
reg     [31:0]  csr_input_data;

wire            lsu_reqValid;
wire            lsu_respValid;
reg     [31:0]  lsu_rdata;
reg     [31:0]  lsu_addr;
wire            lsu_wen;
reg     [31:0]  lsu_wdata;
reg     [ 3:0]  lsu_wmask;

wire    [31:0]  wb;

wire    [2:0]   funct3;

wire    [31:0]  mtvec_data;
wire    [31:0]  mepc_data;
IFU ifu(
    .is_jalr(is_jalr),
    .is_load(is_load),
    .clk(clk),
    .reset(reset),
    .next_pc(next_pc),
    .ifu_to_idu_ready(ifu_to_idu_ready),
    .ifu_to_idu_valid(ifu_to_idu_valid),
    .inst(inst),
    .id_done(id_done),
    .exe_done(exe_done),
    .wb_done(wb_done),
    .pc(pc),
    .ifu_reqValid(ifu_reqValid),
    .ifu_respValid(ifu_respValid),
    .ifu_raddr(ifu_raddr),
    .ifu_rdata(ifu_rdata),
    .rf_to_ifu_valid(rf_to_ifu_valid),
    .rf_to_ifu_ready(rf_to_ifu_ready),
    .csr_to_ifu_valid(csr_to_ifu_valid),
    .csr_to_ifu_ready(csr_to_ifu_ready)
);

IDU idu(
    .pc(pc),
    .inst(inst),
    .ifu_to_idu_valid(ifu_to_idu_valid),
    .ifu_to_idu_ready(ifu_to_idu_ready),
    .idu_to_exu_ready(idu_to_exu_ready),
    .idu_to_exu_valid(idu_to_exu_valid),
    //.idu_to_lsu_ready(idu_to_lsu_ready),
    //.idu_to_lsu_valid(idu_to_lsu_valid),
    
    .idu_we(idu_we),
    .sen(sen),
    .csr_wen(csr_wen),
    .is_ecall(is_ecall),
    .is_ebreak(is_ebreak),
    .is_jalr(is_jalr),
    .is_load(is_load),
    .is_store(is_store),
    .is_csr(is_csr),
    .id_done(id_done),
    .wb_sel(wb_sel),
    .csr_op_sel(csr_op_sel),
    .nextpc_sel(nextpc_sel),
    .alu_src1_sel(alu_src1_sel),
    .alu_src2_sel(alu_src2_sel),
    .ALUop(ALUop),
    .funct3(funct3),
    .src1(src1),
    .src2(src2),
    .rd(rd),
    .imm(imm),
    .shamt(shamt),
    .csr_addr(csr_addr)
);

EXU exu(
    .clk(clk),
    .nextpc_sel(nextpc_sel),
    .idu_we(idu_we),
    .exu_we(exu_we),
    .wb_sel(wb_sel),
    .alu_src1_sel(alu_src1_sel),
    .alu_src2_sel(alu_src2_sel),
    .ALUop(ALUop),
    .alu_result(alu_result),
    .branch_taken(branch_taken),
    .csr_op_sel(csr_op_sel),
    .is_ebreak(is_ebreak),
    .is_csr(is_csr),
    .is_load(is_load),
    .is_store(is_store),
    .pc(pc),
    .src1_data(src1_data),
    .src2_data(src2_data),
    .csr_input_data(csr_input_data),
    .csr_output_data(csr_output_data),
    .mtvec_data(mtvec_data),
    .mepc_data(mepc_data),
    .rd(rd),
    .imm(imm),
    .shamt(shamt),
    .wb(wb),
    .sen(sen),
    .funct3(funct3),
    .next_pc(next_pc),
    .idu_to_exu_ready(idu_to_exu_ready),
    .idu_to_exu_valid(idu_to_exu_valid),
    .exu_to_rf_ready(exu_to_rf_ready),
    .exu_to_rf_valid(exu_to_rf_valid),
    .exu_to_lsu_ready(exu_to_lsu_ready),
    .exu_to_lsu_valid(exu_to_lsu_valid)

);
LSU lsu(
    .clk(clk),
    .sen(sen),
    .exu_we(exu_we),
    .lsu_rf_we(lsu_rf_we),
    .is_load(is_load),
    .is_store(is_store),
    .branch_taken(branch_taken),

    .pc(pc),
    .next_pc(next_pc),
    .nextpc_sel(nextpc_sel),
    .funct3(funct3),
    .alu_result(alu_result),
    .wb(wb),
    .wb_sel(wb_sel),
    .src1_data(src1_data),
    .src2_data(src2_data),
    
    .csr_op_sel(csr_op_sel), 
    .csr_input_data(csr_input_data),
    .csr_output_data(csr_output_data),
    .mtvec_data(mtvec_data),
    .mepc_data(mepc_data),
    .lsu_reqValid(lsu_reqValid),
    .lsu_respValid(lsu_respValid),
    .lsu_rdata(lsu_rdata),
    .lsu_addr(lsu_addr),
    .lsu_wen(lsu_wen),
    .lsu_wdata(lsu_wdata),
    .lsu_wmask(lsu_wmask),

    .exu_to_lsu_valid(exu_to_lsu_valid),
    .exu_to_lsu_ready(exu_to_lsu_ready),
    .lsu_to_rf_valid(lsu_to_rf_valid),
    .lsu_to_rf_ready(lsu_to_rf_ready)
);

MEM mem(
    .clk(clk),
    .ifu_reqValid(ifu_reqValid),
    .ifu_respValid(ifu_respValid),
    .ifu_raddr(ifu_raddr),
    .ifu_rdata(ifu_rdata),
    .lsu_reqValid(lsu_reqValid),
    .lsu_respValid(lsu_respValid),
    .lsu_rdata(lsu_rdata),
    .lsu_addr(lsu_addr),
    .lsu_wen(lsu_wen),
    .lsu_wdata(lsu_wdata),
    .lsu_wmask(lsu_wmask)
);

RegisterFile regfile (
    .clk(clk),
    .reset(reset),
    .wdata(wb),
    .waddr(rd),
    .lsu_rf_we(lsu_rf_we),
    .wb_done(wb_done),
    .wb_done_flag(wb_done_flag),
    .raddr1(src1),
    .raddr2(src2),
    .rdata1(src1_data),
    .rdata2(src2_data),
    .exu_to_rf_valid(exu_to_rf_valid),
    .exu_to_rf_ready(exu_to_rf_ready),
    .lsu_to_rf_valid(lsu_to_rf_valid),
    .lsu_to_rf_ready(lsu_to_rf_ready),
    .rf_to_ifu_valid(rf_to_ifu_valid),
    .rf_to_ifu_ready(rf_to_ifu_ready)
);

CSR csr (
    .clk(clk),
    .pc(pc),
    .csr_addr(csr_addr),
    .csr_wen(csr_wen),
    .is_ecall(is_ecall),
    .csr_output_data(csr_output_data),
    .csr_input_data(csr_input_data),
    .mtvec_data(mtvec_data),
    .mepc_data(mepc_data),
    .exu_to_csr_valid(exu_to_csr_valid),
    .exu_to_csr_ready(exu_to_csr_ready),
    .csr_to_ifu_valid(csr_to_ifu_valid),
    .csr_to_ifu_ready(csr_to_ifu_ready)
);


endmodule
