//==================================================================
// UART Transmitter - 8N1 format (1 Start, 8 Data, 1 Stop)
//==================================================================

module uart_tx (
    input wire       clk,
    input wire       rst_n,
    input wire       tx_enb,     // Baud rate tick from baud generator
    input wire [7:0] data_in,    // Data byte from FIFO / host
    input wire       enb,        // Load new data (valid signal)
    
    output reg       tx,         // Serial output
    output reg       busy        // High when transmitting
);

    reg [1:0] state;
    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;

    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tx        <= 1'b1;     // Idle state is high
            busy      <= 1'b0;
            shift_reg <= 8'b0;
            bit_cnt   <= 3'b0;
        end 
        else begin
            case (state)
                
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (enb) begin
                        shift_reg <= data_in;
                        state     <= START;
                        busy      <= 1'b1;
                    end
                end

                START: begin
                    if (tx_enb) begin
                        tx        <= 1'b0;     // Start bit
                        state     <= DATA;
                        bit_cnt   <= 3'b0;
                    end
                end

                DATA: begin
                    if (tx_enb) begin
                        tx        <= shift_reg[0];   // LSB first
                        shift_reg <= shift_reg >> 1;
                        bit_cnt   <= bit_cnt + 1;
                        
                        if (bit_cnt == 3'd7) begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (tx_enb) begin
                        tx    <= 1'b1;      // Stop bit
                        state <= IDLE;
                        busy  <= 1'b0;
                    end
                end

                default: begin
                    state <= IDLE;
                end
                
            endcase
        end
    end

endmodule
