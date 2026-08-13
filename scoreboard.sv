
import axi_pkg::*;

class scoreboard;

    mailbox #(axi_transaction) mon2scb;// Mailbox
    axi_transaction tr;// Transaction
    

    // Reference Memory
    logic [DATA_WIDTH-1:0] ref_mem [0:MEM_DEPTH-1];
    localparam MAX_VALID_ADDR = MEM_DEPTH*STRB_WIDTH - STRB_WIDTH;
    

    int pass_count;
    int fail_count;
    int total_count;
    
    int expected_transactions;
    event done;
    
    // Constructor
    function new(mailbox #(axi_transaction) mon2scb);

        this.mon2scb = mon2scb;
        pass_count  = 0;
        fail_count  = 0;
        total_count = 0;
        expected_transactions=0;

        foreach(ref_mem[i])
            ref_mem[i] = '0;

    endfunction
    
    task run();
        
        forever
        begin
            mon2scb.get(tr);
            tr.display("SCOREBOARD");
            total_count++;
            
            case(tr.cmd)
                WRITE : check_write();
                READ  : check_read();
            endcase
            
            if ((expected_transactions > 0) && (total_count == expected_transactions))
            begin
                $display("[SCOREBOARD] Completed %0d transactions", total_count);
                -> done;
            end
            
        end

    endtask

    // Check Write
    task check_write();
    
        int index;
    

    
        //-----------------------------------------------------
        // SLVERR Check
        //-----------------------------------------------------
        if(tr.addr > MAX_VALID_ADDR)
        begin
            if(tr.resp == RESP_SLVERR)
            begin
                pass_count++;
                $display("WRITE PASS : SLVERR Generated");
            end
            else
            begin
                fail_count++;
                $display("WRITE FAIL : Expected SLVERR");
            end
            return;
        end
    
        //-----------------------------------------------------
        // Normal Write
        //-----------------------------------------------------
        index = tr.addr[7:2];
    
        for(int i=0;i<STRB_WIDTH;i++)
        begin
            if(tr.wstrb[i])
                ref_mem[index][8*i +:8] = tr.wdata[8*i +:8];
        end
    
        if(tr.resp == RESP_OKAY)
        begin
            pass_count++;
    
            $display("----------------------------------------");
            $display("WRITE PASS");
            $display("ADDR  = %08h",tr.addr);
            $display("DATA  = %08h",tr.wdata);
            $display("WSTRB = %04b",tr.wstrb);
            $display("RESP  = %s",tr.resp.name());
            $display("----------------------------------------");
        end
        else
        begin
            fail_count++;
    
            $display("----------------------------------------");
            $display("WRITE FAIL");
            $display("ADDR = %08h",tr.addr);
            $display("RESP = %s",tr.resp.name());
            $display("----------------------------------------");
        end
    
    endtask

    // Check Read
    task check_read();
    
        int index;
        logic [DATA_WIDTH-1:0] expected_data;
    

        //-----------------------------------------------------
        // SLVERR Check
        //-----------------------------------------------------
        if(tr.addr > MAX_VALID_ADDR)
        begin
            if(tr.resp == RESP_SLVERR)
            begin
                pass_count++;
                $display("READ PASS : SLVERR Generated");
            end
            else
            begin
                fail_count++;
                $display("READ FAIL : Expected SLVERR");
            end
            return;
        end
    
        //-----------------------------------------------------
        // Normal Read
        //-----------------------------------------------------
        index = tr.addr[7:2];
        expected_data = ref_mem[index];
        if((tr.rdata == expected_data) &&
           (tr.resp == RESP_OKAY))
        begin
            pass_count++;
    
            $display("----------------------------------------");
            $display("READ PASS");
            $display("ADDR     = %08h",tr.addr);
            $display("EXPECTED = %08h",expected_data);
            $display("ACTUAL   = %08h",tr.rdata);
            $display("----------------------------------------");
        end
        else
        begin
            fail_count++;
    
            $display("----------------------------------------");
            $display("READ FAIL");
            $display("ADDR     = %08h",tr.addr);
            $display("EXPECTED = %08h",expected_data);
            $display("ACTUAL   = %08h",tr.rdata);
            $display("RESP     = %s",tr.resp.name());
            $display("----------------------------------------");
        end
    
    endtask
    // Report
    function void report();

        $display("\n==========================================");
        $display("        AXI SCOREBOARD REPORT");
        $display("==========================================");
        $display("TOTAL TRANSACTIONS : %0d",total_count);
        $display("PASS               : %0d",pass_count);
        $display("FAIL               : %0d",fail_count);
        $display("==========================================\n");

    endfunction

endclass
