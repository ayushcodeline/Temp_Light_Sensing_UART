module lcd_driver (
    // System Ports
    input wire clk,                 // Main Clock (e.g., 50 MHz)
    input wire rst,                 // Asynchronous Reset (Active Low)

    // Data Input and Control (Simulated data from UART/Core Logic)
    input wire [7:0] lcd_data_in,   // 8-bit data/command to be displayed
    input wire lcd_send,            // Pulse high when a new byte is ready to send
    input wire rs_select,           // 0: Command, 1: Data (e.g., Temp/Light value)

    // Output Pins (To simulated LCD)
    output reg lcd_rs = 1'b0,       // Register Select (0=Command, 1=Data)
    output reg lcd_en = 1'b0,       // Enable Pin (Pulse High to transfer data)
    output reg [7:0] lcd_data_bus = 8'h00 // 8-bit Data Bus
);

    // --- Parameter and Internal Signals ---
    // A simplified counter to generate the 'Enable' pulse width.
    // Assuming 50 MHz clock (20ns period). 25 cycles * 20ns = 500ns (Enough for >450ns pulse)
    localparam EN_PULSE_CYCLES = 25; 

    reg [4:0] pulse_counter = 0;
    reg update_flag = 1'b0; // Flag to hold the current command/data until pulse completes

    // --- State Machine / Pulse Generator Logic ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            lcd_rs <= 1'b0;
            lcd_en <= 1'b0;
            lcd_data_bus <= 8'h00;
            pulse_counter <= 0;
            update_flag <= 1'b0;
        end
        else begin
            // 1. Start of Command/Data Cycle
            if (lcd_send) begin
                // Latch the new data/command and RS selection
                lcd_data_bus <= lcd_data_in;
                lcd_rs <= rs_select;
                
                // Start the pulse and counter
                lcd_en <= 1'b1;
                pulse_counter <= 0;
                update_flag <= 1'b1; // Transmission active
            end
            
            // 2. Pulse Timing (Counting while update is active)
            else if (update_flag) begin
                if (pulse_counter < EN_PULSE_CYCLES - 1) begin
                    pulse_counter <= pulse_counter + 1;
                    lcd_en <= 1'b1; // Keep Enable high during count
                end
                else begin
                    // Pulse End: Reset Enable and flag
                    lcd_en <= 1'b0;
                    update_flag <= 1'b0;
                    pulse_counter <= 0;
                end
            end
            
            // 3. Idle State
            else begin
                lcd_en <= 1'b0;
            end
        end
    end

endmodule