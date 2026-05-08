// Code your design here
//==================================================================
// uart_rx.v - PROPERLY ALIGNED VERSION
//==================================================================

`timescale 1ns / 1ps

module uart_rx (
    input wire       clk,
    input wire       rst_n,
    input wire       rx_enb,
    input wire       rx,
    
    output reg [7:0] data_out,
    output reg       data_valid,
    output reg       ready
);

    reg [1:0] state;
    reg [3:0] sample_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    
    // Synchronize rx
    reg rx_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_sync <= 1'b1;
        else
            rx_sync <= rx;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= 2'b00;
            data_out   <= 8'b0;
            data_valid <= 1'b0;
            ready      <= 1'b1;
            shift_reg  <= 8'b0;
            sample_cnt <= 4'b0;
            bit_cnt    <= 3'b0;
        end 
        else begin
            data_valid <= 1'b0;

            case (state)
                
                2'b00: begin  // IDLE
                    ready <= 1'b1;
                    sample_cnt <= 4'b0;
                    bit_cnt <= 3'b0;
                    
                    // Wait for rx_enb AND start bit
                    if (!rx_sync && rx_enb) begin
                        state <= 2'b01;
                        ready <= 1'b0;
                        sample_cnt <= 4'b1;  // Start counting from 1
                    end
                end

                2'b01: begin  // START
                    if (rx_enb) begin
                        if (sample_cnt == 4'd8) begin
                            if (!rx_sync) begin
                                // Valid start bit
                                state <= 2'b10;
                                sample_cnt <= 4'b0;
                                bit_cnt <= 3'b0;
                            end else begin
                                // False start
                                state <= 2'b00;
                                ready <= 1'b1;
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                end

                2'b10: begin  // DATA
                    if (rx_enb) begin
                        if (sample_cnt == 4'd15) begin
                            sample_cnt <= 4'b0;
                            if (bit_cnt == 3'd7) begin
                                state <= 2'b11;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                            // Sample at count 8
                            if (sample_cnt == 4'd7) begin
                                shift_reg <= {rx_sync, shift_reg[7:1]};
                            end
                        end
                    end
                end

                2'b11: begin  // STOP
                    if (rx_enb) begin
                        if (sample_cnt == 4'd15) begin
                            if (rx_sync) begin
                                data_out <= shift_reg;
                                data_valid <= 1'b1;
                            end
                            state <= 2'b00;
                            ready <= 1'b1;
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
