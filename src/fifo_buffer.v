//==================================================================
// fifo.v
// Reusable Synchronous FIFO Buffer
// -----------------------------------------------------------------
// Description:
//   This module implements a simple synchronous FIFO
//   (First-In First-Out) memory buffer for UART TX/RX buffering
//   and general-purpose data storage.
//
// Features:
//   - Synchronous read and write operations
//   - Circular buffer implementation
//   - Independent read/write interfaces
//   - Full and empty status flags
//   - Parameterized depth and pointer width
//   - 8-bit data width
//
// Applications:
//   - UART transmit buffering
//   - UART receive buffering
//   - Streaming data pipelines
//   - Producer-consumer buffering
//
// FIFO Characteristics:
// -----------------------------------------------------------------
//   FIFO Type     : Synchronous FIFO
//   Data Width    : 8 bits
//   FIFO Depth    : 16 entries
//   Address Width : 4 bits
//
// Notes:
// -----------------------------------------------------------------
//   - Read and write occur on rising edge of clock
//   - FIFO uses circular pointer incrementing
//   - Pointer wrap-around occurs automatically due to fixed width
//   - Full condition reserves one slot to distinguish from empty
//
//==================================================================

module fifo (

    //==============================================================
    // Port Declarations
    //==============================================================

    input wire              clk,        // System clock
    input wire              rst_n,      // Active-low asynchronous reset

    //==============================================================
    // Write Interface
    //==============================================================

    input wire [7:0]        wr_data,    // Data to be written into FIFO
    input wire              wr_en,      // Write enable signal

    output wire             full,       // FIFO full status flag

    //==============================================================
    // Read Interface
    //==============================================================

    input wire              rd_en,      // Read enable signal

    output reg [7:0]        rd_data,    // Data read from FIFO
    output wire             empty       // FIFO empty status flag
);

    //==============================================================
    // FIFO Parameters
    //==============================================================

    localparam DEPTH     = 16;   // Number of FIFO storage locations
    localparam PTR_WIDTH = 4;    // Pointer width for addressing

    //==============================================================
    // Internal Memory and Pointers
    //==============================================================

    // FIFO memory array
    reg [7:0] mem [0:DEPTH-1];
    // Write pointer
    reg [PTR_WIDTH-1:0] wr_ptr;
    // Read pointer
    reg [PTR_WIDTH-1:0] rd_ptr;

    //==============================================================
    // FIFO Status Flags
    //==============================================================
    // EMPTY Condition:
    //   FIFO is empty when write pointer equals read pointer.
    //
    // FULL Condition:
    //   FIFO is considered full when incrementing the write
    //   pointer would make it equal to the read pointer.
    //
    // NOTE:
    //   One memory location is intentionally unused to
    //   distinguish FULL from EMPTY condition.
    //==============================================================

    assign full  = ((wr_ptr + 1'b1) == rd_ptr);
    assign empty = (wr_ptr == rd_ptr);

    //==============================================================
    // FIFO Write Logic
    //==============================================================
    // Writes data into FIFO memory when:
    //   - Write enable is asserted
    //   - FIFO is not full
    //
    // Write pointer automatically wraps around because of fixed
    // pointer width.
    //==============================================================

    always @(posedge clk or negedge rst_n) begin

        //----------------------------------------------------------
        // Asynchronous Reset
        //----------------------------------------------------------
        if (!rst_n) begin

            wr_ptr <= 0;

        end 
        else if (wr_en && !full) begin

            //------------------------------------------------------
            // Store input data into current write location
            //------------------------------------------------------
            mem[wr_ptr] <= wr_data;

            //------------------------------------------------------
            // Increment write pointer (circular increment)
            //------------------------------------------------------
            wr_ptr <= wr_ptr + 1'b1;

        end
    end

    //==============================================================
    // FIFO Read Logic
    //==============================================================
    // Reads data from FIFO memory when:
    //   - Read enable is asserted
    //   - FIFO is not empty
    //
    // Read pointer automatically wraps around because of fixed
    // pointer width.
    //==============================================================

    always @(posedge clk or negedge rst_n) begin

        //----------------------------------------------------------
        // Asynchronous Reset
        //----------------------------------------------------------
        if (!rst_n) begin

            rd_ptr  <= 0;
            rd_data <= 8'b0;

        end 
        else if (rd_en && !empty) begin

            //------------------------------------------------------
            // Read data from current FIFO location
            //------------------------------------------------------
            rd_data <= mem[rd_ptr];

            //------------------------------------------------------
            // Increment read pointer (circular increment)
            //------------------------------------------------------
            rd_ptr <= rd_ptr + 1'b1;

        end
    end

endmodule
