
import axi_pkg::*;

interface axi_if;

    //---------------------------------------------------------
    // Global Signals
    //---------------------------------------------------------
    logic ACLK;
    logic ARESETn;

    //---------------------------------------------------------
    // Driver Write Interface
    //---------------------------------------------------------
    logic                    wr_start;
    logic [ADDR_WIDTH-1:0]   wr_addr;
    logic [DATA_WIDTH-1:0]   wr_data;
    logic [STRB_WIDTH-1:0]   wr_strb;

    logic                    wr_done;
    axi_resp_t               wr_resp;

    //---------------------------------------------------------
    // Driver Read Interface
    //---------------------------------------------------------
    logic                    rd_start;
    logic [ADDR_WIDTH-1:0]   rd_addr;

    logic                    rd_done;
    logic [DATA_WIDTH-1:0]   rd_data;
    axi_resp_t               rd_resp;

endinterface
