import axi_pkg::*;

class driver;

    localparam int TIMEOUT = 1000;  // Local Parameters

    mailbox #(axi_transaction) gen2drv;  // Mailbox

    virtual axi_if vif;  // Virtual Interface

    axi_transaction tr; // Transaction Handle

    //------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------
    function new(mailbox #(axi_transaction) gen2drv,
                 virtual axi_if vif);

        this.gen2drv = gen2drv;
        this.vif     = vif;

    endfunction

    //------------------------------------------------------------
    // Reset Driver Outputs
    //------------------------------------------------------------
    task reset_outputs();

        vif.wr_start = 0;
        vif.rd_start = 0;

        vif.wr_addr  = '0;
        vif.rd_addr  = '0;

        vif.wr_data  = '0;
        vif.wr_strb  = '0;

    endtask

    //------------------------------------------------------------
    // Drive Write Transaction
    //------------------------------------------------------------
    task drive_write();

        int timeout;

        // Drive request
        vif.wr_addr  = tr.addr;
        vif.wr_data  = tr.wdata;
        vif.wr_strb  = tr.wstrb;
        vif.wr_start = 1'b1;

        // Hold request for one clock
        @(posedge vif.ACLK);

        vif.wr_start = 1'b0;

        // Wait for completion
        timeout = TIMEOUT;

        while(!vif.wr_done && timeout > 0)
        begin
            @(posedge vif.ACLK);
            timeout--;
        end

        if(timeout == 0)
            $fatal(1,"[DRIVER] Write Timeout : TXN_ID=%0d",tr.txn_id);

        $display("[DRIVER] WRITE COMPLETE : TXN_ID=%0d RESP=%s",
                 tr.txn_id, vif.wr_resp.name());

        reset_outputs();

    endtask

    //------------------------------------------------------------
    // Drive Read Transaction
    //------------------------------------------------------------
    task drive_read();

        int timeout;

        // Drive request
        vif.rd_addr  = tr.addr;
        vif.rd_start = 1'b1;

        // Hold request for one clock
        @(posedge vif.ACLK);

        vif.rd_start = 1'b0;

        // Wait for completion
        timeout = TIMEOUT;

        while(!vif.rd_done && timeout > 0)
        begin
            @(posedge vif.ACLK);
            timeout--;
        end

        if(timeout == 0)
            $fatal(1,"[DRIVER] Read Timeout : TXN_ID=%0d",tr.txn_id);

        $display("[DRIVER] READ COMPLETE : TXN_ID=%0d RESP=%s",
                 tr.txn_id,
                 vif.rd_resp.name());

        reset_outputs();

    endtask

    //------------------------------------------------------------
    // Main Driver
    //------------------------------------------------------------
    task run();

        reset_outputs();

        wait(vif.ARESETn);

        @(posedge vif.ACLK);

        forever
        begin

            gen2drv.get(tr);

            tr.display("DRIVER");

            case(tr.cmd)

                WRITE :
                    drive_write();

                READ :
                    drive_read();

                default :
                    $fatal(1,"[DRIVER] Invalid Command");

            endcase

        end

    endtask

endclass
