`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.08.2026 12:23:06
// Design Name: 
// Module Name: tb_top
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

module tb_top;

    // Interfaces
    axi_if     drv_if();
    axi_bus_if bus_if();

    test test;// Test

    // DUT
    axi_system_top dut
    (

        .drv_if     (drv_if),
        .bus_if     (bus_if)
    );
    
    axi_assertion u_axi_assertion(bus_if);

    // Clock Generation
    initial
    begin
        drv_if.ACLK = 1'b0;
        
        forever #5 drv_if.ACLK = ~drv_if.ACLK;
    end

    // Reset Generation
    initial
    begin
        drv_if.ARESETn = 1'b0;

        repeat(5) @(posedge drv_if.ACLK);

        drv_if.ARESETn = 1'b1;
    end

    //---------------------------------------------------------
    // Test Execution
    //---------------------------------------------------------
    initial
    begin
        //process::self().srandom($urandom);
        wait(drv_if.ARESETn);// Wait until reset is released
        @(posedge drv_if.ACLK);
        
        test = new(drv_if, bus_if);// Create Test

        test.run();// Run Test

        //-----------------------------------------------------
        // End Simulation
        //-----------------------------------------------------
        $display("\n========================================");
        $display("      SIMULATION COMPLETED");
        $display("========================================\n");

        $finish;
    end
    
    //assertion injection logic
//    initial begin
//        wait(drv_if.ARESETn);
    
//        #100ns;
    
//        force dut.AWREADY = 1'b0;
    
//        #50ns;
    
//        release dut.AWREADY;
//    end

endmodule

