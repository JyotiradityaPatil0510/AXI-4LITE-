import axi_pkg::*;
module axi_master
(
    input  logic                    ACLK,
    input  logic                    ARESETn,

    //---------------------------------------------------------
    // Driver Write Interface
    //---------------------------------------------------------
    input  logic                    wr_start,
    input  logic [ADDR_WIDTH-1:0]   wr_addr,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    input  logic [STRB_WIDTH-1:0]   wr_strb,

    output logic                    wr_done,
    output axi_resp_t               wr_resp,

    //---------------------------------------------------------
    // Driver Read Interface
    //---------------------------------------------------------
    input  logic                    rd_start,
    input  logic [ADDR_WIDTH-1:0]   rd_addr,

    output logic                    rd_done,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output axi_resp_t               rd_resp,

    //---------------------------------------------------------
    // AXI Write Address Channel
    //---------------------------------------------------------
    output logic                    AWVALID,
    output logic [ADDR_WIDTH-1:0]   AWADDR,
    input  logic                    AWREADY,

    //---------------------------------------------------------
    // AXI Write Data Channel
    //---------------------------------------------------------
    output logic                    WVALID,
    output logic [DATA_WIDTH-1:0]   WDATA,
    output logic [STRB_WIDTH-1:0]   WSTRB,
    input  logic                    WREADY,

    //---------------------------------------------------------
    // AXI Write Response Channel
    //---------------------------------------------------------
    input  logic                    BVALID,
    input  axi_resp_t               BRESP,
    output logic                    BREADY,

    //---------------------------------------------------------
    // AXI Read Address Channel
    //---------------------------------------------------------
    output logic                    ARVALID,
    output logic [ADDR_WIDTH-1:0]   ARADDR,
    input  logic                    ARREADY,

    //---------------------------------------------------------
    // AXI Read Data Channel
    //---------------------------------------------------------
    input  logic                    RVALID,
    input  logic [DATA_WIDTH-1:0]   RDATA,
    input  axi_resp_t               RRESP,
    output logic                    RREADY
);

    //---------------------------------------------------------
    // Write Command Registers
    //---------------------------------------------------------
    logic [ADDR_WIDTH-1:0] wr_addr_reg;
    logic [DATA_WIDTH-1:0] wr_data_reg;
    logic [STRB_WIDTH-1:0] wr_strb_reg;

    logic [ADDR_WIDTH-1:0] rd_addr_reg;// Read Command Registers
    logic [DATA_WIDTH-1:0] rd_data_reg;

    axi_resp_t wr_resp_reg,rd_resp_reg;

    //---------------------------------------------------------
    // AXI Handshake Flags
    //---------------------------------------------------------
    logic aw_done;
    logic w_done;
    
//    logic toggle; //assertions_used_logic 

    // Master Write FSM
    mw_state_t mw_state,mw_next_state;

    // Master Read FSM
    mr_state_t mr_state,mr_next_state;

    //---------------------------------------------------------
    // Write State Register
    //---------------------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETn)
    begin
        if(!ARESETn)
            mw_state <= MW_IDLE;
        else
            mw_state <= mw_next_state;
    end

    //---------------------------------------------------------
    // Read State Register
    //---------------------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETn)
    begin
        if(!ARESETn)
            mr_state <= MR_IDLE;
        else
            mr_state <= mr_next_state;
    end
    
