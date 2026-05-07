//==================================================================
// Baud Rate Generator for UART 
// System Clock: 50 MHz, Baud Rate: 9600
//==================================================================

module baud_rate_generator (
    input wire clk,
    input wire rst_n,          // Active low asynchronous reset
    output wire rx_enb,        // 16x oversampling tick for Receiver
    output wire tx_enb         // 1x baud rate tick for Transmitter
);

    reg [13:0] tx_counter;
    reg [9:0]  rx_counter;

    // TX baud tick generator (50MHz / 9600 ≈ 5208)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_counter <= 14'd0;
        end else if (tx_counter == 5208) begin
            tx_counter <= 14'd0;
        end else begin
            tx_counter <= tx_counter + 1;
        end
    end

    // RX 16x oversampling tick generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_counter <= 10'd0;
        end else if (rx_counter == 325) begin
            rx_counter <= 10'd0;
        end else begin
            rx_counter <= rx_counter + 1;
        end
    end

    // Single-cycle pulse outputs
    assign tx_enb = (tx_counter == 5208) ? 1'b1 : 1'b0;
    assign rx_enb = (rx_counter == 325) ? 1'b1 : 1'b0;

endmodule
