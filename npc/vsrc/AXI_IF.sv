interface AXI_IF();
    //AR
    logic       [31:0]      araddr;
    logic                   arvalid;
    logic                   arready;
    logic       [ 3:0]      arid;
    logic       [ 7:0]      arlen;
    logic       [ 2:0]      arsize;
    logic       [ 1:0]      arburst;

    //R
    logic       [31:0]      rdata;
    logic       [ 1:0]      rresp;
    logic                   rvalid;
    logic                   rready;
    logic                   rlast;
    //AW
    logic       [31:0]      awaddr;
    logic                   awvalid;
    logic                   awready;
    //W
    logic       [31:0]      wdata;
    logic       [ 3:0]      wstrb;
    logic                   wvalid;
    logic                   wready;
    //B
    logic       [ 1:0]      bresp;
    logic                   bvalid;
    logic                   bready;
    
    modport master(
        output      araddr,
        output      arvalid,
        input       arready,
        output      arid,
        output      arlen,
        output      arsize,
        output      arburst,

        input       rdata,
        input       rresp,
        input       rvalid,
        output      rready,
        input       rlast,

        output      awaddr,
        output      awvalid,
        input       awready,
        output      wdata,
        output      wstrb,
        output      wvalid,
        input       wready,
        input       bresp,
        input       bvalid,
        output      bready
    );

     modport slaver(
        input       araddr,
        input       arvalid,
        input       arburst,
        input       arlen,
        input       arsize,
        
        output      arready,
        output      rdata,
        output      rresp,
        output      rvalid,
        input       rready,
        output      rlast,

        input       awaddr,
        input       awvalid,
        output      awready,
        input       wdata,
        input       wstrb,
        input       wvalid,
        output      wready,
        output      bresp,
        output      bvalid,
        input       bready
    );

               

endinterface
