//==================================================================
// uart_rx.v
// UART Receiver Module
// -----------------------------------------------------------------
// Description:
//   This module implements an 8-bit UART receiver using 16x
//   oversampling. It detects the start bit, samples incoming
//   serial data at the center of each bit period, reconstructs
//   the received byte, and validates the stop bit.
//
// Features:
//   - 8-bit UART reception
//   - 16x oversampling for improved timing accuracy
//   - Start bit validation
//   - Stop bit verification
//   - Synchronized RX input
//   - Ready flag to indicate receiver idle/completion
//
// Assumptions:
//   - rx_enb generates a pulse at 16x baud rate
//   - UART frame format: 1 Start, 8 Data, 1 Stop
//   - No parity support
//
// Author : RUSHIKESH
//==================================================================

`timescale 1ns / 1ps

module uart_rx (

    //==============================================================
    // Port Declarations
    //==============================================================
    input wire       clk,        // System clock
    input wire       rst_n,      // Active-low asynchronous reset
    input wire       rx_enb,     // 16x baud oversampling enable pulse
    input wire       rx,         // Serial RX input line

    output reg [7:0] data_out,   // Parallel received data byte
    output reg       ready       // Receiver ready/idle indicator
);

    //==============================================================
    // Internal Registers
    //==============================================================

    reg [1:0] state;             // FSM current state
    reg [3:0] sample_cnt;        // Oversampling counter (0-15)
    reg [2:0] bit_cnt;           // Counts received data bits (0-7)
    reg [7:0] shift_reg;         // Shift register for serial-to-parallel conversion

    // RX synchronizer register
    // Helps reduce metastability issues from asynchronous RX input
    reg rx_sync;

    //==============================================================
    // RX Input Synchronization
    //==============================================================
    // Synchronizes asynchronous RX signal with system clock domain.
    // A single-stage synchronizer is used here.
    // In high-reliability systems, a two-stage synchronizer is preferred.
    //==============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_sync <= 1'b1;     // UART idle line is logic HIGH
        else
            rx_sync <= rx;
    end

    //==============================================================
    // UART Receiver FSM
    //==============================================================
    // State Encoding:
    //   2'b00 : IDLE
    //   2'b01 : START BIT DETECTION
    //   2'b10 : DATA RECEPTION
    //   2'b11 : STOP BIT CHECK
    //==============================================================
    always @(posedge clk or negedge rst_n) begin

        //----------------------------------------------------------
        // Asynchronous Reset
        //----------------------------------------------------------
        if (!rst_n) begin

            state      <= 2'b00;
            data_out   <= 8'b0;
            ready      <= 1'b1;

            shift_reg  <= 8'b0;
            sample_cnt <= 4'b0;
            bit_cnt    <= 3'b0;

        end 
        else begin

            case (state)

                //==================================================
                // IDLE STATE
                //==================================================
                // Waits for detection of UART start bit.
                // RX line remains HIGH during idle condition.
                //==================================================
                2'b00: begin

                    ready <= 1'b1;

                    sample_cnt <= 4'b0;
                    bit_cnt    <= 3'b0;

                    // Start-bit detection performed only on
                    // oversampling enable pulses
                    if (rx_enb) begin

                        // Detect falling edge/start condition
                        if (!rx_sync) begin

                            state      <= 2'b01;
                            ready      <= 1'b0;

                            // Begin oversampling count
                            sample_cnt <= 4'b1;
                        end
                    end
                end

                //==================================================
                // START BIT VALIDATION STATE
                //==================================================
                // Confirms that detected low level is a valid
                // start bit by sampling near the middle of the bit.
                //==================================================
                2'b01: begin

                    if (rx_enb) begin

                        // Sample near center of start bit
                        if (sample_cnt == 4'd8) begin

                            // Valid start bit confirmed
                            if (!rx_sync) begin

                                state      <= 2'b10;
                                sample_cnt <= 4'b0;
                                bit_cnt    <= 3'b0;

                            end 
                            else begin

                                // False start bit detected
                                state <= 2'b00;
                                ready <= 1'b1;

                            end

                        end 
                        else begin

                            sample_cnt <= sample_cnt + 1'b1;

                        end
                    end
                end

                //==================================================
                // DATA RECEPTION STATE
                //==================================================
                // Receives 8 serial data bits.
                // Each bit is sampled at the center of the bit
                // period for improved noise immunity.
                //==================================================
                2'b10: begin

                    if (rx_enb) begin

                        // End of one bit duration
                        if (sample_cnt == 4'd15) begin

                            sample_cnt <= 4'b0;

                            // All 8 bits received
                            if (bit_cnt == 3'd7) begin

                                state <= 2'b11;

                            end 
                            else begin

                                // Move to next data bit
                                bit_cnt <= bit_cnt + 1'b1;

                            end

                        end 
                        else begin

                            sample_cnt <= sample_cnt + 1'b1;

                            // Sample exactly at center
                            // of current bit period
                            if (sample_cnt == 4'd7) begin

                                // LSB-first UART reception
                                shift_reg <= {rx_sync, shift_reg[7:1]};

                            end
                        end
                    end
                end

                //==================================================
                // STOP BIT CHECK STATE
                //==================================================
                // Verifies stop bit validity.
                // Stop bit must remain HIGH.
                //==================================================
                2'b11: begin

                    if (rx_enb) begin

                        if (sample_cnt == 4'd15) begin

                            // Valid stop bit check
                            if (rx_sync) begin

                                // Transfer received byte
                                data_out <= shift_reg;

                            end

                            // Return to idle state
                            state <= 2'b00;
                            ready <= 1'b1;

                        end 
                        else begin

                            sample_cnt <= sample_cnt + 1'b1;

                        end
                    end
                end

            endcase
        end
    end

endmodule
