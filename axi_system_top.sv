`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.08.2026 12:15:03
// Design Name: 
// Module Name: axi_system_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import axi_pkg::*;

module axi_system_top
(
//    //---------------------------------------------------------
//    // Global Signals
//    //---------------------------------------------------------
//    input logic ACLK,
//    input logic ARESETn,

    axi_if drv_if,// Driver Interface
    axi_bus_if bus_if// AXI Bus Monitor Interface
);

    //---------------------------------------------------------
    // Internal AXI Bus Signals
    //---------------------------------------------------------

    // Write Address Channel
    logic                  AWVALID;
    logic                  AWREADY;
    logic [ADDR_WIDTH-1:0] AWADDR;

    // Write Data Channel
    logic                  WVALID;
    logic                  WREADY;
    logic [DATA_WIDTH-1:0] WDATA;
    logic [STRB_WIDTH-1:0] WSTRB;

    // Write Response Channel
    logic                  BVALID;
    logic                  BREADY;
    axi_resp_t             BRESP;

    // Read Address Channel
    logic                  ARVALID;
    logic                  ARREADY;
    logic [ADDR_WIDTH-1:0] ARADDR;

    // Read Data Channel
    logic                  RVALID;
    logic                  RREADY;
    logic [DATA_WIDTH-1:0] RDATA;
    axi_resp_t             RRESP;

    //---------------------------------------------------------
    // Master
    //---------------------------------------------------------

    axi_master u_master
    (
        .ACLK           (drv_if.ACLK),
        .ARESETn        (drv_if.ARESETn),

        //---------------- Driver Write Interface ----------------
        .wr_start   (drv_if.wr_start),
        .wr_addr    (drv_if.wr_addr),
        .wr_data    (drv_if.wr_data),
        .wr_strb    (drv_if.wr_strb),
        
        .wr_done    (drv_if.wr_done),
        .wr_resp    (drv_if.wr_resp),

        //---------------- Driver Read Interface -----------------
        .rd_start   (drv_if.rd_start),
        .rd_addr    (drv_if.rd_addr),

        .rd_done    (drv_if.rd_done),
        .rd_data    (drv_if.rd_data),
        .rd_resp    (drv_if.rd_resp),

        //---------------- AXI Write Address ---------------------
        .AWVALID        (AWVALID),
        .AWADDR         (AWADDR),
        .AWREADY        (AWREADY),

        //---------------- AXI Write Data ------------------------
        .WVALID         (WVALID),
        .WDATA          (WDATA),
        .WSTRB          (WSTRB),
        .WREADY         (WREADY),

        //---------------- AXI Write Response --------------------
        .BVALID         (BVALID),
        .BRESP          (BRESP),
        .BREADY         (BREADY),

        //---------------- AXI Read Address ----------------------
        .ARVALID        (ARVALID),
        .ARADDR         (ARADDR),
        .ARREADY        (ARREADY),

        //---------------- AXI Read Data -------------------------
        .RVALID         (RVALID),
        .RDATA          (RDATA),
        .RRESP          (RRESP),
        .RREADY         (RREADY)
    );

    //---------------------------------------------------------
    // Slave
    //---------------------------------------------------------

    slave_top u_slave
    (
        .ACLK       (drv_if.ACLK),
        .ARESETn    (drv_if.ARESETn),

        .AWVALID    (AWVALID),
        .AWADDR     (AWADDR),
        .AWREADY    (AWREADY),

        .WVALID     (WVALID),
        .WDATA      (WDATA),
        .WSTRB      (WSTRB),
        .WREADY     (WREADY),

        .BVALID     (BVALID),
        .BRESP      (BRESP),
        .BREADY     (BREADY),

        .ARVALID    (ARVALID),
        .ARADDR     (ARADDR),
        .ARREADY    (ARREADY),

        .RVALID     (RVALID),
        .RDATA      (RDATA),
        .RRESP      (RRESP),
        .RREADY     (RREADY)
    );

    //---------------------------------------------------------
    // Connect AXI Bus Interface (Monitor)
    //---------------------------------------------------------

    assign bus_if.ACLK     = drv_if.ACLK;
    assign bus_if.ARESETn  = drv_if.ARESETn;

    assign bus_if.AWVALID  = AWVALID;
    assign bus_if.AWREADY  = AWREADY;
    assign bus_if.AWADDR   = AWADDR;

    assign bus_if.WVALID   = WVALID;
    assign bus_if.WREADY   = WREADY;
    assign bus_if.WDATA    = WDATA;
    assign bus_if.WSTRB    = WSTRB;

    assign bus_if.BVALID   = BVALID;
    assign bus_if.BREADY   = BREADY;
    assign bus_if.BRESP    = BRESP;

    assign bus_if.ARVALID  = ARVALID;
    assign bus_if.ARREADY  = ARREADY;
    assign bus_if.ARADDR   = ARADDR;

    assign bus_if.RVALID   = RVALID;
    assign bus_if.RREADY   = RREADY;
    assign bus_if.RDATA    = RDATA;
    assign bus_if.RRESP    = RRESP;
endmodule

