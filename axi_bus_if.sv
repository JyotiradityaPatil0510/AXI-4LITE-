`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.08.2026 12:15:03
// Design Name: 
// Module Name: axi_bus_if
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

interface axi_bus_if;


    //---------------------------------------------------------
    // Global Signals
    //---------------------------------------------------------
    logic                    ACLK;
    logic                    ARESETn;

    //---------------------------------------------------------
    // Write Address Channel
    //---------------------------------------------------------
    logic                    AWVALID;
    logic                    AWREADY;
    logic [ADDR_WIDTH-1:0]   AWADDR;

    //---------------------------------------------------------
    // Write Data Channel
    //---------------------------------------------------------
    logic                    WVALID;
    logic                    WREADY;
    logic [DATA_WIDTH-1:0]   WDATA;
    logic [STRB_WIDTH-1:0]   WSTRB;

    //---------------------------------------------------------
    // Write Response Channel
    //---------------------------------------------------------
    logic                    BVALID;
    logic                    BREADY;
    axi_resp_t               BRESP;

    //---------------------------------------------------------
    // Read Address Channel
    //---------------------------------------------------------
    logic                    ARVALID;
    logic                    ARREADY;
    logic [ADDR_WIDTH-1:0]   ARADDR;

    //---------------------------------------------------------
    // Read Data Channel
    //---------------------------------------------------------
    logic                    RVALID;
    logic                    RREADY;
    logic [DATA_WIDTH-1:0]   RDATA;
    axi_resp_t               RRESP;

endinterface
