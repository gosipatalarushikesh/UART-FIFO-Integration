//==================================================================
// uart_top.v - Integrated UART with TX & RX FIFOs
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
    wire       rx_fifo_wr_en;
    wire       uart_rx_ready;      // Receiver ready (unused downstream)

    //==============================================================
    // TX Path Control Logic
    //==============================================================
    // Generates single-cycle start pulse to synchronize:
    //   - FIFO read (one byte consumed)
    //   - UART transmitter load (one byte captured)
    //
    // This prevents the FIFO from dumping data continuously
    // and ensures the transmitter captures exactly one byte
    // per transmission.
    //==============================================================
    
    wire tx_start_req;      // Condition: FIFO has data, TX not busy
    reg  tx_start_req_d;    // Delayed for edge detection
    wire tx_start_pulse;    // Single-cycle pulse

    assign tx_start_req = ~tx_fifo_empty && ~uart_tx_busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_start_req_d <= 1'b0;
        else
            tx_start_req_d <= tx_start_req;
    end

    // Rising-edge detect: fires once when condition becomes true
    assign tx_start_pulse = tx_start_req && ~tx_start_req_d;

    //==============================================================
    // RX Path Control Logic
    //==============================================================
    // uart_rx now provides data_valid pulse.
    // Gate with ~rx_full to prevent FIFO overflow writes.
    //==============================================================

    assign rx_fifo_wr_en = rx_data_valid && ~rx_full;

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
    // Read enable fires for ONE CYCLE per byte transmitted.
    // This aligns with the transmitter's capture of data_in.
    //==============================================================
    fifo tx_fifo_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_data (tx_data_in),
        .wr_en   (tx_wr_en),
        .full    (tx_full),
        .rd_en   (tx_start_pulse),       // Single-cycle read
        .rd_data (tx_fifo_out),
        .empty   (tx_fifo_empty)
    );

    //==============================================================
    // 3. UART Transmitter
    //==============================================================
    // Enb fires for ONE CYCLE to load data and start transmission.
    // Data_in is stable from FIFO read at the same instant.
    //==============================================================
    uart_tx uart_tx_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .tx_enb  (tx_enb),
        .data_in (tx_fifo_out),
        .enb     (tx_start_pulse),       // Single-cycle start
        .tx      (tx),
        .busy    (uart_tx_busy)
    );

    //==============================================================
    // 4. UART Receiver
    //==============================================================
    // data_valid pulses for one cycle when byte reception complete.
    // ready indicates receiver is idle (high during IDLE and STOP).
    //==============================================================
    uart_rx uart_rx_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_enb     (rx_enb),
        .rx         (rx),
        .data_out   (rx_fifo_in),
        .data_valid (rx_data_valid),
        .ready      (uart_rx_ready)
    );

    //==============================================================
    // 5. RX FIFO
    //==============================================================
    // Written on data_valid, gated by ~full to prevent overflow.
    //==============================================================
    fifo rx_fifo_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_data (rx_fifo_in),
        .wr_en   (rx_fifo_wr_en),
        .full    (rx_full),
        .rd_en   (rx_rd_en),
        .rd_data (rx_data_out),
        .empty   (rx_empty)
    );

    //==============================================================
    // Output Assignments
    //==============================================================
    assign tx_empty = tx_fifo_empty;

endmodule
