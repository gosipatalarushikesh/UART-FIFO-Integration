//==================================================================
// tb_baud_rate_generator.v
// UART Baud Rate Generator Testbench
// -----------------------------------------------------------------
// Description:
//   This testbench verifies the functionality and timing accuracy
//   of the UART baud rate generator module.
//
// Features:
//   - Generates a 50 MHz system clock
//   - Applies asynchronous reset
//   - Monitors TX and RX enable pulses
//   - Measures actual TX baud rate using simulation time
//   - Displays internal DUT counter values
//   - Calculates baud-rate error percentage
//
// Measurement Method:
//   The baud rate is calculated using the time difference between
//   consecutive TX enable pulses:
//
//       Baud Rate = 1 / Pulse Period
//
// Since simulation time is in nanoseconds:
//
//       Baud Rate = 1,000,000,000 / Time_Difference(ns)
//
// DUT Configuration:
// -----------------------------------------------------------------
//   System Clock : 50 MHz
//   UART Baud    : 9600 bps
//   RX Oversample: 16x
//
// Expected Results:
// -----------------------------------------------------------------
//   TX enable pulse every ~104.16 us
//   RX enable pulse every ~6.51 us
//
//==================================================================

module tb_baud_rate_generator;

    //==============================================================
    // Testbench Signals
    //==============================================================

    reg        clk;          // System clock
    reg        rst_n;        // Active-low reset

    wire       rx_enb;       // RX oversampling enable pulse
    wire       tx_enb;       // TX baud enable pulse

    //==============================================================
    // Simulation Monitoring Variables
    //==============================================================

    reg [31:0] cycle_count = 0;

    //==============================================================
    // Baud Rate Measurement Variables
    //==============================================================

    integer    tx_pulse      = 0;    // Counts TX enable pulses
    reg [63:0] prev_tx_time  = 0;    // Stores previous TX pulse time
    real       baud_rate     = 0.0;  // Measured baud rate

    //==============================================================
    // DUT Instantiation
    //==============================================================
    // Device Under Test
    //==============================================================

    baud_rate_generator dut (.*);

    //==============================================================
    // Clock Generation
    //==============================================================
    // Generates 50 MHz clock
    //
    // Clock Period:
    //   20 ns
    //
    // Clock Frequency:
    //   1 / 20ns = 50 MHz
    //==============================================================

    initial begin

        clk = 0;

        forever #10 clk = ~clk;

    end

    //==============================================================
    // Clock Cycle Counter
    //==============================================================
    // Tracks total active simulation clock cycles.
    //==============================================================

    always @(posedge clk) begin

        if (rst_n)
            cycle_count <= cycle_count + 1;

    end

    //==============================================================
    // TX Baud Rate Measurement Logic
    //==============================================================
    // Measures baud rate using time interval between
    // consecutive TX enable pulses.
    //
    // Formula:
    //   Baud Rate = 1e9 / Pulse_Period(ns)
    //==============================================================

    always @(posedge tx_enb) begin

        //----------------------------------------------------------
        // Count TX pulses
        //----------------------------------------------------------
        tx_pulse = tx_pulse + 1;

        //----------------------------------------------------------
        // Store first pulse timestamp
        //----------------------------------------------------------
        if (tx_pulse == 1) begin

            prev_tx_time = $time;

        end 
        else begin

            //------------------------------------------------------
            // Calculate instantaneous baud rate
            //------------------------------------------------------
            if (prev_tx_time != 0) begin

                baud_rate =
                    1_000_000_000.0 / ($time - prev_tx_time);

            end

            //------------------------------------------------------
            // Update previous timestamp
            //------------------------------------------------------
            prev_tx_time = $time;

        end
    end

    //==============================================================
    // Reset Measurement Variables
    //==============================================================
    // Clears measurement counters and timing values whenever
    // reset is asserted.
    //==============================================================

    always @(negedge rst_n) begin

        tx_pulse     = 0;
        prev_tx_time = 0;
        baud_rate    = 0.0;

    end

    //==============================================================
    // Simulation Initialization & Header Display
    //==============================================================

    initial begin

        $display("====================================================================");
        $display("        BAUD RATE GENERATOR TESTBENCH - SIMULATION START           ");
        $display("====================================================================");

        $display("   Time(ns)    Cycles    TX_Cnt   RX_Cnt   TX_enb   RX_enb");

        $display("--------------------------------------------------------------------");

        //----------------------------------------------------------
        // Apply Reset
        //----------------------------------------------------------
        rst_n = 0;

        #50;

        rst_n = 1;

        #30;

    end

    //==============================================================
    // Pulse Monitoring Display
    //==============================================================
    // Displays DUT internal counter values whenever TX or RX
    // enable pulses occur.
    //==============================================================

    always @(posedge tx_enb or posedge rx_enb) begin

        $display("%10t   %8d   %6d   %6d      %b        %b",

                 $time,
                 cycle_count,

                 dut.tx_counter,
                 dut.rx_counter,

                 tx_enb,
                 rx_enb);

    end

    //==============================================================
    // Final Simulation Summary
    //==============================================================
    // Prints final measured baud rate statistics.
    //==============================================================

    initial begin

        //----------------------------------------------------------
        // Run simulation long enough for stable measurement
        //----------------------------------------------------------
        #800_000;

        $display("--------------------------------------------------------------------");
        $display("                        SIMULATION SUMMARY                          ");
        $display("--------------------------------------------------------------------");

        $display("Total Clock Cycles     : %0d", cycle_count);

        $display("TX Pulses              : %0d", tx_pulse);

        $display("Measured TX Baud Rate  : %.2f baud", baud_rate);

        $display("Target Baud Rate       : 9600 baud");

        $display("Error                  : %.4f %%",

                 ((9600 - baud_rate) / 9600) * 100);

        $display("====================================================================");

        $finish;

    end

endmodule
