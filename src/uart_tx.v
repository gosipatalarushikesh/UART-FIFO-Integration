//==================================================================
// uart_tx.v
// UART Transmitter Module
// -----------------------------------------------------------------
// Description:
//   This module implements a UART transmitter supporting the
//   standard 8N1 UART frame format:
//
//       - 1 Start Bit
//       - 8 Data Bits
//       - No Parity
//       - 1 Stop Bit
//
// Functionality:
//   - Accepts 8-bit parallel input data
//   - Serializes data for UART transmission
//   - Transmits data LSB first
//   - Generates proper UART start and stop bits
//   - Provides busy status indication
//
// Timing:
//   - Transmission progresses only on tx_enb pulses
//   - tx_enb must be a single-clock baud-rate enable pulse
//
// UART Frame Format:
// -----------------------------------------------------------------
//   IDLE  : Logic HIGH
//   START : Logic LOW
//   DATA  : 8 bits (LSB first)
//   STOP  : Logic HIGH
//
//==================================================================

module uart_tx (

    //==============================================================
    // Port Declarations
    //==============================================================

    input  wire       clk,        // System clock
    input  wire       rst_n,      // Active-low asynchronous reset

    input  wire       tx_enb,     // Baud-rate enable pulse
    input  wire [7:0] data_in,    // Parallel input data
    input  wire       enb,        // Transmission start enable

    output reg        tx,         // UART serial transmit output
    output reg        busy        // Transmitter busy flag
);

    //==============================================================
    // Internal Registers
    //==============================================================

    reg [1:0] state;              // FSM current state
    reg [7:0] shift_reg;          // Shift register for serialization
    reg [3:0] bit_cnt;            // Counts transmitted data bits

    //==============================================================
    // FSM State Encoding
    //==============================================================

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    //==============================================================
    // UART Transmitter FSM
    //==============================================================
    // State Flow:
    //
    //   IDLE -> START -> DATA -> STOP -> IDLE
    //
    //==============================================================

    always @(posedge clk or negedge rst_n) begin

        //----------------------------------------------------------
        // Asynchronous Reset
        //----------------------------------------------------------
        if (!rst_n) begin

            state     <= IDLE;

            tx        <= 1'b1;    // UART idle line is HIGH
            busy      <= 1'b0;

            shift_reg <= 8'b0;
            bit_cnt   <= 4'b0;

        end 
        else begin

            case (state)

                //==================================================
                // IDLE STATE
                //==================================================
                // Waits for transmission request.
                // TX line remains HIGH during idle condition.
                //==================================================
                IDLE: begin

                    tx   <= 1'b1;
                    busy <= 1'b0;

                    // Load new transmission data
                    if (enb) begin

                        shift_reg <= data_in;

                        state     <= START;
                        busy      <= 1'b1;

                        // Start bit driven in START state

                    end
                end

                //==================================================
                // START BIT STATE
                //==================================================
                // Transmits UART start bit (logic LOW).
                //==================================================
                START: begin

                    // Drive start bit continuously
                    tx <= 1'b0;

                    // Advance on baud tick
                    if (tx_enb) begin

                        state   <= DATA;
                        bit_cnt <= 4'd0;

                    end
                end

                //==================================================
                // DATA TRANSMISSION STATE
                //==================================================
                // Serially transmits 8-bit data.
                // Data is transmitted LSB first.
                //==================================================
                DATA: begin

                    if (tx_enb) begin

                        //--------------------------------------------------
                        // Transmit current LSB
                        //--------------------------------------------------
                        tx <= shift_reg[0];

                        //--------------------------------------------------
                        // Shift data right for next transmission bit
                        //--------------------------------------------------
                        shift_reg <= shift_reg >> 1;

                        //--------------------------------------------------
                        // Increment transmitted bit counter
                        //--------------------------------------------------
                        bit_cnt <= bit_cnt + 1;

                        //--------------------------------------------------
                        // After last bit, move to STOP state
                        //--------------------------------------------------
                        if (bit_cnt == 4'd7) begin

                            state <= STOP;

                        end
                    end
                end

                //==================================================
                // STOP BIT STATE
                //==================================================
                // Transmits UART stop bit (logic HIGH).
                //==================================================
                STOP: begin

                    if (tx_enb) begin

                        //--------------------------------------------------
                        // Drive stop bit
                        //--------------------------------------------------
                        tx <= 1'b1;

                        //--------------------------------------------------
                        // Return to IDLE after stop bit duration
                        //--------------------------------------------------
                        state <= IDLE;

                        //--------------------------------------------------
                        // Clear busy flag
                        //--------------------------------------------------
                        busy <= 1'b0;

                    end
                end

                //==================================================
                // DEFAULT STATE RECOVERY
                //==================================================
                // Safety fallback for invalid states.
                //==================================================
                default: begin

                    state <= IDLE;

                end

            endcase
        end
    end

endmodule
