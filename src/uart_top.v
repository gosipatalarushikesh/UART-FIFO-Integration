//==================================================================
// uart_top.v - Simplified & Clean Integration
//==================================================================

module uart_top (
    input wire       clk,
    input wire       rst_n,
    
    // Serial Interface
    input wire       rx,
    output wire      tx,
    
    // TX Path (Host → UART)
    input wire [7:0] tx_data_in,
    input wire       tx_wr_en,
    output wire      tx_full,
    output wire      tx_empty,
    
    // RX Path (UART → Host)
    output wire [7:0] rx_data_out,
    input wire        rx_rd_en,
    output wire       rx_full,
    output wire       rx_empty
);

    //==============================================================
    // Internal Wires
    //==============================================================
    wire rx_enb;
    wire tx_enb;
    
    wire [7:0] tx_fifo_out;
    wire       tx_fifo_empty;
    wire       uart_tx_busy;

    wire [7:0] rx_fifo_in;
    wire       rx_data_valid;

    //==============================================================
    // 1. Baud Rate Generator
    //==============================================================
    baud_rate_generator baud_gen (
        .clk    (clk),
        .rst_n  (rst_n),
        .rx_enb (rx_enb),
        .tx_enb (tx_enb)
    );

    //==============================================================
    // 2. TX FIFO
    //==============================================================
    fifo tx_fifo_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_data (tx_data_in),
        .wr_en   (tx_wr_en),
        .full    (tx_full),
        .rd_en   (\~tx_fifo_empty && \~uart_tx_busy),   // Simple & Reliable
        .rd_data (tx_fifo_out),
        .empty   (tx_fifo_empty)
    );

    //==============================================================
    // 3. UART Transmitter
    //==============================================================
    uart_tx uart_tx_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .tx_enb  (tx_enb),
        .data_in (tx_fifo_out),
        .enb     (\~tx_fifo_empty),        // Load when data available
        .tx      (tx),
        .busy    (uart_tx_busy)
    );

    //==============================================================
    // 4. UART Receiver
    //==============================================================
    uart_rx uart_rx_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_enb     (rx_enb),
        .rx         (rx),
        .data_out   (rx_fifo_in),
        .data_valid (rx_data_valid),
        .ready      () 
    );

    //==============================================================
    // 5. RX FIFO
    //==============================================================
    fifo rx_fifo_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_data (rx_fifo_in),
        .wr_en   (rx_data_valid),
        .full    (rx_full),
        .rd_en   (rx_rd_en),
        .rd_data (rx_data_out),
        .empty   (rx_empty)
    );

    //==============================================================
    // Output Assignment
    //==============================================================
    assign tx_empty = tx_fifo_empty;

endmodule
