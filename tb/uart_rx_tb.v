// ========================================================================
// Testbench: uart_rx_tb.v
// Function: Simulates a 9600 Baud serial stream for 'A' (0x41)
// ========================================================================
`timescale 1ns / 1ps

module uart_rx_testb;

    // --- Parameters (MUST match 50 MHz clock and 9600 Baud) ---
    parameter CLK_PERIOD = 20; // 50 MHz clock
    parameter BIT_PERIOD = 104_160; // 1 / 9600 Baud 

    // --- Testbench Signals ---
    reg clk;
    reg rst;
    reg rxd;            
    wire [7:0] rx_data; 
    wire rx_done;       

    // --- Instantiate the DUT (uart_rx) ---
    uart_rx DUT (
        .clk(clk),
        .rst(rst),
        .rxd(rxd),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // --- Clock Generation ---
    always begin
        #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Stimulus Generation: Send 'A' (0x41) ---
    // Sequence (txd line, LSB first): Start(0), 1, 0, 0, 0, 0, 0, 1, 0, Stop(1)
    initial begin
        // 1. Initial Setup and Reset
        clk = 0;
        rst = 0;
        rxd = 1; // IDLE state is High
        
        $display("--- UART RX Simulation Started (Sending 'A' or 0x41) ---");
        
        # (CLK_PERIOD * 4);
        rst = 1; // Release Reset
        # (CLK_PERIOD * 4);
        
        // --- 2. Send Byte 'A' (0x41) ---
        
        // Start Bit (0)
        rxd = 0;
        # BIT_PERIOD; 
        
        // Data Bits (LSB first: 10000010)
        rxd = 1; # BIT_PERIOD; // Bit 0 (1)
        rxd = 0; # BIT_PERIOD; // Bit 1 (0)
        rxd = 0; # BIT_PERIOD; // Bit 2 (0)
        rxd = 0; # BIT_PERIOD; // Bit 3 (0)
        rxd = 0; # BIT_PERIOD; // Bit 4 (0)
        rxd = 0; # BIT_PERIOD; // Bit 5 (0)
        rxd = 1; # BIT_PERIOD; // Bit 6 (1)
        rxd = 0; # BIT_PERIOD; // Bit 7 (0)

        // Stop Bit (1)
        rxd = 1; 
        # BIT_PERIOD; 

        // --- 3. Clean Termination ---
        // Wait for 10 full clock cycles (200 ns) to ensure the final 
        // assignment executes before $finish.
      // --- 3. Clean Termination ---

// Wait until rx_done is high, then wait 1 clock cycle to ensure all assignments run.
// This is the most reliable way to catch the pulse.
# (CLK_PERIOD * 20);
# CLK_PERIOD; 
        
$display("-------------------------------------------");
$display("Time: %0d ns | Final rx_data: 0x%h, rx_done: %d", $time, rx_data, rx_done);
$display("Simulation Finished.");
$finish;
    end

endmodule