`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.08.2026 12:23:06
// Design Name: 
// Module Name: axi_transaction
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

class axi_transaction;

    //============================================================
    // Transaction Information
    //============================================================

    int unsigned txn_id;
    rand cmd_t cmd;

    //============================================================
    // AXI Fields
    //============================================================

    rand logic [ADDR_WIDTH-1:0] addr;
    rand logic [DATA_WIDTH-1:0] wdata;
         logic [DATA_WIDTH-1:0] rdata;

    rand logic [STRB_WIDTH-1:0] wstrb;

         axi_resp_t resp;

    //============================================================
    // Constraints
    //============================================================

    constraint addr_align
    {
        addr[1:0] == 2'b00;
    }
    
    constraint valid_addr_c
    {
         soft addr < (MEM_DEPTH*(DATA_WIDTH/8));
    }
    
    constraint valid_wstrb
    {
        if(cmd == WRITE)
            wstrb inside {[1:(2**STRB_WIDTH)-1]};
        else
            wstrb == 0;
    }
    
    constraint read_fields
    {
        if(cmd == READ)
        {
            wdata == 0;
        }
    } 

    //============================================================
    // Constructor
    //============================================================

    function new();
        txn_id = 0;
        addr   = '0;
        wdata  = '0;
        rdata  = '0;
        wstrb  = '0;
        resp   = RESP_OKAY;
    endfunction

    //============================================================
    // Copy
    //============================================================

    function axi_transaction copy();

        axi_transaction tr;

        tr = new();

        tr.txn_id = this.txn_id;
        tr.cmd    = this.cmd;
        tr.addr   = this.addr;
        tr.wdata  = this.wdata;
        tr.rdata  = this.rdata;
        tr.wstrb  = this.wstrb;
        tr.resp   = this.resp;

        return tr;

    endfunction

    //============================================================
    // Display
    //============================================================

    function void display(string tag="TRANSACTION");

        $display("\n==================================================");
        $display("%s",tag);
        $display("TXN ID : %0d",txn_id);
        $display("CMD : %s",cmd.name());
        $display("ADDR   : %08h",addr);

        if(cmd == WRITE)
        begin
            $display("WDATA  : %08h",wdata);
            $display("WSTRB  : %04b",wstrb);
        end

        else
        begin
            $display("RDATA  : %08h",rdata);
        end
 
        $display("RESP   : %s",resp.name());
        $display("==================================================\n");

    endfunction

endclass


