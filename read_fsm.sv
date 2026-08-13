import axi_pkg::*;

module read_fsm
(
    //---------------------------------------------------------
    // Global Signals
    //---------------------------------------------------------
    input  logic                     ACLK,
    input  logic                     ARESETn,

    //---------------------------------------------------------
    // AXI Read Address Channel
    //---------------------------------------------------------
    input  logic                     ARVALID,
    input  logic [ADDR_WIDTH-1:0]    ARADDR,
    output logic                     ARREADY,

    //---------------------------------------------------------
    // AXI Read Response Channel
    //---------------------------------------------------------
    output logic                     RVALID,
    output logic [DATA_WIDTH-1:0]    RDATA,
    output axi_resp_t                RRESP,
    input  logic                     RREADY,


    //---------------------------------------------------------
    // Memory Interface
    //---------------------------------------------------------
    output logic                     mem_read_req,
    input  logic                     mem_read_grant,
    output logic [INDEX_WIDTH-1:0]   mem_addr,
    input  logic [DATA_WIDTH-1:0]    mem_rdata

);

    // Registers

    logic [ADDR_WIDTH-1:0] araddr_reg;
    logic [DATA_WIDTH-1:0] rdata_reg;
    axi_resp_t rresp_reg;
    
    // Read FSM State
    rd_state_t rd_state;
    rd_state_t rd_next_state;
    
    // State Register
    always_ff @(posedge ACLK or negedge ARESETn)
    begin
        if(!ARESETn)
        begin
            rd_state <= RD_IDLE;
        end
        else
        begin
            rd_state <= rd_next_state;
        end
    end

    //---------------------------------------------------------
    // Transaction Registers
    always_ff @(posedge ACLK or negedge ARESETn)
    begin
        if(!ARESETn)
        begin

            araddr_reg <= '0;
            rdata_reg  <= '0;
            rresp_reg  <= RESP_OKAY;

        end
        else
        begin

            // Capture address and decide response
            if(ARVALID && ARREADY)
            begin

                araddr_reg <= ARADDR;
                if(ARADDR >=MAX_BYTE_ADDR)
                    rresp_reg <= RESP_SLVERR;
                else
                    rresp_reg <= RESP_OKAY;
            end
    
            // Capture memory data only for valid addresses
            if(rd_state == RD_CAPTURE)
                rdata_reg <= mem_rdata;
    
            // Transaction complete
            if( rd_state == RD_RESPOND && RREADY)
            begin
                araddr_reg <= '0;
                rdata_reg  <= '0;
                rresp_reg  <= RESP_OKAY;
            end
        end
    end

    // Next State Logic
    always_comb
    begin

        rd_next_state = rd_state;
        case(rd_state)

            // Wait for AXI Read Address
            RD_IDLE:
            begin

                if(ARVALID && ARREADY)
                begin

                    if(ARADDR >= MAX_BYTE_ADDR)
                        rd_next_state = RD_RESPOND;
                    else
                        rd_next_state = RD_EXECUTE;

                end
                else
                    rd_next_state = RD_IDLE;
            end

            // Start Memory Read
           RD_EXECUTE:
            begin

                if(mem_read_grant)
                    rd_next_state = RD_CAPTURE;
                else
                    rd_next_state = RD_EXECUTE;

            end

            // Capture Memory Output
            RD_CAPTURE:
            begin
                rd_next_state = RD_RESPOND;
            end

            // AXI Read Response
            RD_RESPOND:
            begin

                if(RVALID && RREADY)
                    rd_next_state = RD_IDLE;
                else
                    rd_next_state = RD_RESPOND;

            end
            default:
            begin
                rd_next_state = RD_IDLE;
            end
        endcase
    end
    //---------------------------------------------------------
    // Output Logic
    always_comb
    begin

        ARREADY    = 1'b0;
        RVALID     = 1'b0;
        RDATA      = rdata_reg;
        RRESP      = rresp_reg;
        
        mem_read_req = 1'b0;

        //-----------------------------------------------------
        // AXI address to memory index conversion
        //-----------------------------------------------------
        mem_addr = araddr_reg[INDEX_WIDTH+1:2];

        case(rd_state)

            //-------------------------------------------------
            // Accept Read Address
            //-------------------------------------------------
            RD_IDLE:
            begin
                ARREADY = (rd_state == RD_IDLE);
            end

            //-------------------------------------------------
            // Issue Memory Read
            //-------------------------------------------------
            RD_EXECUTE:
            begin
                mem_read_req = 1'b1;
            end

            //-------------------------------------------------
            // Memory Data Capture
            //-------------------------------------------------
            RD_CAPTURE:
            begin
            end

            //-------------------------------------------------
            // Send AXI Response
            //-------------------------------------------------
            RD_RESPOND:
            begin
                RVALID = 1'b1;
            end
            
            default: ;
        endcase
    end
endmodule
