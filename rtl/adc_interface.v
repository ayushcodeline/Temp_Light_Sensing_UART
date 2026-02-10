module adc_interface(

    // System Control Ports
    input wire clk,             // Main Clock signal
    input wire rst,             // Asynchronous Reset signal (Active Low)

    // Input Data Ports (Parallel data from simulated ADC/Testbench)
    input wire [7:0] temp_in,   // 8-bit digital temperature value (e.g., 0-255)
    input wire [7:0] light_in,  // 8-bit digital light intensity value (e.g., 0-255)

    // Output Data Ports (Synchronized data passed to UART/Core Logic)
    output reg [7:0] temp_out,
    output reg [7:0] light_out
);

    // --- Synchronous Data Capture Logic ---
    // Registers the input data on the positive edge of the clock (posedge clk).
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin // Reset is active (low)
            temp_out <= 8'h00;
            light_out <= 8'h00;
        end
        else begin
            // Capture the input data and hold it until the next clock edge
            temp_out <= temp_in;
            light_out <= light_in;
        end
    end
endmodule