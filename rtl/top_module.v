// ========================================================================
// Module: top_module.v
// Final Integration with Synthesis and Schematic Fixes
// ========================================================================
module top_module (
    // System Ports
    input wire clk,
    input wire rst,
    
    // External ADC/Sensor Inputs (Simulated)
    input wire [7:0] light_adc_in,  // Light data from ADC
    input wire [7:0] temp_adc_in,   // Temp data from ADC
    
    // External UART Pin (Used for internal loopback)
    inout wire serial_link,          // Connects txd to rxd
    
    // External LCD Pins (Outputs)
    output wire lcd_rs,
    output wire lcd_en,
    output wire [7:0] lcd_data_bus
);

    // --- Internal Wires ---
    wire [7:0] temp_out_w, light_out_w;
    wire txd_w;             // Wire driven by the UART Transmitter
    wire tx_busy_w;
    wire rxd_w;             // Wire read by the UART Receiver
    wire [7:0] rx_data_w;
    wire rx_done_w;
    wire [7:0] current_tx_data;
    wire tx_trigger_pulse;
    wire lcd_send_pulse;
    wire rs_select_w;
    
    // --- 1. Control Logic: Sequencer and Trigger ---
    
    // A. Slow Pulse Generator (50 MHz / 10 = 5,000,000 cycles for 100ms)
    // SYNTHESIS FIX: Using integer division.
    localparam TRIGGER_MAX = (50_000_000 / 10) - 1; // 4,999,999
    reg [24:0] trigger_counter = 0;
    reg tx_trigger_reg = 0; 
    
    // State machine for alternating between Temp (0) and Light (1)
    localparam TEMP_STATE = 1'b0;
    localparam LIGHT_STATE = 1'b1;
    reg tx_data_select = TEMP_STATE; 
    
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            trigger_counter <= 0;
            tx_trigger_reg <= 0;
            tx_data_select <= TEMP_STATE; 
        end else begin
            tx_trigger_reg <= 1'b0; 
            
            if (trigger_counter == TRIGGER_MAX) begin
                trigger_counter <= 0;
                tx_trigger_reg <= 1'b1; // Assert pulse
                
                // Toggle the selection state on trigger
                tx_data_select <= ~tx_data_select; 
            end else begin
                trigger_counter <= trigger_counter + 1;
            end
        end
    end
    
    // B. Data Mux for Transmission
    assign current_tx_data = (tx_data_select == TEMP_STATE) ? temp_out_w : light_out_w;
    assign tx_trigger_pulse = tx_trigger_reg & ~tx_busy_w; 

    // C. Data Mux for LCD Display
    assign lcd_send_pulse = rx_done_w;
    assign rs_select_w = 1'b1;
    
    // --- 2. Instance Declarations ---

    // A. ADC Interface
    adc_interface u_adc_interface (
        .clk(clk),
        .rst(rst),
        .temp_in(temp_adc_in),
        .light_in(light_adc_in),
        .temp_out(temp_out_w),
        .light_out(light_out_w)
    );
    
    // B. UART Transmitter
    uart_tx u_uart_tx (
        .clk(clk),
        .rst(rst),
        .data_in(current_tx_data),
        .tx_start(tx_trigger_pulse),
        .txd(txd_w),             // Transmitter drives local wire txd_w
        .tx_busy(tx_busy_w)
    );

    // C. Bidirectional Connection / Loopback Logic FIX: Connects serial_link
    
    // 1. Output Drive: txd_w drives the external pin (serial_link).
    // The conditional operator creates the required tri-state (high-Z when txd_w is low).
    assign serial_link = txd_w ? 1'b1 : 1'bz;

    // 2. Receiver Input: Receiver reads the value directly from the external pin.
    assign rxd_w = serial_link;
    
    uart_rx u_uart_rx (
        .clk(clk),
        .rst(rst),
        .rxd(rxd_w),             // Receiver input is from the external port
        .rx_data(rx_data_w),
        .rx_done(rx_done_w)
    );

    // D. LCD Driver
    lcd_driver u_lcd_driver (
        .clk(clk),
        .rst(rst),
        .lcd_data_in(rx_data_w), // Recovered data
        .lcd_send(lcd_send_pulse), 
        .rs_select(rs_select_w),
        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en),
        .lcd_data_bus(lcd_data_bus)
    );

endmodule




