import axi_pkg::*;

class monitor;
    
    // Virtual Interface
    virtual axi_bus_if bus_if;

    // Mailbox
    mailbox #(axi_transaction) mon2scb;
    mailbox #(axi_transaction) mon2cov;

    // Transaction Counter
    int unsigned txn_count;

    // Constructor
    function new(virtual axi_bus_if bus_if,mailbox #(axi_transaction) mon2scb,
        mailbox #(axi_transaction) mon2cov);
        this.bus_if  = bus_if;
        this.mon2scb = mon2scb;
        this.mon2cov = mon2cov;
        txn_count = 0;
    endfunction

    // Write Address Channel
    typedef struct
    {
        logic [ADDR_WIDTH-1:0] addr;
    } aw_item_t;

    // Write Data Channel
    typedef struct
    {
        logic [DATA_WIDTH-1:0] data;
        logic [STRB_WIDTH-1:0] strb;
    } w_item_t;

    // Write Response Channel
    typedef struct
    {
        axi_resp_t resp;
    } b_item_t;

    // Read Address Channel
    typedef struct
    {
        logic [ADDR_WIDTH-1:0] addr;
    } ar_item_t;

    // Read Data Channel
    typedef struct
    {
        logic [DATA_WIDTH-1:0] data;
        axi_resp_t             resp;
    } r_item_t;
    
    
    // Queues
    aw_item_t aw_queue[$];
    w_item_t  w_queue[$];
    b_item_t  b_queue[$];

    ar_item_t ar_queue[$];
    r_item_t  r_queue[$];

    // Queue Status
    task display_queue_status();
    
        $display("----------------------------------------");
        $display("AW Queue = %0d",aw_queue.size());
        $display(" W Queue = %0d",w_queue.size());
        $display(" B Queue = %0d",b_queue.size());
        $display("AR Queue = %0d",ar_queue.size());
        $display(" R Queue = %0d",r_queue.size());
        $display("----------------------------------------");
        
    endtask
    
    // Capture Write Address Channel
    task capture_aw();
    
        aw_item_t item;
        if(bus_if.AWVALID && bus_if.AWREADY)
        begin
            item.addr = bus_if.AWADDR;
            aw_queue.push_back(item);
            $display("[%0t] MONITOR : AW Handshake  ADDR=%08h",$time,item.addr);
        end
        
    endtask
    
    // Capture Write Data Channel
    task capture_w();
    
        w_item_t item;
        if(bus_if.WVALID && bus_if.WREADY)
        begin
            item.data = bus_if.WDATA;
            item.strb = bus_if.WSTRB;
            w_queue.push_back(item);
            $display("[%0t] MONITOR : W Handshake   DATA=%08h STRB=%b",$time,item.data,item.strb);              
        end
    
    endtask
    
    // Capture Write Response Channel
    task capture_b();
    
        b_item_t item;
        if(bus_if.BVALID && bus_if.BREADY)
        begin
            item.resp = bus_if.BRESP;
            b_queue.push_back(item);
            $display("[%0t] MONITOR : B Handshake   RESP=%s",$time,item.resp.name());              
        end
    
    endtask
    
    // Capture Read Address Channel
    task capture_ar();
    
        ar_item_t item;
        if(bus_if.ARVALID && bus_if.ARREADY)
        begin
            item.addr = bus_if.ARADDR;
            ar_queue.push_back(item);
            $display("[%0t] MONITOR : AR Handshake  ADDR=%08h",$time,item.addr);               
        end
    
    endtask
    
    // Capture Read Data Channel
    task capture_r();
    
        r_item_t item;
        if(bus_if.RVALID && bus_if.RREADY)
        begin
            item.data = bus_if.RDATA;
            item.resp = bus_if.RRESP;
            r_queue.push_back(item);
            $display("[%0t] MONITOR : R Handshake DATA=%08h RESP=%s",$time,item.data,item.resp.name());                 
        end
    
    endtask
    
    // Build Complete Write Transaction
    task build_write_transaction();
    
        axi_transaction tr;
        aw_item_t aw;
        w_item_t  w;
        b_item_t  b;
    
        // Wait until complete write transaction is available
        while((aw_queue.size() > 0) && (w_queue.size()  > 0) &&(b_queue.size()  > 0))
        begin
        
            // Pop one entry from each queue
            aw = aw_queue.pop_front();
            w  = w_queue.pop_front();
            b  = b_queue.pop_front();
            
            // Create Transaction
            tr = new();
    
            tr.txn_id = txn_count++;
            tr.cmd    = WRITE;
            tr.addr   = aw.addr;
            tr.wdata  = w.data;
            tr.wstrb  = w.strb;
            tr.resp   = b.resp;
            
            tr.display("MONITOR WRITE");
            mon2scb.put(tr.copy());
            mon2cov.put(tr.copy());
        end
    
    endtask
    
    // Build Complete Read Transaction
    task build_read_transaction();
    
        axi_transaction tr;
    
        ar_item_t ar;
        r_item_t  r;
    
        // Wait until complete read transaction is available
        while((ar_queue.size() > 0) &&
           (r_queue.size()  > 0))
        begin
    
            //-------------------------------------------------
            // Pop Queue
            ar = ar_queue.pop_front();
            r  = r_queue.pop_front();
            
            // Create Transaction
            tr = new();
    
            tr.txn_id = txn_count++;
            tr.cmd    = READ;
            tr.addr   = ar.addr;
            tr.rdata  = r.data;
            tr.resp   = r.resp;
            
            tr.display("MONITOR READ");// Display
            mon2scb.put(tr.copy());
            mon2cov.put(tr.copy());
        end
    
    endtask
    
    // Run
    task run();
    
        $display("[%0t] AXI Monitor Started",$time);
        forever
        begin
    
            @(posedge bus_if.ACLK);
            
            // Wait until reset is released
            if(!bus_if.ARESETn)
            begin
                aw_queue.delete();
                w_queue.delete();
                b_queue.delete();
                ar_queue.delete();
                r_queue.delete();
                txn_count = 0;
                continue;
            end
    
            // Capture AXI Channels
            capture_aw();
            capture_w();
            capture_b();
            capture_ar();
            capture_r();
            
            // Build Complete Transactions
            build_write_transaction();
            build_read_transaction();
    
            //-------------------------------------------------
            // Debug Queue Status
            //-------------------------------------------------
            //display_queue_status();
        end
    
    endtask
   
endclass