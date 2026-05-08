//==================================================================
// baud_rate_generator.v
// UART Baud Rate Generator
// -----------------------------------------------------------------
// Description:
//   This module generates baud rate enable pulses required for
//   UART transmission and reception from a high-frequency
//   system clock.
//
// Functionality:
//   - Generates 1x baud tick for UART transmitter
//   - Generates 16x oversampling tick for UART receiver
//   - Designed for 50 MHz system clock
//   - Supports UART baud rate of 9600 bps
//
// Baud Calculations:
// -----------------------------------------------------------------
// TX Baud Tick:
//   Baud Rate = 9600
//   Clock      = 50 MHz
//
//   Divider = 50,000,000 / 9,600
//           ≈ 5208
//
// RX Oversampling Tick:
//   Oversampling Rate = 16 × 9600 = 153600
//
//   Divider = 50,000,000 / 153600
//           ≈ 325
//
// Notes:
//   - Outputs are single-clock-cycle pulses
//   - Active-low asynchronous reset used
//   - Suitable for UART TX/RX FSM enable timing
//
//==================================================================

module baud_rate_generator (

    //==============================================================
    // Port Declarations
    //==============================================================

    input wire clk,         // System clock (50 MHz)
    input wire rst_n,       // Active-low asynchronous reset

    output wire rx_enb,     // 16x oversampling enable pulse for RX
    output wire tx_enb      // 1x baud enable pulse for TX
);

    //==============================================================
    // Internal Registers
    //==============================================================

    // Counter for transmitter baud generation
    reg [13:0] tx_counter;

    // Counter for receiver oversampling baud generation
    reg [9:0]  rx_counter;

    //==============================================================
    // TX Baud Tick Generator
    //==============================================================
    // Generates a single-cycle pulse every 5208 clock cycles.
    //
    // Purpose:
    //   Provides baud timing for UART transmitter FSM.
    //
    // Tick Frequency:
    //   50 MHz / 5208 ≈ 9600 Hz
    //==============================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            tx_counter <= 14'd0;

        end 
        else if (tx_counter == 5208) begin

            // Reset counter after baud interval
            tx_counter <= 14'd0;

        end 
        else begin

            // Increment counter
            tx_counter <= tx_counter + 1;

        end
    end

    //==============================================================
    // RX Oversampling Tick Generator
    //==============================================================
    // Generates a single-cycle pulse every 325 clock cycles.
    //
    // Purpose:
    //   Provides 16x oversampling clock enable for UART receiver.
    //
    // Oversampling Frequency:
    //   9600 × 16 = 153600 Hz
    //
    // Tick Frequency:
    //   50 MHz / 325 ≈ 153.8 kHz
    //==============================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rx_counter <= 10'd0;

        end 
        else if (rx_counter == 325) begin

            // Reset counter after oversampling interval
            rx_counter <= 10'd0;

        end 
        else begin

            // Increment counter
            rx_counter <= rx_counter + 1;

        end
    end

    //==============================================================
    // Baud Enable Pulse Generation
    //==============================================================
    // Generates single-clock-cycle enable pulses when counters
    // reach terminal count values.
    //==============================================================

    assign tx_enb = (tx_counter == 5208) ? 1'b1 : 1'b0;

    assign rx_enb = (rx_counter == 325) ? 1'b1 : 1'b0;

endmodule
