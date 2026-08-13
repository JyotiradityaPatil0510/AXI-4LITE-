import axi_pkg::*;

class env;

    // Virtual Interfaces
    virtual axi_if     drv_if;
    virtual axi_bus_if bus_if;

    // Mailboxes
    mailbox #(axi_transaction) gen2drv;
    mailbox #(axi_transaction) mon2scb;
    mailbox #(axi_transaction) mon2cov;

    // Components
    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard scb;
    coverage   cov;

    // Constructor
    function new
    (
        virtual axi_if drv_if,
        virtual axi_bus_if bus_if
    );

        // Save Virtual Interfaces
        this.drv_if = drv_if;
        this.bus_if = bus_if;

        // Create Mailboxes
        gen2drv = new();
        mon2scb = new();
        mon2cov = new();

        // Create Components
        gen = new(gen2drv);

        drv = new(gen2drv,drv_if);
        
        mon = new(bus_if,mon2scb,mon2cov);
        
        scb = new(mon2scb);

        cov = new(mon2cov);

    endfunction

    //---------------------------------------------------------
    // Run
    //---------------------------------------------------------
    task run();
    
        fork
            drv.run();
            mon.run();
            scb.run();
            cov.run();
        join_none
    
    endtask

    //---------------------------------------------------------
    // Report
    //---------------------------------------------------------
    function void report();

        scb.report();

        cov.report();

    endfunction

endclass