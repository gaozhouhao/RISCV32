`include "params.vh"
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
wire    [31:0]  pc/* verilator public_flat_rd */;
AXI_IF          axi_lsu();
AXI_IF          axi_ifu();
AXI_IF          axi_arb();
AXI_IF          axi_soc();
AXI_IF          axi_clint();
AXI_IF          axi_mem();
AXI_IF          axi_uart();



assign axi_soc.awready   = io_master_awready;
assign io_master_awvalid = axi_soc.awvalid;
assign io_master_awaddr  = axi_soc.awaddr;
assign io_master_awid    = 4'b0;
assign io_master_awlen   = 8'b0;
assign io_master_awsize  = 3'b000;
assign io_master_awburst = 2'b0;

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
assign io_master_arid    = 4'b0;
assign io_master_arlen   = axi_soc.arlen;
assign io_master_arsize  = axi_soc.arsize;
assign io_master_arburst = axi_soc.arburst;

assign axi_soc.rresp    = io_master_rresp;
assign axi_soc.rvalid   = io_master_rvalid;
assign axi_soc.rdata    = io_master_rdata;
assign io_master_rready = axi_soc.rready;
assign axi_soc.rlast    = io_master_rlast;


assign io_slave_awready  = 1'b0;

assign io_slave_wready   = 1'b0;

assign io_slave_bvalid   = 1'b0;
assign io_slave_bresp    = 2'b0;
assign io_slave_bid      = 4'b0;

assign io_slave_arready  = 1'b0;

assign io_slave_rvalid   = 1'b0;
assign io_slave_rresp    = 2'b0;
assign io_slave_rdata    = 32'b0;
assign io_slave_rlast    = 1'b0;
assign io_slave_rid      = 4'b0;




wire            ifu_to_idu_valid;
wire            idu_to_ifu_ready;

wire            idu_to_exu_valid;
wire            exu_to_idu_ready;

wire            exu_to_lsu_valid;
wire            lsu_to_exu_ready;

wire            lsu_to_wbu_valid;
wire            wbu_to_lsu_ready;


// IFU Output
wire            ifu_icache_flush;
wire    [31:0]  ifu_pc;

// IDU Output
wire    [31:0]  idu_pc;
wire    [31:0]  idu_inst;
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
wire            idu_is_load;
wire            idu_is_store;
wire            idu_is_fencei;
wire            idu_trap_valid;
wire    [ 2:0]  idu_branch_op;
wire    [ 2:0]  idu_load_size;
wire    [ 2:0]  idu_store_size;
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
wire    [ 4:0]  idu_decode_src1;
wire    [ 4:0]  idu_decode_src2;

//  EXU Output
wire            exu_is_load;
wire            exu_is_store;
wire            exu_is_fencei;
wire    [2 :0]  exu_load_size;
wire    [2 :0]  exu_store_size;
wire    [31:0]  exu_wb_data;
wire    [31:0]  exu_store_data;
wire    [31:0]  exu_mem_addr;
wire            exu_rf_we;
wire    [ 4:0]  exu_src1;
wire    [ 4:0]  exu_src2;
wire    [ 4:0]  exu_rd;
wire            exu_redirect_valid;
wire    [31:0]  exu_redirect_pc;
wire    [31:0]  exu_pc;
wire    [31:0]  exu_inst;
wire    [31:0]  exu_npc;
wire            exu_is_ebreak;

//  LSU Output
wire            lsu_rf_we;
wire    [31:0]  lsu_wb_data;
wire    [ 4:0]  lsu_rd;
wire    [ 4:0]  lsu_src1;
wire    [ 4:0]  lsu_src2;
wire            lsu_is_mmio;
wire            lsu_is_fencei;
wire            lsu_redirect_valid;
wire    [31:0]  lsu_redirect_pc;
wire    [31:0]  lsu_pc;
wire    [31:0]  lsu_inst;
wire    [31:0]  lsu_npc;
wire            lsu_is_ebreak;

//  WBU Output
wire    [31:0]  wbu_src1_data;
wire    [31:0]  wbu_src2_data;
wire            wbu_fencei_done;
wire            wbu_commit_valid    /* verilator public_flat_rd */;
wire            wbu_commit_fire     /* verilator public_flat_rd */;
wire    [31:0]  wbu_commit_pc       /* verilator public_flat_rd */;
wire    [31:0]  wbu_commit_inst     /* verilator public_flat_rd */;
wire    [31:0]  wbu_commit_npc      /* verilator public_flat_rd */;
wire            wbu_commit_ebreak   /* verilator public_flat_rd */;
wire            wbu_commit_skip_ref /* verilator public_flat_rd */;
wire            wbu_commit_wen      /* verilator public_flat_rd */;
wire    [ 4:0]  wbu_commit_rd       /* verilator public_flat_rd */;
wire    [31:0]  wbu_commit_wdata    /* verilator public_flat_rd */;

IFU ifu(
    .axi(axi_ifu),
    .clk(clock),
    .reset(reset),
    .in_ready(idu_to_ifu_ready),
    .in_fencei_done(wbu_fencei_done),
    .out_pc(ifu_pc),
    .in_redirect_pc(lsu_redirect_pc),
    .in_redirect_valid(lsu_redirect_valid),
    
    .out_valid(ifu_to_idu_valid),
    .out_inst(inst),
    .out_icache_flush(ifu_icache_flush)
);

IDU idu(
    .clk(clock),
    .reset(reset),
    .in_inst(inst),
    .in_pc(ifu_pc),
    .in_src1_data(wbu_src1_data),
    .in_src2_data(wbu_src2_data),
    .in_valid(ifu_to_idu_valid),
    .in_ready(exu_to_idu_ready),

    .out_valid(idu_to_exu_valid),
    .out_ready(idu_to_ifu_ready),
    .out_pc(idu_pc),
    .out_inst(idu_inst),
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
    .out_is_fencei(idu_is_fencei),
    .out_trap_valid(idu_trap_valid),
    .out_wb_sel(idu_wb_sel),
    .out_csr_op_sel(idu_csr_op_sel),
    .out_alu_src1_sel(idu_alu_src1_sel),
    .out_alu_src2_sel(idu_alu_src2_sel),
    .out_alu_op(idu_alu_op),
    .out_branch_op(idu_branch_op),
    .out_load_size(idu_load_size),
    .out_store_size(idu_store_size),
    .out_src1(idu_src1),
    .out_src2(idu_src2),
    .out_rd(idu_rd),
    .out_imm(idu_imm),
    .out_shamt(idu_shamt),
    .out_csr_addr(idu_csr_addr),
    .out_src1_data(idu_src1_data),
    .out_src2_data(idu_src2_data),
    .idu_decode_src1(idu_decode_src1),
    .idu_decode_src2(idu_decode_src2)
);


EXU exu(
    .clk(clock),
    .reset(reset),
    .in_pc(idu_pc),
    .in_inst(idu_inst),
    .in_rf_we(idu_rf_we),
    .in_wb_sel(idu_wb_sel),
    .in_alu_src1_sel(idu_alu_src1_sel),
    .in_alu_src2_sel(idu_alu_src2_sel),
    .in_alu_op(idu_alu_op),
    
    .in_is_jal(idu_is_jal),
    .in_is_jalr(idu_is_jalr),
    .in_is_branch(idu_is_branch),
    .in_trap_valid(idu_trap_valid),
    .in_is_ebreak(idu_is_ebreak),
    .in_is_load(idu_is_load),
    .in_is_store(idu_is_store),
    .in_is_fencei(idu_is_fencei),
    .in_src1(idu_src1),
    .in_src2(idu_src2),
    .in_src1_data(idu_src1_data),
    .in_src2_data(idu_src2_data),

    .in_rd(idu_rd),
    .in_imm(idu_imm),
    .in_shamt(idu_shamt),
    
    .in_branch_op(idu_branch_op),
    .in_load_size(idu_load_size),
    .in_store_size(idu_store_size),

    .in_csr_addr(idu_csr_addr),
    .in_csr_wen(idu_csr_wen),
    .in_csr_op_sel(idu_csr_op_sel),
    .in_is_ecall(idu_is_ecall),
    .in_is_mret(idu_is_mret),

    .in_ready(lsu_to_exu_ready),
    .in_valid(idu_to_exu_valid),

    .out_pc(exu_pc),
    .out_inst(exu_inst),
    .out_npc(exu_npc),
    .out_is_ebreak(exu_is_ebreak),
    .out_wb_data(exu_wb_data),
    .out_store_data(exu_store_data),
    .out_src1(exu_src1),
    .out_src2(exu_src2),
    .out_rd(exu_rd),
    .out_mem_addr(exu_mem_addr),
    .out_load_size(exu_load_size),
    .out_store_size(exu_store_size),
    .out_is_load(exu_is_load),
    .out_is_store(exu_is_store),
    .out_is_fencei(exu_is_fencei),

    .out_redirect_valid(exu_redirect_valid),
    .out_redirect_pc(exu_redirect_pc),
    .out_rf_we(exu_rf_we),
    .out_ready(exu_to_idu_ready),
    .out_valid(exu_to_lsu_valid)

);
LSU lsu(
    .clk(clock),
    .reset(reset),

    .in_pc(exu_pc),
    .in_inst(exu_inst),
    .in_npc(exu_npc),
    .in_is_ebreak(exu_is_ebreak),
    .in_rf_we(exu_rf_we),
    .in_rd(exu_rd),
    .in_src1(exu_src1),
    .in_src2(exu_src2),
    .in_is_load(exu_is_load),
    .in_is_store(exu_is_store),
    .in_is_fencei(exu_is_fencei),
    .in_ready(wbu_to_lsu_ready),
    .in_redirect_valid(exu_redirect_valid),
    .in_redirect_pc(exu_redirect_pc),
    .in_load_size(exu_load_size),
    .in_store_size(exu_store_size),
    .in_mem_addr(exu_mem_addr),
    .in_wb_data(exu_wb_data),
    .in_store_data(exu_store_data),
    
    .axi(axi_lsu),

    .in_valid(exu_to_lsu_valid),
    .out_ready(lsu_to_exu_ready),
    .out_valid(lsu_to_wbu_valid),
    
    .out_pc(lsu_pc),
    .out_inst(lsu_inst),
    .out_npc(lsu_npc),
    .out_is_ebreak(lsu_is_ebreak),
    .out_is_fencei(lsu_is_fencei),
    .out_is_mmio(lsu_is_mmio),
    .out_wb_data(lsu_wb_data),
    .out_rd(lsu_rd),
    .out_src1(lsu_src1),
    .out_src2(lsu_src2),
    .out_rf_we(lsu_rf_we),
    .out_redirect_valid(lsu_redirect_valid),
    .out_redirect_pc(lsu_redirect_pc)
);


WBU wbu (
    .clk(clock),
    .reset(reset),
    .in_pc(lsu_pc),
    .in_inst(lsu_inst),
    .in_npc(lsu_npc),
    .in_is_ebreak(lsu_is_ebreak),
    .in_is_mmio(lsu_is_mmio),
    .in_is_fencei(lsu_is_fencei),
    .in_wdata(lsu_wb_data),
    .in_waddr(lsu_rd),
    .in_rf_we(lsu_rf_we),
    .in_valid(lsu_to_wbu_valid),
    .in_raddr1(idu_decode_src1),
    .in_raddr2(idu_decode_src2),
    .commit_ready(1'b1),
    .commit_valid(wbu_commit_valid),
    .commit_fire(wbu_commit_fire),
    .commit_pc(wbu_commit_pc),
    .commit_inst(wbu_commit_inst),
    .commit_npc(wbu_commit_npc),
    .commit_ebreak(wbu_commit_ebreak),
    .commit_skip_ref(wbu_commit_skip_ref),
    .commit_wen(wbu_commit_wen),
    .commit_rd(wbu_commit_rd),
    .commit_wdata(wbu_commit_wdata),
    .out_rdata1(wbu_src1_data),
    .out_rdata2(wbu_src2_data),
    .out_fencei_done(wbu_fencei_done),
    .out_ready(wbu_to_lsu_ready)
);





`ifdef ARCH_NPC

