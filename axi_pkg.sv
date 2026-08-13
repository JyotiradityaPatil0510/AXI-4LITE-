


`ifndef AXI_PKG_SV
`define AXI_PKG_SV

package axi_pkg;

    // AXI4-Lite Global Configuration
    parameter int unsigned ADDR_WIDTH = 32;
    parameter int unsigned DATA_WIDTH = 32;

    // Number of byte lanes
    parameter int unsigned STRB_WIDTH = DATA_WIDTH/8;

    // Number of memory words
    parameter int unsigned MEM_DEPTH  = 64;


    // Number of bits required to address MEM_DEPTH locations
    localparam int INDEX_WIDTH = $clog2(MEM_DEPTH);
    localparam MAX_BYTE_ADDR = MEM_DEPTH*(DATA_WIDTH/8);
    
    
    //mode_selector 
    typedef enum
    {
        CONTINUOUS_WRITE,
        CONTINUOUS_READ,
        ALTERNATE_RW,
        RANDOM_RW,
        SAME_ADDRESS,
        INVALID_ADDRESS,
        ADDRESS_SWEEP
    } test_mode_t;

    
    
    
    typedef enum {READ,WRITE} cmd_t;


    // AXI4-Lite Response Codes
    typedef enum logic [1:0]
    {
        RESP_OKAY   = 2'b00,
        RESP_SLVERR = 2'b10,
        RESP_DECERR = 2'b11
    } axi_resp_t;
    
    
    // Write FSM States
    typedef enum logic [1:0]
    {
        WR_IDLE,
        WR_COLLECT,
        WR_EXECUTE,
        WR_RESPOND
    } wr_state_t;


    // Read FSM States
    typedef enum logic [1:0]
    {
        RD_IDLE,
        RD_EXECUTE,
        RD_CAPTURE,
        RD_RESPOND
    } rd_state_t;
    
    //---------------------------------------------------------
    // AXI Master Write FSM
    //---------------------------------------------------------
    typedef enum logic [1:0]
    {
        MW_IDLE,
        MW_ADDR_DATA,
        MW_RESP
    } mw_state_t;
        
    //---------------------------------------------------------
    // AXI Master Read FSM
    //---------------------------------------------------------
    typedef enum logic [1:0]
    {
        MR_IDLE,
        MR_ADDR,
        MR_WAIT
    } mr_state_t;
    
endpackage

`endif
