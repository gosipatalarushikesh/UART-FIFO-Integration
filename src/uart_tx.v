//==================================================================
// UART Transmitter - 8N1 format (1 Start, 8 Data, 1 Stop)
//==================================================================

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_enb,     // Baud rate tick (one clk wide)
    input  wire [7:0] data_in,
    input  wire       enb,        // Load new data
    
    output reg        tx,
    output reg        busy
);

    reg [1:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tx        <= 1'b1;
            busy      <= 1'b0;
            shift_reg <= 8'b0;
            bit_cnt   <= 4'b0;
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
                        // tx will be set in START state
                    end
                end

                START: begin
                    tx <= 1'b0;                    // Start bit (driven continuously)
                    if (tx_enb) begin
                        state   <= DATA;
                        bit_cnt <= 4'd0;
                    end
                end

                DATA: begin
                    if (tx_enb) begin
                        tx        <= shift_reg[0];      // LSB first
                        shift_reg <= shift_reg >> 1;
                        bit_cnt   <= bit_cnt + 1;

                        if (bit_cnt == 4'd7) begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (tx_enb) begin
                        tx    <= 1'b1;         // Stop bit
                        state <= IDLE;
                        busy  <= 1'b0;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