Arbiter arbiter(
    .clk(clock),
    .reset(reset),
    .axi_ifu(axi_ifu),
    .axi_lsu(axi_lsu),
    .axi_arb(axi_arb)
);

Xbar xbar(
    .clk(clock),
    .reset(reset),
    .axi_arb(axi_arb),
    .axi_mem(axi_mem),
    .axi_uart(axi_uart),
    .axi_clint(axi_clint)
);

CLINT clint(
    .clk(clock),
    .reset(reset),
    .axi(axi_clint)
);

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

`elsif ARCH_YSYXSOC

AXI_IF  axi_icache();


ICACHE icache(
    .clk(clock),
    .reset(reset),
    .in_icache_flush(ifu_icache_flush),
    .axi_in(axi_ifu),
    .axi_out(axi_icache)
);


Arbiter arbiter(
    .clk(clock),
    .reset(reset),
    .axi_ifu(axi_icache),
    .axi_lsu(axi_lsu),
    .axi_arb(axi_arb)
);



SoCXbar socxbar(
    .clk(clock),
    .reset(reset),
    .axi_arb(axi_arb),
    .axi_soc(axi_soc),
    .axi_clint(axi_clint)
);

CLINT clint(
    .clk(clock),
    .reset(reset),
    .axi(axi_clint)    
);

`endif

endmodule
