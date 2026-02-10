`timescale 1ns / 1ps

module adc_interface_tb;

    // --- Testbench Signals (Mismatched types for connection) ---
    reg clk;
    reg rst;
    reg [7:0] temp_in;
    reg [7:0] light_in;

    wire [7:0] temp_out;
    wire [7:0] light_out;

    // --- Parameter Definitions ---
    // Define a clock period for simulation (e.g., 10 ns for a 100 MHz clock)
    parameter CLK_PERIOD = 10;

    // --- Instantiate the Device Under Test (DUT) ---
    adc_interface DUT (
        .clk(clk),
        .rst(rst),
        .temp_in(temp_in),
        .light_in(light_in),
        .temp_out(temp_out),
        .light_out(light_out)
    );

    // --- Clock Generation ---
    always begin
        #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Stimulus Generation ---
    initial begin
        // 1. Initial Reset and Setup
        clk = 1'b0;
        rst = 1'b0;          // Assert Reset (Active Low)
        temp_in = 8'hFF;     // Input doesn't matter during reset
        light_in = 8'hFF;
        $display("Time | rst | temp_in | temp_out");

        // Wait a few clock cycles in reset
        # (CLK_PERIOD * 3);

        // 2. Release Reset and Initial Values
        rst = 1'b1;         // Deassert Reset
        temp_in = 8'd25;    // Simulate 25 degrees (Normal Condition)
        light_in = 8'd150;  // Simulate Medium Light
        # CLK_PERIOD;       // Wait one clock cycle for data to be captured
        $display("%4d | %1b | %7d | %8d", $time, rst, temp_in, temp_out); // Check temp_out

        // 3. New Reading: Bright Location
        temp_in = 8'd25;
        light_in = 8'd240;  // High Light Value
        # CLK_PERIOD;
        $display("%4d | %1b | %7d | %8d", $time, rst, temp_in, temp_out); // Check temp_out

        // 4. New Reading: Dark Location (Higher LDR resistance -> Lower ADC value)
        temp_in = 8'd20;
        light_in = 8'd10;   // Low Light Value
        # CLK_PERIOD;
        $display("%4d | %1b | %7d | %8d", $time, rst, temp_in, temp_out); // Check temp_out

        // 5. Finish Simulation
        # (CLK_PERIOD * 2);
        $finish;
    end

endmodule
