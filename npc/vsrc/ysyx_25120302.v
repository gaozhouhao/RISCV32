module ysyx_25120302(
    input           clock,
    input           reset,
    input           io_interrupt,
    //output  [31:0]  pc,
    //output          wb_done_flag,
    //output          inst_done
    input           io_master_awready,
    output          io_master_awvalid,
    output  [31:0]  io_master_awaddr,
    output  [ 3:0]  io_master_awid,
    output  [ 7:0]  io_master_awlen,
    output  [ 2:0]  io_master_awsize,
    output  [ 1:0]  io_master_awburst,

    input           io_master_wready,
    output          io_master_wvalid,
    output  [31:0]  io_master_wdata,
    output  [ 3:0]  io_master_wstrb,
    output          io_master_wlast,
    
    output          io_master_bready,
    input           io_master_bvalid,
    input   [ 1:0]  io_master_bresp,
    input   [ 3:0]  io_master_bid,
    
    input           io_master_arready,
    output          io_master_arvalid,
    output  [31:0]  io_master_araddr,
    output  [ 3:0]  io_master_arid,
    output  [ 7:0]  io_master_arlen,
    output  [ 2:0]  io_master_arsize,
    output  [ 1:0]  io_master_arburst,
    
    output          io_master_rready,
    input           io_master_rvalid,
    input   [ 1:0]  io_master_rresp,
    input   [31:0]  io_master_rdata,
    input           io_master_rlast,
    input   [ 3:0]  io_master_rid,

    output          io_slave_awready,
    input           io_slave_awvalid,
    input   [31:0]  io_slave_awaddr,
    input   [ 3:0]  io_slave_awid,
    input   [ 7:0]  io_slave_awlen,
    input   [ 2:0]  io_slave_awsize,
    input   [ 1:0]  io_slave_awburst,

    output          io_slave_wready,
    input           io_slave_wvalid,
    input   [31:0]  io_slave_wdata,
    input   [ 3:0]  io_slave_wstrb,
    input           io_slave_wlast,
    
    input           io_slave_bready,
    output          io_slave_bvalid,
    output  [ 1:0]  io_slave_bresp,
    output  [ 3:0]  io_slave_bid,
    
    output          io_slave_arready,
    input           io_slave_arvalid,
    input   [31:0]  io_slave_araddr,
    input   [ 3:0]  io_slave_arid,
    input   [ 7:0]  io_slave_arlen,
    input   [ 2:0]  io_slave_arsize,
    input   [ 1:0]  io_slave_arburst,
    
    input           io_slave_rready,
    output          io_slave_rvalid,
    output  [ 1:0]  io_slave_rresp,
    output  [31:0]  io_slave_rdata,
    output          io_slave_rlast,
    output  [ 3:0]  io_slave_rid
);
wire    [31:0]  inst;
wire    [31:0]  next_pc;
wire    [31:0]  pc;
AXI_IF          axi_lsu();
AXI_IF          axi_ifu();
AXI_IF          axi_arb();
//AXI_IF          axi_mem();
//AXI_IF          axi_uart();
AXI_IF          axi_clint();

assign  axi_arb.awready = io_master_awready;
assign  io_master_awvalid = axi_arb.awvalid;
assign  io_master_awaddr = axi_arb.awaddr;

assign  axi_arb.wready = io_master_wready;
assign  io_master_wvalid = axi_arb.wvalid;
assign  io_master_wdata = axi_arb.wdata;
assign  io_master_wstrb = axi_arb.wstrb;

assign  io_master_bready = axi_arb.bready;
assign  axi_arb.bvalid = io_master_bvalid;
assign  axi_arb.bresp = io_master_bresp;

assign  axi_arb.arready = io_master_arready;
assign  io_master_arvalid = axi_arb.arvalid;
assign  io_master_araddr = axi_arb.araddr;

assign  io_master_rready = axi_arb.rready;
assign  axi_arb.rresp = io_master_rresp;
assign  axi_arb.rvalid = io_master_rvalid;
assign  axi_arb.rdata = io_master_rdata;


