//==================================================================
// tb_uart_rx.v
// Simple UART Receiver Testbench
// -----------------------------------------------------------------
// Description:
//   This testbench verifies functionality of the UART receiver
//   module by transmitting multiple UART frames serially and
//   checking whether the received parallel data matches the
//   transmitted data.
//
// Features Tested:
//   - UART start bit detection
//   - 8-bit serial data reception
//   - Stop bit handling
//   - Multiple data patterns
//   - Receiver ready signal operation
//
// UART Configuration:
//   - 8 Data Bits
//   - No Parity
//   - 1 Stop Bit
//   - 16x Oversampling
//
// Test Data:
//   - 0xA5 : Alternating pattern
//   - 0xFF : All HIGHs
//   - 0x00 : All LOWs
//   - 0x55 : 01010101 pattern
//   - 0xAA : 10101010 pattern
//
//==================================================================

`timescale 1ns / 1ps

module tb_uart_rx;

    //==============================================================
    // Testbench Signals
    //==============================================================

    reg        clk;          // System clock
    reg        rst_n;        // Active-low reset
    reg        rx_enb;       // 16x baud enable pulse
    reg        rx;           // Serial RX stimulus

    wire [7:0] data_out;     // Received parallel data
    wire       ready;        // Receiver ready indication

    //==============================================================
    // Clock Parameters
    //==============================================================

    parameter CLK_PERIOD = 20;

    //==============================================================
    // DUT Instantiation
    //==============================================================
    // Device Under Test (DUT)
    //==============================================================

    uart_rx dut (.*);

    //==============================================================
    // Clock Generation
    //==============================================================
    // Generates 50 MHz system clock
    // Clock period = 20 ns
    //==============================================================

    always #10 clk = ~clk;

    //==============================================================
    // Baud Enable Generator
    //==============================================================
    // Generates rx_enb pulse once every 16 clock cycles.
    // This simulates 16x UART oversampling clock enable.
    //==============================================================

    reg [4:0] count;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            count  <= 0;
            rx_enb <= 0;

        end 
        else begin

            count  <= count + 1;
            rx_enb <= (count == 15);

        end
    end

    //==============================================================
    // UART Byte Transmission Task
    //==============================================================
    // Task:
    //   Serially transmits one UART frame to DUT.
    //
    // UART Frame Format:
    //   1 Start Bit  -> Logic 0
    //   8 Data Bits  -> LSB First
    //   1 Stop Bit   -> Logic 1
    //
    // Timing:
    //   Each UART bit lasts for 16 rx_enb pulses
    //==============================================================

    task send_byte(input [7:0] data);

        integer i;

        begin

            //------------------------------------------------------
            // START BIT
            //------------------------------------------------------
            @(posedge rx_enb);
            rx = 0;

            // Hold start bit for one full UART bit duration
            repeat(16) @(posedge rx_enb);

            //------------------------------------------------------
            // DATA BITS (LSB FIRST)
            //------------------------------------------------------
            for (i = 0; i < 8; i = i + 1) begin

                rx = data[i];

                // Hold each bit for one UART bit duration
                repeat(16) @(posedge rx_enb);

            end

            //------------------------------------------------------
            // STOP BIT
            //------------------------------------------------------
            rx = 1;

            // Hold stop bit for one UART bit duration
            repeat(16) @(posedge rx_enb);

        end

    endtask

    //==============================================================
    // Main Test Sequence
    //==============================================================

    initial begin

        $display("================================================");
        $display("              UART RX TEST START                ");
        $display("================================================");

        //----------------------------------------------------------
        // Initial Conditions
        //----------------------------------------------------------
        clk   = 0;
        rst_n = 0;
        rx    = 1;   // UART idle line is HIGH

        //----------------------------------------------------------
        // Apply Reset
        //----------------------------------------------------------
        #100;
        rst_n = 1;

        //----------------------------------------------------------
        // Test Case 1 : 0xA5
        //----------------------------------------------------------
        send_byte(8'hA5);

        wait(ready);

        $display("Sent: 0xA5 | Received: 0x%02h | %s",
                 data_out,
                 (data_out == 8'hA5) ? "PASS" : "FAIL");

        //----------------------------------------------------------
        // Test Case 2 : 0xFF
        //----------------------------------------------------------
        send_byte(8'hFF);

        wait(ready);

        $display("Sent: 0xFF | Received: 0x%02h | %s",
                 data_out,
                 (data_out == 8'hFF) ? "PASS" : "FAIL");

        //----------------------------------------------------------
        // Test Case 3 : 0x00
        //----------------------------------------------------------
        send_byte(8'h00);

        wait(ready);

        $display("Sent: 0x00 | Received: 0x%02h | %s",
                 data_out,
                 (data_out == 8'h00) ? "PASS" : "FAIL");

        //----------------------------------------------------------
        // Test Case 4 : 0x55
        //----------------------------------------------------------
        send_byte(8'h55);

        wait(ready);

        $display("Sent: 0x55 | Received: 0x%02h | %s",
                 data_out,
                 (data_out == 8'h55) ? "PASS" : "FAIL");

        //----------------------------------------------------------
        // Test Case 5 : 0xAA
        //----------------------------------------------------------
        send_byte(8'hAA);

        wait(ready);

        $display("Sent: 0xAA | Received: 0x%02h | %s",
                 data_out,
                 (data_out == 8'hAA) ? "PASS" : "FAIL");

        //----------------------------------------------------------
        // End Simulation
        //----------------------------------------------------------
        $display("================================================");
        $display("           UART RX TEST COMPLETE                ");
        $display("================================================");

        $finish;

    end

endmodule
