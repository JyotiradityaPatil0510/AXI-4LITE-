
import axi_pkg::*;

class test;

    // Virtual Interfaces
    virtual axi_if drv_if;
    virtual axi_bus_if bus_if;

    // Environment
    env env;

    // Test Configuration
    test_mode_t test_case;
    int unsigned num_transactions;

    function new( virtual axi_if drv_if, virtual axi_bus_if bus_if );
    
        this.drv_if = drv_if;
        this.bus_if = bus_if;
        env = new(drv_if,bus_if);

    endfunction
    
    task run_single_test(test_mode_t mode, int num);
    
        $display("\n======================================");
        $display("RUNNING TEST : %s", mode.name());
        $display("======================================");
    
        //-------------------------------------------------
        // Reset Generator
        //-------------------------------------------------
        env.gen.mode             = mode;
        env.gen.num_transactions = num;
        env.gen.txn_count        = 0;
        env.gen.written_addr_q.delete();
    
        //-------------------------------------------------
        // Reset Scoreboard
        //-------------------------------------------------
        env.scb.pass_count = 0;
        env.scb.fail_count = 0;
        env.scb.total_count = 0;
        env.scb.expected_transactions = num;
    
        // Start Generator only
        fork
            env.gen.run();
        join_none
        
        // Wait for Completion
        @(env.scb.done);
            
        //-------------------------------------------------
        // Print Report
        //-------------------------------------------------
        env.report();
    
    endtask
    
    task run();
    
        // Start environment only once
        env.run();
    
        run_single_test(CONTINUOUS_WRITE,20);
        run_single_test(CONTINUOUS_READ,20);
        run_single_test(ADDRESS_SWEEP,64);
        run_single_test(ALTERNATE_RW,20);
        run_single_test(RANDOM_RW,20);
        run_single_test(SAME_ADDRESS,20);
        run_single_test(INVALID_ADDRESS,20);
    
        $display("\n========================================");
        $display("     REGRESSION COMPLETED");
        $display("========================================");
    
    endtask
    
endclass
