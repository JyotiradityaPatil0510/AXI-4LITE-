import axi_pkg::*;

module write_fsm
(
    //---------------------------------------------------------
    // Global Signals
    //---------------------------------------------------------
    input  logic                    ACLK,
    input  logic                    ARESETn,

    //---------------------------------------------------------
    // AXI Write Address Channel
    //---------------------------------------------------------
    input  logic                    AWVALID,
    input  logic [ADDR_WIDTH-1:0]   AWADDR,
    output logic                    AWREADY,

    //---------------------------------------------------------
    // AXI Write Data Channel
    //---------------------------------------------------------
    input  logic                    WVALID,
    input  logic [DATA_WIDTH-1:0]   WDATA,
    input  logic [STRB_WIDTH-1:0]   WSTRB,
    output logic                    WREADY,

    //---------------------------------------------------------
    // AXI Write Response Channel
    //---------------------------------------------------------
    output logic                    BVALID,
    output axi_resp_t               BRESP,
    input  logic                    BREADY,

    //---------------------------------------------------------
    // Memory Interface
    //---------------------------------------------------------
    output logic                    mem_write_req,
    output logic [INDEX_WIDTH-1:0]  mem_addr,
    output logic [DATA_WIDTH-1:0]   mem_wdata,
    output logic [STRB_WIDTH-1:0]   mem_wstrb
);
    //---------------------------------------------------------
    // FSM Registers
    //---------------------------------------------------------
    wr_state_t wr_state,wr_next_state;
        
    //---------------------------------------------------------
    // Captured Transaction Information
    //---------------------------------------------------------
    logic [ADDR_WIDTH-1:0]  awaddr_reg;
    logic [DATA_WIDTH-1:0]  wdata_reg;
    logic [STRB_WIDTH-1:0]  wstrb_reg;
    
    //---------------------------------------------------------
    // Handshake Flags
    //---------------------------------------------------------
    logic aw_captured;
    logic w_captured;
    
    axi_resp_t bresp_reg;// Write Response Register
    
    //---------------------------------------------------------
    // Write State Register
    //---------------------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETn)
    begin
        if(!ARESETn)
            wr_state <= WR_IDLE;
        else
            wr_state <= wr_next_state;
    end
    
    //---------------------------------------------------------
    // Transaction Capture Registers
    //---------------------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETn)
    begin
        if(!ARESETn)
        begin
            awaddr_reg  <= '0;
            wdata_reg   <= '0;
            wstrb_reg   <= '0;
    
            aw_captured <= 1'b0;
            w_captured  <= 1'b0;
    
            bresp_reg   <= RESP_OKAY;
        end
        else
        begin
            //-----------------------------------------
            // Capture Write Address
            //-----------------------------------------
            if(AWVALID && AWREADY)
            begin
                awaddr_reg  <= AWADDR;
                aw_captured <= 1'b1;
                if(AWADDR >= MAX_BYTE_ADDR)
                    bresp_reg <= RESP_SLVERR;
                else
                    bresp_reg <= RESP_OKAY;
            end
            //-----------------------------------------
            // Capture Write Data
            //-----------------------------------------
            if(WVALID && WREADY)
            begin
                wdata_reg  <= WDATA;
                wstrb_reg  <= WSTRB;
                w_captured <= 1'b1;
            end
             //-----------------------------------------
            // Transaction Complete
            //-----------------------------------------
            if(BVALID && BREADY)
            begin
                awaddr_reg  <= '0;
                wdata_reg   <= '0;
                wstrb_reg   <= '0;
    
                aw_captured <= 1'b0;
                w_captured  <= 1'b0;
    
                bresp_reg   <= RESP_OKAY;
            end
        end
    end
    
    //---------------------------------------------------------
    // Next State Logic
    //---------------------------------------------------------
    
    always_comb
    begin
    
        // Default State
        wr_next_state = wr_state;
    
        case(wr_state)
    
            //-------------------------------------------------
            // WR_IDLE
            //-------------------------------------------------
            WR_IDLE:
            begin
    
                // Both Address and Data received
                if(aw_captured && w_captured)
                begin
                    if(awaddr_reg >= MAX_BYTE_ADDR)
                        wr_next_state = WR_RESPOND;
                    else
                        wr_next_state = WR_EXECUTE;
                end

                // Either Address or Data received
                else if(aw_captured || w_captured)
                    wr_next_state = WR_COLLECT;
    
                // Nothing received
                else
                    wr_next_state = WR_IDLE;
    
            end
    
    
            //-------------------------------------------------
            // WR_COLLECT
            //-------------------------------------------------
            WR_COLLECT:
            begin
    
                // Waiting for second handshake
                if(aw_captured && w_captured)
                begin
                    if(awaddr_reg >= MAX_BYTE_ADDR)
                        wr_next_state = WR_RESPOND;
                    else
                        wr_next_state = WR_EXECUTE;
                end
                else
                    wr_next_state = WR_COLLECT;
    
            end
    
    
            //-------------------------------------------------
            // WR_EXECUTE
            //-------------------------------------------------
            WR_EXECUTE:
            begin 
                wr_next_state = WR_RESPOND;
            end
    
    
            //-------------------------------------------------
            // WR_RESPOND
            //-------------------------------------------------
            WR_RESPOND:
            begin
    
                if(BVALID && BREADY)
                    wr_next_state = WR_IDLE;
                else
                    wr_next_state = WR_RESPOND;
    
            end
    
    
            //-------------------------------------------------
            // Default
            //-------------------------------------------------
            default:
                wr_next_state = WR_IDLE;
    
        endcase
    
    end
    
    
    //---------------------------------------------------------
    // output logic
    //---------------------------------------------------------
    always_comb
    begin
        // Defaults
        AWREADY      = 1'b0;
        WREADY       = 1'b0;
        BVALID       = 1'b0;
    
        BRESP        = bresp_reg;
    
        mem_write_req = 1'b0;
    
        // Continuously drive captured values
        mem_addr     = awaddr_reg[INDEX_WIDTH+1:2];// Convert AXI byte address to memory word index
        mem_wdata    = wdata_reg;
        mem_wstrb    = wstrb_reg;
    
        case (wr_state)
    
            WR_IDLE:
            begin
                AWREADY = !aw_captured;
                WREADY  = !w_captured;
            end
    
            WR_COLLECT:
            begin
                AWREADY = !aw_captured;
                WREADY  = !w_captured;
            end
    
            WR_EXECUTE:
            begin
                    mem_write_req = 1'b1;
            end
    
            WR_RESPOND:
            begin
                BVALID = 1'b1;
            end
    
            default: ;
        endcase
    end
    
endmodule