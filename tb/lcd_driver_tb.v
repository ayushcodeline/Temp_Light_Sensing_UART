// ========================================================================
// Testbench for Module 3: lcd_driver_tb.v
// Function: Verifies the correct generation of LCD control pulses and data.
// ========================================================================
`timescale 1ns / 1ps

module lcd_driver_tb;

    // --- Testbench Signals ---
    reg clk;
    reg rst;
    reg [7:0] lcd_data_in;
    reg lcd_send;
    reg rs_select;

    wire lcd_rs;
    wire lcd_en;
    wire [7:0] lcd_data_bus;

    // --- Parameters ---
    parameter CLK_PERIOD = 20; // 50 MHz clock
    // Pulse duration check: 25 clock cycles * 20 ns = 500 ns
    parameter PULSE_DURATION = 500; 
    // Time needed between commands/data for the LCD to process (t_HD44780_write_us > 40 us)
    parameter LCD_PROCESSING_DELAY = 100_000; // 100 us

    // --- Instantiate the DUT ---
    lcd_driver DUT (
        .clk(clk),
        .rst(rst),
        .lcd_data_in(lcd_data_in),
        .lcd_send(lcd_send),
        .rs_select(rs_select),
        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en),
        .lcd_data_bus(lcd_data_bus)
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
        lcd_send = 0;
        rs_select = 0;
        lcd_data_in = 8'h00;
        
        $display("--- LCD Driver Simulation Started ---");
        
        # (CLK_PERIOD * 4);
        rst = 1; // Release Reset
        # (CLK_PERIOD * 4); 

        // 2. Test Case 1: Send Initialization Command (e.g., Function Set 0x38)
        $display("Time: %0d ns | Sending Command: Function Set (0x38)", $time);
        lcd_data_in = 8'h38; // Command: 8-bit mode, 2 lines, 5x8 dots
        rs_select = 0;       // RS=0 (Command)
        lcd_send = 1;        // Trigger send
        # CLK_PERIOD;
        lcd_send = 0;        // Deactivate trigger

        // Wait for the pulse to complete (approx 500ns) and LCD processing delay
        # (LCD_PROCESSING_DELAY);

        // 3. Test Case 2: Send Clear Display Command (0x01)
        $display("Time: %0d ns | Sending Command: Clear Display (0x01)", $time);
        lcd_data_in = 8'h01; // Command: Clear Display
        rs_select = 0;       // RS=0 (Command)
        lcd_send = 1;
        # CLK_PERIOD;
        lcd_send = 0;

        // Wait for the pulse to complete and LCD processing delay
        # (LCD_PROCESSING_DELAY);

        // 4. Test Case 3: Send Data (e.g., 'T' for Temperature)
        $display("Time: %0d ns | Sending Data: 'T' (0x54)", $time);
        lcd_data_in = 8'h54; // ASCII for 'T'
        rs_select = 1;       // RS=1 (Data)
        lcd_send = 1;
        # CLK_PERIOD;
        lcd_send = 0;

        // Wait for the pulse to complete
        # (PULSE_DURATION * 2);

        // 5. Finish Simulation
        $display("-------------------------------------------");
        $display("Simulation Finished.");
        $finish;
    end

endmodule
