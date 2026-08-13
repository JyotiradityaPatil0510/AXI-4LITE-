
import axi_pkg::*;

class coverage;

    mailbox #(axi_transaction) mon2cov;// Mailbox  
    axi_transaction tr; // Transaction

    // Functional Coverage
    covergroup axi_cg;

        option.per_instance = 1;
        option.name = "AXI4_Lite_Functional_Coverage";
        
        // READ / WRITE Coverage
        cmd_cp : coverpoint tr.cmd
        {
            bins READ  = {READ};
            bins WRITE = {WRITE};
        }
        
//        // Memory Address Coverage
//        addr_cp : coverpoint tr.addr[7:2]
//        {
//            bins mem_addr[] = {[0:63]};
//        }

        addr_cp : coverpoint tr.addr[7:2]
        {
            bins mem_addr[] = {[0:63]};
        }
        
        // Invalid Address Coverage
        invalid_addr_cp : coverpoint (tr.addr > 32'h000000FC)
        {
            bins VALID   = {0};
            bins INVALID = {1};
        }
        
        // Write Strobe Coverage
        wstrb_cp : coverpoint tr.wstrb iff(tr.cmd == WRITE)
        {
            bins BYTE0 = {4'b0001};
            bins BYTE1 = {4'b0010};
            bins BYTE2 = {4'b0100};
            bins BYTE3 = {4'b1000};

            bins HALF0 = {4'b0011};
            bins HALF1 = {4'b1100};

            bins WORD  = {4'b1111};

            bins OTHER = default;
        }

        // Response Coverage
        resp_cp : coverpoint tr.resp
        {
            bins OKAY   = {RESP_OKAY};
            bins SLVERR = {RESP_SLVERR};
            //bins DECERR = {RESP_DECERR};
        }
        
        // Cross Coverage
        cmd_addr_cross :
        cross cmd_cp, addr_cp;

        cmd_resp_cross :
        cross cmd_cp, resp_cp;

        cmd_wstrb_cross :
        cross cmd_cp, wstrb_cp
        iff (tr.cmd == WRITE);

    endgroup
    
    // Constructor
    function new(mailbox #(axi_transaction) mon2cov);
        this.mon2cov = mon2cov;
        axi_cg = new();
    endfunction

    // Run
    task run();

        forever
        begin
            mon2cov.get(tr);
            axi_cg.sample();
        end

    endtask
    
    // Report
    function void report();

        $display("\n==============================================");
        $display("      AXI4-Lite Functional Coverage");
        $display("==============================================");
        $display("Coverage = %0.2f %%", axi_cg.get_coverage());
        $display("==============================================\n");

    endfunction

endclass