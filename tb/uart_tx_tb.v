`timescale 1ns / 1ps

module uart_tx_tb;

    // --- Testbench Signals ---
    reg clk;
    reg rst;
    reg [7:0] data_in;
    reg tx_start;
    wire txd;
    wire tx_busy;

    // --- Parameters (Must match the DUT parameters) ---
    parameter CLK_PERIOD = 20; // 50 MHz clock
    // Baud Count for 9600 bps: 5208 clock cycles per bit.
    // Bit Period = 5208 * 20 ns = 104,160 ns (104.16 us)
    parameter BIT_PERIOD = 104160;

    // --- Instantiate the Device Under Test (DUT) ---
    uart_tx DUT (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .tx_start(tx_start),
        .txd(txd),
        .tx_busy(tx_busy)
    );

    // --- Clock Generation ---
    always begin
        #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Stimulus Generation ---
    initial begin
        // 1. Initial Reset
        clk = 0;
        rst = 0;
        tx_start = 0;
        data_in = 8'h00;
        
        # (CLK_PERIOD * 4);
        rst = 1; // Release Reset

        // Wait for system to stabilize
        # (CLK_PERIOD * 4); 

        // 2. Test Case 1: Transmit the letter 'A' (ASCII: 0100 0001)
        // Note: UART sends LSB first, so the sequence will be 1 0000 010 (Start, LSB->MSB, Stop)
        data_in = 8'h41; 
        tx_start = 1; // Assert tx_start to initiate transmission
        # (CLK_PERIOD * 2); 
        tx_start = 0; // Deassert tx_start (requires only a single clock pulse)
        
        // Wait for 10 bit times (Start + 8 Data + Stop)
        # (BIT_PERIOD * 10.5); 

        // 3. Test Case 2: Transmit the value 25 (0001 1001) - Example from Module 1
        // Sequence (LSB first): 1 0011 000 (Start, LSB->MSB, Stop)
        data_in = 8'd25; 
        tx_start = 1;
        # (CLK_PERIOD * 2);
        tx_start = 0;

        // Wait for 10 bit times
        # (BIT_PERIOD * 10.5); 
        
        // 4. Finish Simulation
        $finish;
    end

endmodule