import axi_pkg::*;
module memory
(
    input  logic                     clk,
    input  logic                     write_en,
    input  logic                     read_en,

    //---------------------------------------------------------
    // Word Address (Byte Offset Already Removed)
    //---------------------------------------------------------
    input  logic [INDEX_WIDTH-1:0]   addr,

    //---------------------------------------------------------
    // Write Data
    //---------------------------------------------------------
    input  logic [DATA_WIDTH-1:0]    wdata,

    //---------------------------------------------------------
    // Write Strobes (1 bit per byte)
    //---------------------------------------------------------
    input  logic [STRB_WIDTH-1:0]    wstrb,

    //---------------------------------------------------------
    // Read Data
    //---------------------------------------------------------
    output logic [DATA_WIDTH-1:0]    rdata
);

    //---------------------------------------------------------
    // Memory Array
    //---------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    //---------------------------------------------------------
    // Initialize Memory
    //---------------------------------------------------------
    integer i;
    
    initial
    begin
        for(i = 0; i < MEM_DEPTH; i = i + 1)
            mem[i] = '0;
    end
    
    //---------------------------------------------------------
    // Memory Read / Write
    //---------------------------------------------------------
    always_ff @(posedge clk)
    begin

        //-----------------------------------------------------
        // Write Operation
        //-----------------------------------------------------
        if(write_en)
        begin
            for(int unsigned i = 0; i < STRB_WIDTH; i++)
            begin
                if(wstrb[i])
                    mem[addr][8*i +: 8] <= wdata[8*i +: 8];
            end
        end

        //-----------------------------------------------------
        // Read Operation (Synchronous Read)
        //-----------------------------------------------------
        if(read_en)
            rdata <= mem[addr];
    end

endmodule