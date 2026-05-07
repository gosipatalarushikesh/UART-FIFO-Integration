`timescale 1ns/1ps

//=============================================================================
// This testbench verifies the functionality of the uart_tx module.
// It generates a 50 MHz clock, baud rate tick for 9600 baud, and 
// performs stimulus for transmitting two different data bytes (0xA5 and 0x55).
//=============================================================================

module uart_tx_tb;

    //-------------------------------------------------------------------------
    // Signal Declarations
    //-------------------------------------------------------------------------
    reg        clk;      // System clock (50 MHz)
    reg        rst_n;    // Active-low asynchronous reset
    reg        tx_enb;   // Baud rate tick (generated internally)
    reg [7:0]  data_in;  // 8-bit data to be transmitted
    reg        enb;      // Enable signal to load data into transmitter
    
    wire       tx;       // Serial transmit output
    wire       busy;     // High when transmitter is busy

    //-------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    //-------------------------------------------------------------------------
    uart_tx dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .tx_enb  (tx_enb),
        .data_in (data_in),
        .enb     (enb),
        .tx      (tx),
        .busy    (busy)
    );

    //-------------------------------------------------------------------------
    // Clock Generation: 50 MHz (20 ns period)
    //-------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // 10ns high + 10ns low = 20ns period
    end

    //-------------------------------------------------------------------------
    // Baud Rate Tick Generation for 9600 baud
    // 
    // At 50 MHz clock:
    //     Cycles per bit = 50_000_000 / 9600 ≈ 5208.33
    // We generate a one-cycle pulse every ~5208 clock cycles.
    //-------------------------------------------------------------------------
    initial begin
        tx_enb = 0;
        forever begin
            #5208 tx_enb = 1;   // Assert baud tick
            #20   tx_enb = 0;   // Deassert (short pulse)
        end
    end

    //-------------------------------------------------------------------------
    // State Monitoring Logic
    // Converts internal state encoding to human-readable string
    //-------------------------------------------------------------------------
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

    //-------------------------------------------------------------------------
    // Waveform Monitor
    // Prints key internal signals at every change for easy debugging
    //-------------------------------------------------------------------------
    initial begin
        $display("Time(ns)     busy   tx    State     shift_reg    Description");
        $display("-------------------------------------------------------------------");
        $monitor("%10t   %b      %b     %-8s    %8b    ", 
                 $time, busy, tx, state_name, dut.shift_reg);
    end

    //-------------------------------------------------------------------------
    // Test Stimulus Sequence
    //-------------------------------------------------------------------------
    initial begin
        // Initialize all inputs
        rst_n   = 0;
        enb     = 0;
        data_in = 8'h00;

        // Hold reset for some time
        repeat(20) @(posedge clk);
        rst_n = 1;                    // Release reset
        repeat(20) @(posedge clk);

        //--------------------- First Transmission Test -----------------------
        $display("\n--- Sending 0xA5 ---");
        data_in = 8'hA5;              // Data to transmit (10100101)
        enb = 1;                      // Assert enable to start transmission
        repeat(2) @(posedge clk);     // Hold enable for a couple of cycles
        enb = 0;

        wait(busy == 0);              // Wait until transmission completes
        repeat(10) @(posedge clk);    // Small idle period

        //--------------------- Second Transmission Test ----------------------
        $display("\n--- Sending 0x55 ---");
        data_in = 8'h55;              // Data to transmit (01010101)
        enb = 1;
        repeat(2) @(posedge clk);
        enb = 0;

        // Wait long enough to observe full transmission then finish
        #100000;
        $display("Test Completed");
        $finish;
    end

endmodule
