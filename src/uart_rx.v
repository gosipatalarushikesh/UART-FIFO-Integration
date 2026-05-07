//==================================================================
// uart_rx.v - UART Receiver (8x oversampling, center sampling)
//==================================================================
//
// Description:
//   - Asynchronous UART receiver with 8x oversampling.
//   - Detects start bit on falling edge.
//   - Samples data at the center of each bit period.
//   - LSB first, 8 data bits, 1 stop bit (no parity).
//   - Uses rx_enb as baud-rate enable (tick every 1/8th of bit period).
//
// Note: rx_enb should be asserted once every baud period / 8
//       (i.e., 8x baud rate clock enable).
//
//==================================================================

module uart_rx (
    input wire       clk,        // System clock
    input wire       rst_n,      // Active-low asynchronous reset
    input wire       rx_enb,     // Baud rate enable (8x oversampling tick)
    input wire       rx,         // Serial data input
    
    output reg [7:0] data_out,   // Received byte (valid when data_valid=1)
    output reg       data_valid  // Pulse indicating valid data on data_out
);

    // State machine states
    reg [1:0] state;
    reg [3:0] sample_cnt;   // Counts 0-7 for 8x oversampling
    reg [2:0] bit_cnt;      // Counts 0-7 for 8 data bits
    reg [7:0] shift_reg;    // Shift register for incoming data (LSB first)
    reg       rx_d1;        // Delayed rx for edge detection

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    //====================================================================
    // Falling edge detection on RX line
    //====================================================================
    always @(posedge clk) begin
        rx_d1 <= rx;
    end

    //====================================================================
    // Main UART Receiver FSM
    //====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            data_out    <= 8'b0;
            data_valid  <= 1'b0;
            shift_reg   <= 8'b0;
            sample_cnt  <= 4'b0;
            bit_cnt     <= 3'b0;
        end 
        else begin
            data_valid <= 1'b0;   // Default: pulse signal

            case (state)
                
                //============================================================
                IDLE: begin
                //============================================================
                    sample_cnt <= 4'b0;
                    if (!rx && rx_d1) begin        // Falling edge detected
                        state <= START;            // Potential start bit
                    end
                end

                //============================================================
                START: begin
                //============================================================
                    if (rx_enb) begin
                        sample_cnt <= sample_cnt + 1;
                        
                        // Sample at center of start bit (after 8 ticks)
                        if (sample_cnt == 4'd7) begin
                            if (rx == 1'b0) begin         // Valid start bit (still low)
                                state      <= DATA;
                                sample_cnt <= 4'b0;
                                bit_cnt    <= 3'b0;
                            end else begin
                                state <= IDLE;            // False start, abort
                            end
                        end
                    end
                end

                //============================================================
                DATA: begin
                //============================================================
                    if (rx_enb) begin
                        sample_cnt <= sample_cnt + 1;
                        
                        // Sample at center of each data bit
                        if (sample_cnt == 4'd7) begin
                            shift_reg  <= {rx, shift_reg[7:1]};  // Shift in LSB first
                            sample_cnt <= 4'b0;
                            bit_cnt    <= bit_cnt + 1;

                            if (bit_cnt == 3'd7) begin
                                state <= STOP;   // All 8 bits received
                            end
                        end
                    end
                end

                //============================================================
                STOP: begin
                //============================================================
                    if (rx_enb) begin
                        sample_cnt <= sample_cnt + 1;
                        
                        // Sample at center of stop bit
                        if (sample_cnt == 4'd7) begin
                            if (rx == 1'b1) begin          // Valid stop bit (high)
                                data_out   <= shift_reg;
                                data_valid <= 1'b1;
                            end
                            // else: framing error (stop bit not high) - currently ignored
                            
                            state <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
