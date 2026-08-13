import axi_pkg::*;
module slave_top
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
    // AXI Read Address Channel
    //---------------------------------------------------------
    input  logic                    ARVALID,
    input  logic [ADDR_WIDTH-1:0]   ARADDR,
    output logic                    ARREADY,

    //---------------------------------------------------------
    // AXI Read Data Channel
    //---------------------------------------------------------
    output logic                    RVALID,
    output logic [DATA_WIDTH-1:0]   RDATA,
    output axi_resp_t               RRESP,
    input  logic                    RREADY
);

    //---------------------------------------------------------
    // Write FSM -> Slave Top
    //---------------------------------------------------------
    logic                    wr_mem_write_req;
    logic [INDEX_WIDTH-1:0]  wr_mem_addr;
    logic [DATA_WIDTH-1:0]   wr_mem_wdata;
    logic [STRB_WIDTH-1:0]   wr_mem_wstrb;

    //---------------------------------------------------------
    // Read FSM -> Slave Top
    //---------------------------------------------------------
    logic                    rd_mem_read_req;
    logic                    rd_mem_read_grant;
    logic [INDEX_WIDTH-1:0]  rd_mem_addr;

    //---------------------------------------------------------
    // Slave Top -> Memory
    //---------------------------------------------------------
    logic                    mem_write_en;
    logic                    mem_read_en;

    logic [INDEX_WIDTH-1:0]  mem_addr;
    logic [DATA_WIDTH-1:0]   mem_wdata;
    logic [STRB_WIDTH-1:0]   mem_wstrb;

    //---------------------------------------------------------
    // Memory -> Read FSM
    //---------------------------------------------------------
    logic [DATA_WIDTH-1:0]   mem_rdata;

    //---------------------------------------------------------
    // Write FSM
    //---------------------------------------------------------
    write_fsm u_write_fsm
    (
        .ACLK          (ACLK),
        .ARESETn       (ARESETn),

        .AWVALID       (AWVALID),
        .AWADDR        (AWADDR),
        .AWREADY       (AWREADY),

        .WVALID        (WVALID),
        .WDATA         (WDATA),
        .WSTRB         (WSTRB),
        .WREADY        (WREADY),

        .BVALID        (BVALID),
        .BRESP         (BRESP),
        .BREADY        (BREADY),

        .mem_write_req (wr_mem_write_req),
        .mem_addr      (wr_mem_addr),
        .mem_wdata     (wr_mem_wdata),
        .mem_wstrb     (wr_mem_wstrb)
    );

    //---------------------------------------------------------
    // Read FSM
    //---------------------------------------------------------
    read_fsm u_read_fsm
    (
        .ACLK            (ACLK),
        .ARESETn         (ARESETn),

        .ARVALID         (ARVALID),
        .ARADDR          (ARADDR),
        .ARREADY         (ARREADY),

        .RVALID          (RVALID),
        .RDATA           (RDATA),
        .RRESP           (RRESP),
        .RREADY          (RREADY),

        .mem_read_req    (rd_mem_read_req),
        .mem_read_grant  (rd_mem_read_grant),
        .mem_addr        (rd_mem_addr),
        .mem_rdata       (mem_rdata)
    );

    //---------------------------------------------------------
    // Memory
    //---------------------------------------------------------
    memory u_memory
    (
        .clk        (ACLK),

        .write_en   (mem_write_en),
        .read_en    (mem_read_en),

        .addr       (mem_addr),

        .wdata      (mem_wdata),
        .wstrb      (mem_wstrb),

        .rdata      (mem_rdata)
    );

    //---------------------------------------------------------
    // Simple Memory Arbiter
    // Write has priority over Read
    //---------------------------------------------------------
    always_comb
    begin

        //-----------------------------------------------------
        // Default Values
        //-----------------------------------------------------
        mem_write_en      = 1'b0;
        mem_read_en       = 1'b0;

        mem_addr          = '0;
        mem_wdata         = '0;
        mem_wstrb         = '0;

        rd_mem_read_grant = 1'b0;

        //-----------------------------------------------------
        // Write Request (Higher Priority)
        //-----------------------------------------------------
        if (wr_mem_write_req)
        begin
            mem_write_en = 1'b1;

            mem_addr     = wr_mem_addr;
            mem_wdata    = wr_mem_wdata;
            mem_wstrb    = wr_mem_wstrb;
        end

        //-----------------------------------------------------
        // Read Request
        //-----------------------------------------------------
        else if(rd_mem_read_req)
        begin
            mem_read_en       = 1'b1;
            rd_mem_read_grant = 1'b1;
            mem_addr          = rd_mem_addr;
        end

    end

endmodule