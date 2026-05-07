//==================================================================
// uart_rx.v - Sampling at count 8 (center of bit)
//==================================================================

module uart_rx (
    input wire       clk,
    input wire       rst_n,
    input wire       rx_enb,
    input wire       rx,
    
    output reg [7:0] data_out,
    output reg       data_valid
);

    reg [1:0] state;
    reg [3:0] sample_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg       rx_d1;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    always @(posedge clk) begin
        rx_d1 <= rx;
    end

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
            data_valid <= 1'b0;

            case (state)
                
                IDLE: begin
                    if (!rx && rx_d1) begin           // Falling edge
                        state      <= START;
                        sample_cnt <= 4'b0;
                    end
                end

                START: begin
                    if (rx_enb) begin
                        sample_cnt <= sample_cnt + 1;
                      if (sample_cnt == 4'd8) begin   // Wait half bit
                            state      <= DATA;
                            sample_cnt <= 4'b0;
                            bit_cnt    <= 3'b0;
                        end
                    end
                end

                DATA: begin
                    if (rx_enb) begin
                        sample_cnt <= sample_cnt + 1;
                      if (sample_cnt == 4'd8) begin     // Sample at center
                            shift_reg  <= {rx, shift_reg[7:1]};
                            sample_cnt <= 4'b0;
                            bit_cnt    <= bit_cnt + 1;

                            if (bit_cnt == 3'd7) begin
                                state <= STOP;
                            end
                        end
                    end
                end

                STOP: begin
                    if (rx_enb) begin
                        sample_cnt <= sample_cnt + 1;
                      if (sample_cnt == 4'd8) begin
                            if (rx == 1'b1) begin          // Good stop bit
                                data_out   <= shift_reg;
                                data_valid <= 1'b1;
                            end
                            state <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