//    //---------------------------------------------------------
//    // Temporary logic for assertion testing
//    //---------------------------------------------------------
//    always_ff @(posedge ACLK or negedge ARESETn)
//    begin
//        if(!ARESETn)
//            toggle <= 1'b0;
//        else if(AWVALID && !AWREADY)
//            toggle <= ~toggle;
//        else
//            toggle <= 1'b0;
//    end
    
    //---------------------------------------------------------
    // Transaction Registers
    //---------------------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETn)
    begin
        if(!ARESETn)
        begin
            //---------------------------------------------
            // Write Registers
            //---------------------------------------------
            wr_addr_reg <= '0;
            wr_data_reg <= '0;
            wr_strb_reg <= '0;
    
            //---------------------------------------------
            // Read Registers
            //---------------------------------------------
            rd_addr_reg <= '0;
            rd_data_reg <= '0;
    
            //---------------------------------------------
            // Response Registers
            //---------------------------------------------
            wr_resp_reg <= RESP_OKAY;
            rd_resp_reg <= RESP_OKAY;
    
            //---------------------------------------------
            // Handshake Flags
            //---------------------------------------------
            aw_done <= 1'b0;
            w_done  <= 1'b0;
        end
        else
        begin
    
            //-------------------------------------------------
            // Write Transaction Complete (Highest Priority)
            //-------------------------------------------------
            if(BVALID && BREADY)
            begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
            
                wr_addr_reg <= '0;
                wr_data_reg <= '0;
                wr_strb_reg <= '0;
            end
            //-------------------------------------------------
            // Capture New Write Transaction
            //-------------------------------------------------
            if(wr_start )
            begin
                wr_addr_reg <= wr_addr;
                wr_data_reg <= wr_data;
                wr_strb_reg <= wr_strb;
                wr_resp_reg <= RESP_OKAY;
            end
    
            //-------------------------------------------------
            // Read Transaction Complete (Highest Priority)
            //-------------------------------------------------
            if(RVALID && RREADY)
            begin
                rd_addr_reg <= '0;
            end
            //-------------------------------------------------
            // Capture New Read Transaction
            //-------------------------------------------------
            if(rd_start )
            begin
                rd_addr_reg <= rd_addr;
    
                rd_resp_reg <= RESP_OKAY;

            end
    
            //-------------------------------------------------
            // Write Address Handshake
            //-------------------------------------------------
            if(AWVALID && AWREADY)
                aw_done <= 1'b1;
    
            //-------------------------------------------------
            // Write Data Handshake
            //-------------------------------------------------
            if(WVALID && WREADY)
                w_done <= 1'b1;
    
    
            //-------------------------------------------------
            // Capture Write Response
            //-------------------------------------------------            
            if(mw_state == MW_RESP && BVALID)
            begin
                wr_resp_reg <= BRESP;
            end
    
            //-------------------------------------------------
            // Capture Read Response
            //-------------------------------------------------
            if(mr_state == MR_WAIT && RVALID)
            begin
                rd_data_reg <= RDATA;
                rd_resp_reg <= RRESP;
            end
    
        end
    end
    //---------------------------------------------------------
    // Write FSM Next State Logic
    //---------------------------------------------------------
    always_comb
    begin
        mw_next_state = mw_state;
    
        case(mw_state)
    
            //-------------------------------------------------
            // Wait for Write Command
            //-------------------------------------------------
            MW_IDLE:
            begin
                if(wr_start)
                    mw_next_state = MW_ADDR_DATA;
                else
                    mw_next_state = MW_IDLE;
            end
    
            //-------------------------------------------------
            // Complete Address & Data Handshakes
            //-------------------------------------------------
            MW_ADDR_DATA:
            begin
                if(aw_done && w_done)
                    mw_next_state = MW_RESP;
                else
                    mw_next_state = MW_ADDR_DATA;
            end
    
            //-------------------------------------------------
            // Wait for Write Response
            //-------------------------------------------------
            MW_RESP:
            begin
                if(BVALID && BREADY)
                    mw_next_state = MW_IDLE;
                else
                    mw_next_state = MW_RESP;
            end
    
            //-------------------------------------------------
            // Transaction Complete
            //-------------------------------------------------

            default:
            begin
                mw_next_state = MW_IDLE;
            end
    
        endcase
    end

    //---------------------------------------------------------
    // Read FSM Next State Logic
    //---------------------------------------------------------
    always_comb
    begin
        mr_next_state = mr_state;
    
        case(mr_state)
    
            //-------------------------------------------------
            // Wait for Read Command
            //-------------------------------------------------
            MR_IDLE:
            begin
                if(rd_start)
                    mr_next_state = MR_ADDR;
                else
                    mr_next_state = MR_IDLE;
            end
    
            //-------------------------------------------------
            // Wait for Address Handshake
            //-------------------------------------------------
            MR_ADDR:
            begin
                if(ARVALID && ARREADY)
                    mr_next_state = MR_WAIT;
                else
                    mr_next_state=MR_ADDR;
            end
    
            //-------------------------------------------------
            // Wait for Read Data
            //-------------------------------------------------
            MR_WAIT:
            begin
                if(RVALID && RREADY)
                    mr_next_state = MR_IDLE;
                else
                    mr_next_state = MR_WAIT;
            end
            
            default:
                mr_next_state = MR_IDLE;
    
        endcase
    end

     //---------------------------------------------------------
    // Output Logic
    //---------------------------------------------------------
    always_comb
    begin
   
        // Driver Outputs
        wr_done = (mw_state == MW_RESP) && BVALID && BREADY;
        wr_resp = wr_resp_reg;
    
        rd_done = (mr_state == MR_WAIT) && RVALID && RREADY;
        rd_data = rd_data_reg;
        rd_resp = rd_resp_reg;
    
        // AXI Write Address Channel
        AWVALID = 1'b0;
        AWADDR  = wr_addr_reg;
//        AWADDR = wr_addr_reg + toggle;  //assertions
        
        
    
        //-----------------------------------------------------
        // AXI Write Data Channel
        //-----------------------------------------------------
        WVALID = 1'b0;
        WDATA  = wr_data_reg;
        WSTRB  = wr_strb_reg;
    
        BREADY = 1'b0;// AXI Write Response Channel
    
        // AXI Read Address Channel
        ARVALID = 1'b0;
        ARADDR  = rd_addr_reg;

        RREADY = 1'b0;// AXI Read Data Channel
    
        // Write FSM Outputs
        case(mw_state)
    
            MW_IDLE:// Idle
            begin
            end
    
            MW_ADDR_DATA:// Address/Data Phase
            begin
    
                if(!aw_done)
                    AWVALID = 1'b1;
    
                if(!w_done)
                    WVALID = 1'b1;
    
            end

            MW_RESP:// Wait for BRESP
            begin
                BREADY = 1'b1;
            end
   
            default: ;   
        endcase
        
         // Read FSM Outputs
        case(mr_state)
        
            MR_IDLE:// Idle
            begin
            end

            MR_ADDR:// Send Address
            begin
                ARVALID = 1'b1;
            end
            
            MR_WAIT:// Wait for Read Data
            begin
                RREADY = 1'b1;
            end 
            
            default: ;  
        endcase   
    end
endmodule