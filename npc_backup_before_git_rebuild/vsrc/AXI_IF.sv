interface AXI_IF();
    //AR
    logic       [31:0]      araddr;
    logic                   arvalid;
    logic                   arready;
    
    //R
    logic       [31:0]      rdata;
    logic       [ 1:0]      rresp;
    logic                   rvalid;
    logic                   rready;
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
        input       rdata,
        input       rresp,
        input       rvalid,
        output      rready,
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
        output      arready,
        output      rdata,
        output      rresp,
        output      rvalid,
        input       rready,
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
