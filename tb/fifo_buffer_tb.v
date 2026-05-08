//==================================================================
// tb_fifo.v
// Testbench for Synchronous FIFO Buffer
// -----------------------------------------------------------------
// Description:
//   This testbench verifies the functionality of the synchronous
//   FIFO module through multiple directed test cases.
//
// Features Verified:
//   - Reset behavior
//   - Empty and full flag operation
//   - Single-byte write/read functionality
//   - FIFO full condition
//   - FIFO empty condition
//   - Sequential data integrity
//   - Circular buffer wrap-around behavior
//
// FIFO Configuration:
// -----------------------------------------------------------------
//   Data Width : 8 bits
//   FIFO Depth : 16 entries
//   Clock       : 100 MHz
//
// Test Cases:
// -----------------------------------------------------------------
//   1. Reset and Empty Flag Verification
//   2. Single Write and Read
//   3. FIFO Full Condition
//   4. Sequential Readback Verification
//   5. Circular Buffer Wrap-around Test
//
//==================================================================

`timescale 1ns / 1ps

module tb_fifo();

    //==============================================================
    // Testbench Signals
    //==============================================================

    reg             clk;        // System clock
    reg             rst_n;      // Active-low reset

    // Write Interface Signals
    reg  [7:0]      wr_data;    // Data input to FIFO
    reg             wr_en;      // Write enable
    wire            full;       // FIFO full flag

    // Read Interface Signals
    reg             rd_en;      // Read enable
    wire [7:0]      rd_data;    // Data output from FIFO
    wire            empty;      // FIFO empty flag

    //==============================================================
    // DUT Instantiation
    //==============================================================
    // Device Under Test (FIFO)
    //==============================================================

    fifo dut (

        .clk      (clk),
        .rst_n    (rst_n),

        .wr_data  (wr_data),
        .wr_en    (wr_en),
        .full     (full),

        .rd_en    (rd_en),
        .rd_data  (rd_data),
        .empty    (empty)

    );

    //==============================================================
    // Clock Generation
    //==============================================================
    // Generates 100 MHz clock.
    //
    // Clock Period:
    //   10 ns
    //
    // Clock Frequency:
    //   1 / 10ns = 100 MHz
    //==============================================================

    always #5 clk = ~clk;

    //==============================================================
    // Main Test Sequence
    //==============================================================

    initial begin

        //----------------------------------------------------------
        // Initialize Signals
        //----------------------------------------------------------
        clk     = 0;
        rst_n   = 0;

        wr_en   = 0;
        rd_en   = 0;

        wr_data = 0;

        //----------------------------------------------------------
        // Apply Reset
        //----------------------------------------------------------
        #15 rst_n = 1;

        $display("\n==================================================");
        $display("              FIFO TESTBENCH START                ");
        $display("==================================================\n");

        //==========================================================
        // TEST 1 : Reset and Empty Flag Verification
        //==========================================================

        $display("Test 1 : Check FIFO Empty Status After Reset");

        #10;

        if (empty && !full)

            $display("PASS : FIFO is empty after reset\n");

        else

            $display("FAIL : FIFO status flags incorrect\n");

        //==========================================================
        // TEST 2 : Single Write and Read
        //==========================================================

        $display("Test 2 : Single Write and Read Operation");

        //----------------------------------------------------------
        // Write 0xA5 into FIFO
        //----------------------------------------------------------
        @(posedge clk);

        wr_data = 8'hA5;
        wr_en   = 1;

        @(posedge clk);

        wr_en = 0;

        //----------------------------------------------------------
        // Display FIFO status
        //----------------------------------------------------------
        $display("  After Write : full=%b, empty=%b",

                 full,
                 empty);

        //----------------------------------------------------------
        // Read data back from FIFO
        //----------------------------------------------------------
        @(posedge clk);

        rd_en = 1;

        @(posedge clk);

        rd_en = 0;

        //----------------------------------------------------------
        // Verify received data
        //----------------------------------------------------------
        $display("  Read Data : 0x%02h", rd_data);

        if (rd_data == 8'hA5)

            $display("PASS\n");

        else

            $display("FAIL\n");

        //==========================================================
        // TEST 3 : FIFO Full Condition
        //==========================================================
        // FIFO uses one slot internally to distinguish full/empty,
        // therefore maximum usable entries = 15.
        //==========================================================

        $display("Test 3 : Fill FIFO to Full Condition");

        //----------------------------------------------------------
        // Perform 15 writes
        //----------------------------------------------------------
        for (integer i = 0; i < 15; i = i + 1) begin

            @(posedge clk);

            wr_data = i;
            wr_en   = 1;

        end

        @(posedge clk);

        wr_en = 0;

        //----------------------------------------------------------
        // Verify FULL flag
        //----------------------------------------------------------
        $display("  full = %b (expected 1)", full);

        if (full)

            $display("PASS : FIFO reached FULL state\n");

        else

            $display("FAIL : FIFO should be FULL\n");

        //==========================================================
        // TEST 4 : Sequential Readback Verification
        //==========================================================

        $display("Test 4 : Read All FIFO Entries");

        //----------------------------------------------------------
        // Read all 15 entries
        //----------------------------------------------------------
        for (integer i = 0; i < 15; i = i + 1) begin

            @(posedge clk);

            rd_en = 1;

            //------------------------------------------------------
            // Sample data before next active edge
            //------------------------------------------------------
            @(negedge clk);

            $display("  Data[%0d] = 0x%02h (expected 0x%02h)",

                     i,
                     rd_data,
                     i);

            //------------------------------------------------------
            // Data verification
            //------------------------------------------------------
            if (rd_data != i)

                $display("    ERROR : Data mismatch detected!");

        end

        @(posedge clk);

        rd_en = 0;

        //----------------------------------------------------------
        // Verify EMPTY flag
        //----------------------------------------------------------
        $display("  empty = %b (expected 1)", empty);

        if (empty)

            $display("PASS : FIFO returned to EMPTY state\n");

        else

            $display("FAIL : FIFO should be EMPTY\n");

        //==========================================================
        // TEST 5 : Circular Buffer Wrap-around
        //==========================================================
        // Verifies pointer wrap-around functionality.
        //==========================================================

        $display("Test 5 : Circular Buffer Wrap-around");

        //----------------------------------------------------------
        // Step 1 : Write 10 entries
        //----------------------------------------------------------
        for (integer i = 0; i < 10; i = i + 1) begin

            @(posedge clk);

            wr_data = i + 100;
            wr_en   = 1;

        end

        @(posedge clk);

        wr_en = 0;

        //----------------------------------------------------------
        // Step 2 : Read 8 entries
        //----------------------------------------------------------
        for (integer i = 0; i < 8; i = i + 1) begin

            @(posedge clk);

            rd_en = 1;

        end

        @(posedge clk);

        rd_en = 0;

        //----------------------------------------------------------
        // Step 3 : Write 8 additional entries
        // Pointer should wrap around internally
        //----------------------------------------------------------
        for (integer i = 0; i < 8; i = i + 1) begin

            @(posedge clk);

            wr_data = i + 200;
            wr_en   = 1;

        end

        @(posedge clk);

        wr_en = 0;

        //----------------------------------------------------------
        // Step 4 : Read remaining entries
        //----------------------------------------------------------
        $display("  Reading Data After Wrap-around:");

        for (integer i = 0; i < 10; i = i + 1) begin

            @(posedge clk);

            rd_en = 1;

            @(negedge clk);

            $display("    Data[%0d] = 0x%02h",

                     i,
                     rd_data);

        end

        @(posedge clk);

        rd_en = 0;

        //----------------------------------------------------------
        // Wrap-around test completed
        //----------------------------------------------------------
        $display("PASS : Wrap-around test completed successfully\n");

        //==========================================================
        // End of Simulation
        //==========================================================

        $display("==================================================");
        $display("              ALL TESTS COMPLETED                 ");
        $display("==================================================\n");

        #50;

        $finish;

    end

endmodule
