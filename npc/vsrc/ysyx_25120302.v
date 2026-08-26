module ysyx_25120302(
    input           clock,
    input           reset,
    input           io_interrupt,

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
wire    [31:0]  inst/* verilator public_flat_rd */;
wire    [31:0]  idu_to_exu_inst/* verilator public_flat_rd */;
wire    [31:0]  next_pc/* verilator public_flat_rd */;
wire    [31:0]  pc/* verilator public_flat_rd */;
AXI_IF          axi_lsu();
AXI_IF          axi_ifu();
AXI_IF          axi_soc();
//AXI_IF          axi_mem();
//AXI_IF          axi_uart();
AXI_IF          axi_clint();

assign axi_soc.awready   = io_master_awready;
assign io_master_awvalid = axi_soc.awvalid;
assign io_master_awaddr  = axi_soc.awaddr;

assign axi_soc.wready   = io_master_wready;
assign io_master_wvalid = axi_soc.wvalid;
assign io_master_wdata  = axi_soc.wdata;
assign io_master_wstrb  = axi_soc.wstrb;
assign io_master_wlast  = 1'b1;

assign io_master_bready = axi_soc.bready;
assign axi_soc.bvalid   = io_master_bvalid;
assign axi_soc.bresp    = io_master_bresp;

assign axi_soc.arready   = io_master_arready;
assign io_master_arvalid = axi_soc.arvalid;
assign io_master_araddr  = axi_soc.araddr;

assign io_master_rready = axi_soc.rready;
assign axi_soc.rresp    = io_master_rresp;
assign axi_soc.rvalid   = io_master_rvalid;
assign axi_soc.rdata    = io_master_rdata;


wire            ifu_reqValid;
wire            ifu_reqReady;
wire            ifu_respValid;
wire            ifu_respReady;
wire    [31:0]  ifu_raddr;
wire    [31:0]  ifu_rdata;

wire            ifu_to_idu_valid;
wire            idu_to_ifu_ready;

wire            exu_to_idu_ready;

wire            exu_to_lsu_valid;
wire            exu_to_lsu_ready;
wire            lsu_to_rf_valid;
wire            lsu_to_rf_ready;
wire            rf_to_ifu_valid;
wire            rf_to_ifu_ready;

wire            wb_done;
wire            wb_done_flag;

wire            redirect_valid;
wire            redirect_valid_r;
wire    [31:0]  redirect_pc;
wire    [31:0]  redirect_pc_r;
wire            rf_we;
wire            exu_we;
wire            lsu_rf_we;
wire            lsu_csr_wen;
wire            csr_wen;

wire    [1:0]   wb_sel;
wire            csr_op_sel;
wire            lsu_csr_op_sel;
wire    [1:0]   alu_src1_sel;
wire    [1:0]   alu_src2_sel;
wire    [3:0]   alu_op;
wire    [31:0]  alu_result;

wire            branch_taken;

wire    [4:0]   src1;
wire    [4:0]   src2;
wire    [4:0]   rd;
wire    [31:0]  imm;
wire    [31:0]  shamt;
wire    [11:0]  csr_addr;

wire    [31:0]  rf_src1_data;
wire    [31:0]  rf_src2_data;
reg     [31:0]  csr_rdata;
reg     [31:0]  csr_wdata;

wire    [31:0]  wb;

wire    [2:0]   funct3;

wire    [31:0]  mtvec_data;
wire    [31:0]  _data;

// IDU Output
wire            idu_valid;
wire            idu_rf_we;
wire            idu_csr_wen;
wire    [ 1:0]  idu_wb_sel;
wire            idu_csr_op_sel;
wire            idu_is_ecall;
wire            idu_is_mret;
wire            idu_is_ebreak;
wire            idu_is_jalr;
wire            idu_is_jal;
wire            idu_is_branch;
wire            idu_is_csr;
wire            idu_is_load;
wire            idu_is_store;
wire            idu_trap_valid;
wire    [ 2:0]  idu_branch_op;
wire    [ 3:0]  idu_alu_op;
wire    [ 1:0]  idu_alu_src2_sel;
wire    [ 1:0]  idu_alu_src1_sel;
wire    [ 4:0]  idu_src1;
wire    [ 4:0]  idu_src2;
wire    [ 4:0]  idu_rd;
wire    [31:0]  idu_imm;
wire    [31:0]  idu_shamt;
wire    [11:0]  idu_csr_addr;
wire    [31:0]  idu_src1_data;
wire    [31:0]  idu_src2_data;

// IDU to EXU Output
wire            idu_to_exu_valid;
wire            idu_to_exu_rf_we;
wire            idu_to_exu_csr_wen;
wire    [ 1:0]  idu_to_exu_wb_sel;
wire            idu_to_exu_csr_op_sel;
wire            idu_to_exu_is_ecall;
wire            idu_to_exu_is_mret;
wire            idu_to_exu_is_ebreak;
wire            idu_to_exu_is_jalr;
wire            idu_to_exu_is_jal;
wire            idu_to_exu_is_branch;
wire            idu_to_exu_is_csr;
wire            idu_to_exu_is_load;
wire            idu_to_exu_is_store;
wire            idu_to_exu_trap_valid;
wire    [ 2:0]  idu_to_exu_branch_op;
wire    [ 3:0]  idu_to_exu_alu_op;
wire    [ 1:0]  idu_to_exu_alu_src2_sel;
wire    [ 1:0]  idu_to_exu_alu_src1_sel;
wire    [ 4:0]  idu_to_exu_src1;
wire    [ 4:0]  idu_to_exu_src2;
wire    [ 4:0]  idu_to_exu_rd;
wire    [31:0]  idu_to_exu_imm;
wire    [31:0]  idu_to_exu_shamt;
wire    [11:0]  idu_to_exu_csr_addr;
wire    [31:0]  idu_to_exu_src1_data;
wire    [31:0]  idu_to_exu_src2_data;

wire exu_is_load;
wire exu_is_store;
IFU ifu(
    .axi(axi_ifu),
    .clk(clock),
    .reset(reset),
    .in_ready(idu_to_ifu_ready),
    .in_wb_done(wb_done),
    .pc(pc),
    .in_redirect_pc_r(redirect_pc_r),
    .in_redirect_valid_r(redirect_valid_r),
    .in_valid(rf_to_ifu_valid),

    .out_valid(ifu_to_idu_valid),
    .out_inst(inst),    
    .out_ready(rf_to_ifu_ready)
);

IDU idu(
    .pc(pc),
    .in_inst(inst),
    .in_src1_data(rf_src1_data),
    .in_src2_data(rf_src2_data),
    .in_valid(ifu_to_idu_valid),
    .in_ready(exu_to_idu_ready),

    .out_valid(idu_valid),
    .out_ready(idu_to_ifu_ready),
    .out_rf_we(idu_rf_we),
    .out_csr_wen(idu_csr_wen),
    .out_is_ecall(idu_is_ecall),
    .out_is_mret(idu_is_mret),
    .out_is_ebreak(idu_is_ebreak),
    .out_is_jalr(idu_is_jalr),
    .out_is_jal(idu_is_jal),
    .out_is_load(idu_is_load),
    .out_is_store(idu_is_store),
    .out_is_branch(idu_is_branch),
    .out_trap_valid(idu_trap_valid),
    .out_is_csr(idu_is_csr),
    .out_wb_sel(idu_wb_sel),
    .out_csr_op_sel(idu_csr_op_sel),
    .out_alu_src1_sel(idu_alu_src1_sel),
    .out_alu_src2_sel(idu_alu_src2_sel),
    .out_alu_op(idu_alu_op),
    .out_branch_op(idu_branch_op),
    .out_src1(idu_src1),
    .out_src2(idu_src2),
    .out_rd(idu_rd),
    .out_imm(idu_imm),
    .out_shamt(idu_shamt),
    .out_csr_addr(idu_csr_addr),
    .out_src1_data(idu_src1_data),
    .out_src2_data(idu_src2_data)
);

IDU_EXU_Reg idu_exu_reg(
    .clk(clock),

    .in_valid(idu_valid),
    .in_rf_we(idu_rf_we),
    .in_csr_wen(idu_csr_wen),
    .in_wb_sel(idu_wb_sel),
    .in_csr_op_sel(idu_csr_op_sel),

    .in_is_ecall(idu_is_ecall),
    .in_is_mret(idu_is_mret),
    .in_is_ebreak(idu_is_ebreak),
    .in_is_jalr(idu_is_jalr),
    .in_is_jal(idu_is_jal),
    .in_is_branch(idu_is_branch),
    .in_is_csr(idu_is_csr),
    .in_is_load(idu_is_load),
    .in_is_store(idu_is_store),
    .in_trap_valid(idu_trap_valid),

    .in_branch_op(idu_branch_op),
    .in_alu_op(idu_alu_op),
    .in_alu_src2_sel(idu_alu_src2_sel),
    .in_alu_src1_sel(idu_alu_src1_sel),
    .in_src1(idu_src1),
    .in_src2(idu_src2),
    .in_rd(idu_rd),
    .in_imm(idu_imm),
    .in_shamt(idu_shamt),
    .in_csr_addr(idu_csr_addr),
    .in_src1_data(idu_src1_data),
    .in_src2_data(idu_src2_data),

    .out_valid(idu_to_exu_valid),
    .out_rf_we(idu_to_exu_rf_we),
    .out_csr_wen(idu_to_exu_csr_wen),
    .out_wb_sel(idu_to_exu_wb_sel),
    .out_csr_op_sel(idu_to_exu_csr_op_sel),

    .out_is_ecall(idu_to_exu_is_ecall),
    .out_is_mret(idu_to_exu_is_mret),
    .out_is_ebreak(idu_to_exu_is_ebreak),
    .out_is_jalr(idu_to_exu_is_jalr),
    .out_is_jal(idu_to_exu_is_jal),
    .out_is_branch(idu_to_exu_is_branch),
    .out_is_csr(idu_to_exu_is_csr),
    .out_is_load(idu_to_exu_is_load),
    .out_is_store(idu_to_exu_is_store),
    .out_trap_valid(idu_to_exu_trap_valid),

    .out_branch_op(idu_to_exu_branch_op),
    .out_alu_op(idu_to_exu_alu_op),

    .out_alu_src2_sel(idu_to_exu_alu_src2_sel),
    .out_alu_src1_sel(idu_to_exu_alu_src1_sel),
    .out_src1(idu_to_exu_src1),
    .out_src2(idu_to_exu_src2),
    .out_src1_data(idu_to_exu_src1_data),
    .out_src2_data(idu_to_exu_src2_data),
    .out_rd(idu_to_exu_rd),
    .out_imm(idu_to_exu_imm),
    .out_shamt(idu_to_exu_shamt),
    .out_csr_addr(idu_to_exu_csr_addr)
);


EXU exu(
    .clk(clock),
    .pc(pc),
    .in_rf_we(idu_to_exu_rf_we),
    .out_exu_we(exu_we),
    .in_wb_sel(idu_to_exu_wb_sel),
    .in_alu_src1_sel(idu_to_exu_alu_src1_sel),
    .in_alu_src2_sel(idu_to_exu_alu_src2_sel),
    .in_alu_op(idu_to_exu_alu_op),
    .out_alu_result(alu_result),
    .out_branch_taken(branch_taken),
    .in_is_jal(idu_to_exu_is_jal),
    .in_is_jalr(idu_to_exu_is_jalr),
    .in_is_branch(idu_to_exu_is_branch),
    .out_redirect_valid(redirect_valid),
    .out_redirect_pc(redirect_pc),
    .in_trap_valid(idu_to_exu_trap_valid),
    .in_is_ebreak(idu_to_exu_is_ebreak),
    .in_is_load(idu_to_exu_is_load),
    .in_is_store(idu_to_exu_is_store),

    .in_src1_data(idu_to_exu_src1_data),
    .in_src2_data(idu_to_exu_src2_data),

    .in_rd(idu_to_exu_rd),
    .in_imm(idu_to_exu_imm),
    .in_shamt(idu_to_exu_shamt),
    .out_wb_data(wb),
    .in_branch_op(idu_to_exu_branch_op),

    .out_is_load(exu_is_load),
    .out_is_store(exu_is_store),

    .out_csr_wdata(csr_wdata),
    .in_csr_addr(idu_to_exu_csr_addr),
    .in_csr_wen(idu_to_exu_csr_wen),
    .in_is_csr(idu_to_exu_is_csr),
    .in_csr_op_sel(idu_to_exu_csr_op_sel),
    .in_is_ecall(idu_to_exu_is_ecall),
    .in_is_mret(idu_to_exu_is_mret),

    .in_ready(exu_to_lsu_ready),
    .in_valid(idu_to_exu_valid),
    .out_ready(exu_to_idu_ready),
    .out_valid(exu_to_lsu_valid)

);
LSU lsu(
    .clk(clock),
    .reset(reset),
    .exu_we(exu_we),
    .lsu_rf_we(lsu_rf_we),
    .is_load(exu_is_load),
    .is_store(exu_is_store),


    .pc(pc),
    .funct3(funct3),
    .alu_result(alu_result),
    .csr_wdata(csr_wdata),
    .wb(wb),
    .wb_sel(wb_sel),

    .src2_data(idu_to_exu_src2_data),
    
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
    .axi_soc(axi_soc.master)
);
/*
Xbar xbar(
    .clk(clock),
    .reset(reset),
    .axi_soc(axi_soc),
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
WBU wbu (
    .clk(clock),
    .reset(reset),
    .wdata(wb),
    .waddr(rd),
    .lsu_rf_we(lsu_rf_we),
    .wb_done(wb_done),
    .wb_done_flag(wb_done_flag),
    .raddr1(src1),
    .raddr2(src2),
    .rdata1(rf_src1_data),
    .rdata2(rf_src2_data),
    .lsu_to_rf_valid(lsu_to_rf_valid),
    .lsu_to_rf_ready(lsu_to_rf_ready),
    .rf_to_ifu_valid(rf_to_ifu_valid),
    .rf_to_ifu_ready(rf_to_ifu_ready)
);
/*
CSR csr (
    .clk(clock),
    .pc(pc),
    .csr_addr(csr_addr),
    .csr_wen(lsu_csr_wen),
    .is_ecall(lsu_is_ecall),
    .csr_rdata(csr_rdata),
    .csr_wdata(csr_wdata),
    .mtvec_data(mtvec_data),
    .mepc_data(mepc_data)
);
*/

endmodule
