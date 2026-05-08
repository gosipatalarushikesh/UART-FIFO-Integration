//==================================================================
// Testbench - WITH DEBUG OUTPUT
//==================================================================

`timescale 1ns / 1ps

module tb_uart_rx;

    reg        clk;
    reg        rst_n;
    reg        rx_enb;
    reg        rx;
    
    wire [7:0] data_out;
    wire       data_valid;
    wire       ready;

    parameter CLK_PERIOD = 20;  // 50MHz = 20ns
    
    uart_rx dut (.*);

    // 50 MHz clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 16x baud tick - one pulse every 16 clock cycles for simplicity
    reg [4:0] tick_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_counter <= 5'b0;
            rx_enb <= 1'b0;
        end else begin
            tick_counter <= tick_counter + 1'b1;
            if (tick_counter == 5'd15) begin
                rx_enb <= 1'b1;
                tick_counter <= 5'b0;
            end else begin
                rx_enb <= 1'b0;
            end
        end
    end

    // UART transmit task - each bit is 16 rx_enb pulses
    task send_byte(input [7:0] data);
        integer i;
        begin
            $display("[%0t] Starting transmission of 0x%02h", $time, data);
            
            // Start bit
            rx = 0;
            repeat(16) @(posedge rx_enb);
            $display("[%0t] Start bit sent", $time);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                repeat(16) @(posedge rx_enb);
                $display("[%0t] Bit %0d = %b sent", $time, i, data[i]);
            end

            // Stop bit
            rx = 1;
            repeat(16) @(posedge rx_enb);
            $display("[%0t] Stop bit sent", $time);
            
            // Idle
            rx = 1;
            repeat(16) @(posedge rx_enb);
        end
    endtask

    initial begin
        $display("=== UART RX Test ===");
        $display("Clock: 50MHz, Tick every 16 cycles");
        
        // Initialize
        rst_n = 0;
        rx    = 1;
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        
        $display("[%0t] Reset released, ready = %b", $time, ready);

        // Send test byte
      send_byte(8'hFF);
        
        // Wait for data_valid with timeout
        fork
            begin
                wait(data_valid);
                $display("[%0t] SUCCESS: Received 0x%02h (Expected 0xA5) %s", 
                         $time, data_out, (data_out === 8'hA5) ? "PASS" : "FAIL");
            end
            begin
                #1000000;  // 1ms timeout
                $display("[%0t] ERROR: Timeout waiting for data_valid", $time);
            end
        join_any
        disable fork;

        #10000;
        $finish;
    end

endmodule
