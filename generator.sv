import axi_pkg::*;

class generator;

    //------------------------------------------------------------
    // Mailbox
    //------------------------------------------------------------
    mailbox #(axi_transaction) gen2drv;

    //------------------------------------------------------------
    // Generator Configuration
    //------------------------------------------------------------
    int unsigned num_transactions;
    int unsigned sweep_index;
    int unsigned txn_count;
    test_mode_t mode;

    localparam int VALID_END = MEM_DEPTH*(DATA_WIDTH/8)-4;

    //------------------------------------------------------------
    // Queue of Written Addresses
    //------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] written_addr_q[$];

    //------------------------------------------------------------
    // Constructor
    //------------------------------------------------------------
    function new(mailbox #(axi_transaction) gen2drv);
        this.gen2drv = gen2drv;
        num_transactions = 1;
        txn_count        = 0;
        sweep_index = 0;
        mode             = RANDOM_RW;
    endfunction

    //------------------------------------------------------------
    // Store unique write addresses
    //------------------------------------------------------------
    function void store_write_addr(logic [ADDR_WIDTH-1:0] addr);

        bit found = 0;

        foreach(written_addr_q[i])
        begin
            if(written_addr_q[i] == addr)
            begin
                found = 1;
                break;
            end
        end

        if(!found)
            written_addr_q.push_back(addr);

    endfunction

    //------------------------------------------------------------
    //for covering every bins. 
    //------------------------------------------------------------    
    task automatic generate_address_sweep(output axi_transaction tr);

    tr = new();
    tr.txn_id = txn_count++;

    assert(tr.randomize() with
    {
        cmd  == WRITE;
        addr == sweep_index * 4;
    });

    store_write_addr(tr.addr);

    sweep_index++;

    if(sweep_index == MEM_DEPTH)
        sweep_index = 0;

    endtask

    //------------------------------------------------------------
    // Generate WRITE Transaction
    //------------------------------------------------------------
    task automatic generate_write(output axi_transaction tr);

        tr = new();
        tr.txn_id = txn_count++;

        if(!tr.randomize() with { cmd == WRITE; })
            $fatal(1,"[GENERATOR] WRITE Randomization Failed");

        store_write_addr(tr.addr);

    endtask

    //------------------------------------------------------------
    // Generate READ Transaction
    //------------------------------------------------------------
    task automatic generate_read(output axi_transaction tr);

        int index;

        tr = new();
        tr.txn_id = txn_count++;

        //--------------------------------------------------------
        // No previous writes
        //--------------------------------------------------------
        if(written_addr_q.size() == 0)
        begin
            if(!tr.randomize() with { cmd == READ; })
                $fatal(1,"[GENERATOR] READ Randomization Failed");
        end
        else
        begin

            randcase

                //------------------------------------------------
                // 80% Read Previously Written Address
                //------------------------------------------------
                80:
                begin

                    index = $urandom_range(0, written_addr_q.size()-1);

                    if(!tr.randomize() with
                    {
                        cmd  == READ;
                        addr == written_addr_q[index];
                    })
                        $fatal(1,"[GENERATOR] READ Randomization Failed");

                end

                //------------------------------------------------
                // 20% Random Address
                //------------------------------------------------
                20:
                begin

                    if(!tr.randomize() with
                    {
                        cmd == READ;
                    })
                        $fatal(1,"[GENERATOR] READ Randomization Failed");

                end

            endcase

        end

    endtask

    //------------------------------------------------------------
    // Main Generator
    //------------------------------------------------------------
    task run();

        axi_transaction tr;
        //process::self().srandom($urandom);

        repeat(num_transactions)
        begin

            case(mode)

                //------------------------------------------------
                // Continuous Write
                //------------------------------------------------
                CONTINUOUS_WRITE:
                begin
                    generate_write(tr);
                end

                //------------------------------------------------
                // Continuous Read
                //------------------------------------------------
                CONTINUOUS_READ:
                begin
                    generate_read(tr);
                end

                //------------------------------------------------
                // Alternate Read/Write
                //------------------------------------------------
                ALTERNATE_RW:
                begin

                    if(txn_count % 2 == 0)
                        generate_write(tr);
                    else
                        generate_read(tr);

                end

                //------------------------------------------------
                // Random Read/Write
                //------------------------------------------------
                RANDOM_RW:
                begin

                    randcase

                        50:
                            generate_write(tr);

                        50:
                            generate_read(tr);

                    endcase

                end

                //------------------------------------------------
                // Same Address
                //------------------------------------------------
                SAME_ADDRESS:
                begin

                    tr = new();
                    tr.txn_id = txn_count++;

                    if(!tr.randomize() with
                    {
                        addr == 32'h00000020;
                    })
                        $fatal(1,"[GENERATOR] SAME_ADDRESS Randomization Failed");

                    if(tr.cmd == WRITE)
                        store_write_addr(tr.addr);

                end

                //------------------------------------------------
                // Invalid Address
                //------------------------------------------------
                INVALID_ADDRESS:
                begin
                
                    tr = new();
                    tr.txn_id = txn_count++;
                
                    randcase
                
                        //------------------------------------------------
                        // 90% Invalid Address (Boundary)
                        //------------------------------------------------
                        90:
                        begin
                            assert(tr.randomize() with
                            {
                                addr >  VALID_END;
                            })
                            else
                                $fatal(1,"[GENERATOR] INVALID_ADDRESS Randomization Failed");
                        end
                
                        //------------------------------------------------
                        // 10% Valid Address
                        //------------------------------------------------
                        10:
                        begin
                            assert(tr.randomize() with
                            {
                                addr inside {[32'h00000000:32'h000000FC]};
                                (addr % 4) == 0;
                            })
                            else
                                $fatal(1,"[GENERATOR] VALID_ADDRESS Randomization Failed");
                        end
                
                    endcase
                
                    if(tr.cmd == WRITE)
                        store_write_addr(tr.addr);
                
                end

                ADDRESS_SWEEP:
                begin
                    generate_address_sweep(tr);
                end

                //------------------------------------------------
                // Default
                //------------------------------------------------
                default:
                begin
                    $fatal(1,"[GENERATOR] Invalid Test Mode");
                end

            endcase

            tr.display("GENERATOR");

            gen2drv.put(tr.copy());

        end

        $display("\n=========================================");
        $display("GENERATOR COMPLETED");
        $display("TOTAL TRANSACTIONS : %0d", txn_count);
        $display("WRITE ADDRESSES STORED : %0d", written_addr_q.size());
        $display("=========================================\n");

    endtask

endclass