//==================================================================
// Clean Testbench with Accurate Baud Rate Measurement
// Simplified Version - Using Only Instantaneous Calculation
//==================================================================

module tb_baud_rate_generator;

    reg        clk;
    reg        rst_n;
    wire       rx_enb;
    wire       tx_enb;

    reg [31:0] cycle_count = 0;
    
    // Baud Rate Measurement Variables
    integer    tx_pulse      = 0;
    reg [63:0] prev_tx_time  = 0;
    real       baud_rate     = 0.0;

    // DUT Instantiation
    baud_rate_generator dut (.*);

    // Clock Generation (50MHz example)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // 50 MHz clock (20ns period)
    end

    // Cycle Counter
    always @(posedge clk) begin
        if (rst_n)
            cycle_count <= cycle_count + 1;
    end

    //============================================================
    // TX Pulse Detection & Instantaneous Baud Rate Measurement
    //============================================================
    always @(posedge tx_enb) begin
        tx_pulse = tx_pulse + 1;           // Blocking assignment

        if (tx_pulse == 1) begin
            prev_tx_time = $time;
        end 
        else begin
            // Instantaneous baud rate calculation
            if (prev_tx_time != 0) begin
                baud_rate = 1_000_000_000.0 / ($time - prev_tx_time);
            end
            prev_tx_time = $time;
        end
    end

    // Reset Measurement Variables
    always @(negedge rst_n) begin
        tx_pulse     = 0;
        prev_tx_time = 0;
        baud_rate    = 0.0;
    end

    // ====================== Display ======================
    initial begin
        $display("====================================================================");
        $display("     BAUD RATE GENERATOR TESTBENCH - Simplified Version");
        $display("====================================================================");
        $display("   Time(ns)    Cycles    TX_Cnt   RX_Cnt   TX_enb   RX_enb");
        $display("-------------------------------------------------------------------");

        rst_n = 0;
        #50;
        rst_n = 1;
        #30;
    end

    // Print on every TX or RX pulse
    always @(posedge tx_enb or posedge rx_enb) begin
        $display("%10t   %8d   %6d   %6d      %b        %b", 
                 $time, cycle_count, dut.tx_counter, dut.rx_counter, tx_enb, rx_enb);
    end

    // Periodic Measurement Display
    always @(posedge tx_enb) begin
        if (tx_pulse % 50 == 0 && tx_pulse > 5) begin
            $display("   [MEAS] Pulses=%0d | Baud Rate = %.2f", 
                     tx_pulse, baud_rate);
        end
    end

    // Final Summary
    initial begin
        #800_000;   // Run long enough for good measurement
        
        $display("-------------------------------------------------------------------");
        $display("                         SIMULATION SUMMARY");
        $display("-------------------------------------------------------------------");
        $display("Total Clock Cycles     : %0d", cycle_count);
        $display("TX Pulses              : %0d", tx_pulse);
        $display("Measured TX Baud Rate  : %.2f baud", baud_rate);
        $display("Target Baud Rate       : 9600 baud");
        $display("Error                  : %.4f %%", ((baud_rate - 9600)/9600)*100);
        $display("====================================================================");
        $finish;
    end

endmodule
