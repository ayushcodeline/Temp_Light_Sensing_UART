module uart_rx (
    input wire clk,
    input wire rst,
    
    // Serial Input
    input wire rxd,             
    output reg [7:0] rx_data = 8'h00,  // Received 8-bit data
    output reg rx_done = 1'b0          // Pulse high when a byte is received
);

    // --- Parameters (50 MHz / 9600 Baud) ---
    localparam CLKS_PER_BIT = 5208; // 50,000,000 / 9600 = 5208.33
    localparam SAMPLE_OFFSET = 2604; // CLKS_PER_BIT / 2
    
    // --- Internal State and Counters ---
    reg [1:0] state = 2'd0;         // 0: IDLE, 1: SAMPLING_START, 2: RECEIVING
    reg [12:0] clk_count = 0;
    reg [3:0] bit_count = 0;
    reg [7:0] data_shifter = 0;
    
    // --- Main Receiver Logic ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin 
            clk_count <= 0;
            bit_count <= 0;
            state <= 2'd0;
            rx_done <= 1'b0;
            rx_data <= 8'h00;
            data_shifter <= 8'h00; // Initialize shifter
        end
        else begin
            
            case (state)
                2'd0: begin // IDLE: Waiting for Start Bit (rxd == 0)
                    rx_done <= 1'b0; // Reset pulse here
                    if (rxd == 1'b0) begin
                        // Load counter to sample center of Start Bit
                        clk_count <= SAMPLE_OFFSET; 
                        state <= 2'd1; 
                    end
                end
                
                2'd1: begin // SAMPLING START BIT (Half-bit delay)
                    if (clk_count == CLKS_PER_BIT - 1) begin 
                        if (rxd == 1'b0) begin 
                            state <= 2'd2;
                            bit_count <= 0; 
                        end else begin
                            state <= 2'd0; // False Start
                        end
                        clk_count <= 0; // Reset for the first full data bit period
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                2'd2: begin // RECEIVING DATA AND STOP BITS
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        
                        if (bit_count < 8) begin 
                            // 1. Receiving 8 Data Bits (bit_count 0 to 7)
                            // SHIFT CORRECTED: Shifts right, placing new bit (rxd) in LSB (index 0)
                            data_shifter <= {rxd, data_shifter[7:1]}; 
                            bit_count <= bit_count + 1;
                        end
                        else if (bit_count == 8) begin 
                            // 2. CHECK STOP BIT (bit_count 8)
                            if (rxd == 1'b1) begin
                                rx_data <= data_shifter; 
                                rx_done <= 1'b1; 
                            end
                            state <= 2'd0; // Go back to IDLE
                        end
                        
                        clk_count <= 0; // Reset counter for the next bit period
                    end
                    else begin
                        clk_count <= clk_count + 1;
                    end
                end
            endcase
        end
    end

endmodule