wire            ifu_reqValid;
wire            ifu_reqReady;
wire            ifu_respValid;
wire            ifu_respReady;
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
wire            inst_done;
wire            wb_done_flag;
wire            exe_done;
wire            is_ecall;
wire            is_ebreak;
wire            is_jalr;
wire            is_jal;
wire            is_branch;
wire            is_csr;
wire            is_load;
wire            is_store;
wire            trap_valid;
wire            redirect_valid;
wire            redirect_valid_r;
wire    [31:0]  redirect_pc;
wire    [31:0]  redirect_pc_r;
wire            idu_we;
wire            exu_we;
wire            lsu_rf_we;
wire            sen;
wire            csr_wen;

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

wire    [31:0]  wb;

wire    [2:0]   funct3;

wire    [31:0]  mtvec_data;
wire    [31:0]  mepc_data;
IFU ifu(
    .is_jalr(is_jalr),
    .is_load(is_load),
    .axi(axi_ifu),
    .clk(clock),
    .reset(reset),
    .ifu_to_idu_ready(ifu_to_idu_ready),
    .ifu_to_idu_valid(ifu_to_idu_valid),
    .inst(inst),
    .id_done(id_done),
    .exe_done(exe_done),
    .wb_done(wb_done),
    .inst_done(inst_done),
    .pc(pc),
    .redirect_pc_r(redirect_pc_r),
    .redirect_valid_r(redirect_valid_r),
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
    
    .idu_we(idu_we),
    .sen(sen),
    .csr_wen(csr_wen),
    .is_ecall(is_ecall),
    .is_ebreak(is_ebreak),
    .is_jalr(is_jalr),
    .is_jal(is_jal),
    .is_load(is_load),
    .is_store(is_store),
    .is_branch(is_branch),
    .trap_valid(trap_valid),
    .is_csr(is_csr),
    .id_done(id_done),
    .wb_sel(wb_sel),
    .csr_op_sel(csr_op_sel),
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
    .clk(clock),
    .idu_we(idu_we),
    .exu_we(exu_we),
    .wb_sel(wb_sel),
    .alu_src1_sel(alu_src1_sel),
    .alu_src2_sel(alu_src2_sel),
    .ALUop(ALUop),
    .alu_result(alu_result),
    .branch_taken(branch_taken),
    .csr_op_sel(csr_op_sel),
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .is_branch(is_branch),
    .redirect_valid(redirect_valid),
    .redirect_pc(redirect_pc),
    .trap_valid(trap_valid),
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
    .idu_to_exu_ready(idu_to_exu_ready),
    .idu_to_exu_valid(idu_to_exu_valid),
    .exu_to_lsu_ready(exu_to_lsu_ready),
    .exu_to_lsu_valid(exu_to_lsu_valid)

);
LSU lsu(
    .clk(clock),
    .reset(reset),
    .sen(sen),
    .exu_we(exu_we),
    .lsu_rf_we(lsu_rf_we),
    .is_load(is_load),
    .is_store(is_store),
    .branch_taken(branch_taken),

    .pc(pc),
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
    .axi(axi_lsu),

    .exu_to_lsu_valid(exu_to_lsu_valid),
    .exu_to_lsu_ready(exu_to_lsu_ready),
    .lsu_to_rf_valid(lsu_to_rf_valid),
    .lsu_to_rf_ready(lsu_to_rf_ready),

    .redirect_pc(redirect_pc),
    .redirect_pc_r(redirect_pc_r),
    .redirect_valid(redirect_valid),
    .redirect_valid_r(redirect_valid_r)
);

Arbiter arbiter(
    .clk(clock),
    .reset(reset),
    .axi_ifu(axi_ifu),
    .axi_lsu(axi_lsu),
    .axi_arb(axi_arb.master)
);
/*
Xbar xbar(
    .clk(clock),
    .reset(reset),
    .axi_arb(axi_arb),
    .axi_mem(axi_mem),
    .axi_uart(axi_uart),
    .axi_clint(axi_clint)
);
*/
CLINT clint(
    .clk(clock),
    .reset(reset),
    .axi(axi_clint)    
);
/*
UART uart(
    .clk(clock),
    .reset(reset),
    .axi(axi_uart)    
);

MEM mem(
    .clk(clock),
    .reset(reset),
    .axi(axi_mem)
);
*/
RegisterFile regfile (
    .clk(clock),
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
    .clk(clock),
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
