`timescale 1ns/1ps

//=============================================================================
// uart_tx_tb.v
// UART Transmitter Testbench
//-----------------------------------------------------------------------------
// Description:
//   This testbench verifies the functionality of the UART transmitter
//   module operating in standard 8N1 UART format:
//
//       - 1 Start Bit
//       - 8 Data Bits
//       - No Parity
//       - 1 Stop Bit
//
// Features:
//   - Generates 50 MHz system clock
//   - Generates baud-rate enable pulse for 9600 baud
//   - Applies reset and transmission stimulus
//   - Transmits multiple UART frames
//   - Monitors internal DUT state and shift register
//   - Displays live waveform/debug information
//
// Test Cases:
// -----------------------------------------------------------------------------
//   1. Transmission of 0xA5 (10100101)
//   2. Transmission of 0x55 (01010101)
//
// UART Configuration:
// -----------------------------------------------------------------------------
//   System Clock : 50 MHz
//   Baud Rate    : 9600 bps
//   Data Format  : 8N1
//
//=============================================================================

module uart_tx_tb;

    //=========================================================================
    // Signal Declarations
    //=========================================================================
    // Testbench-driven input signals and DUT outputs
    //=========================================================================

    reg        clk;        // System clock (50 MHz)
    reg        rst_n;      // Active-low asynchronous reset
    reg        tx_enb;     // Baud-rate enable pulse
    reg [7:0]  data_in;    // Parallel data input
    reg        enb;        // Transmission start enable

    wire       tx;         // UART serial transmit output
    wire       busy;       // High when transmission is active

    //=========================================================================
    // DUT Instantiation
    //=========================================================================
    // Device Under Test (UART Transmitter)
    //=========================================================================

    uart_tx dut (

        .clk     (clk),
        .rst_n   (rst_n),

        .tx_enb  (tx_enb),

        .data_in (data_in),
        .enb     (enb),

        .tx      (tx),
        .busy    (busy)

    );

    //=========================================================================
    // Clock Generation
    //=========================================================================
    // Generates 50 MHz system clock.
    //
    // Clock Period:
    //     20 ns
    //
    // Clock Frequency:
    //     1 / 20ns = 50 MHz
    //=========================================================================

    initial begin

        clk = 0;

        forever #10 clk = ~clk;

    end

    //=========================================================================
    // Baud-Rate Enable Pulse Generation
    //=========================================================================
    // Generates one-cycle tx_enb pulse for 9600 baud operation.
    //
    // Calculation:
    // ------------------------------------------------------------------------
    //   System Clock Frequency = 50 MHz
    //   Baud Rate              = 9600
    //
    //   Clock Cycles per Bit:
    //
    //       50,000,000 / 9600 ≈ 5208.33
    //
    // A short pulse is generated approximately every 5208 ns.
    //=========================================================================

    initial begin

        tx_enb = 0;

        forever begin

            //--------------------------------------------------------------
            // Assert baud-rate tick
            //--------------------------------------------------------------
            #5208 tx_enb = 1;

            //--------------------------------------------------------------
            // Deassert after one short pulse
            //--------------------------------------------------------------
            #20 tx_enb = 0;

        end
    end

    //=========================================================================
    // State Monitoring Logic
    //=========================================================================
    // Converts DUT internal FSM state encoding into readable text.
    // Useful for waveform debugging and console monitoring.
    //=========================================================================

    reg [63:0] state_name;

    always @(*) begin

        case (dut.state)

            2'b00: state_name = "IDLE";
            2'b01: state_name = "START";
            2'b10: state_name = "DATA";
            2'b11: state_name = "STOP";

            default: state_name = "UNKNOWN";

        endcase
    end

    //=========================================================================
    // Live Simulation Monitor
    //=========================================================================
    // Continuously prints key DUT signals whenever any monitored
    // signal changes.
    //
    // Signals Displayed:
    //   - Simulation time
    //   - Busy flag
    //   - TX output
    //   - FSM state
    //   - Internal shift register
    //=========================================================================

    initial begin

        $display("Time(ns)     busy   tx    State      shift_reg");

        $display("-------------------------------------------------------------------");

        $monitor("%10t   %b      %b     %-8s    %8b",

                 $time,
                 busy,
                 tx,
                 state_name,
                 dut.shift_reg);

    end

    //=========================================================================
    // Main Test Stimulus
    //=========================================================================
    // Applies reset and performs UART transmission tests.
    //=========================================================================

    initial begin

        //--------------------------------------------------------------
        // Initialize Inputs
        //--------------------------------------------------------------
        rst_n   = 0;
        enb     = 0;
        data_in = 8'h00;

        //--------------------------------------------------------------
        // Apply Reset
        //--------------------------------------------------------------
        repeat(20) @(posedge clk);

        rst_n = 1;

        //--------------------------------------------------------------
        // Wait for system stabilization
        //--------------------------------------------------------------
        repeat(20) @(posedge clk);

        //=================================================================
        // Test Case 1 : Transmit 0xA5
        //=================================================================
        // Binary Pattern:
        //     10100101
        //=================================================================

        $display("\n--- Sending 0xA5 ---");

        data_in = 8'hA5;

        //--------------------------------------------------------------
        // Start transmission
        //--------------------------------------------------------------
        enb = 1;

        repeat(2) @(posedge clk);

        enb = 0;

        //--------------------------------------------------------------
        // Wait for transmission completion
        //--------------------------------------------------------------
        wait(busy == 0);

        //--------------------------------------------------------------
        // Small idle gap between packets
        //--------------------------------------------------------------
        repeat(10) @(posedge clk);

        //=================================================================
        // Test Case 2 : Transmit 0x55
        //=================================================================
        // Binary Pattern:
        //     01010101
        //=================================================================

        $display("\n--- Sending 0x55 ---");

        data_in = 8'h55;

        //--------------------------------------------------------------
        // Start transmission
        //--------------------------------------------------------------
        enb = 1;

        repeat(2) @(posedge clk);

        enb = 0;

        //--------------------------------------------------------------
        // Allow full transmission to complete
        //--------------------------------------------------------------
        #100000;

        //=================================================================
        // End Simulation
        //=================================================================

        $display("Test Completed");

        $finish;

    end

endmodule
