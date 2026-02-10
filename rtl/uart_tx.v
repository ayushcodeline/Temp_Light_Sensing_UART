module uart_tx (
    // System Ports
    input wire clk,             // Main Clock (e.g., 50 MHz)
    input wire rst,             // Asynchronous Reset (Active Low)

    // Data Input and Control
    input wire [7:0] data_in,   // Parallel 8-bit data to transmit (from adc_interface)
    input wire tx_start,        // Rising edge signal to start transmission

    // Output Port
    output reg txd = 1'b1,      // Serial Transmit Line (Idle state is High)
    output reg tx_busy = 1'b0   // High when transmission is in progress
);

    // --- 1. Parameter Definitions ---
    // Assuming a 50 MHz clock (20 ns period)
    localparam CLK_FREQ    = 50_000_000;
    localparam BAUD_RATE   = 9600;

    // Baud Count = (Clock Frequency / Baud Rate) - 1
    // 50,000,000 / 9600 = 5208.33. Use 5208.
    localparam BAUD_COUNT  = CLK_FREQ / BAUD_RATE;

    // --- 2. State Machine Definitions ---
    localparam IDLE     = 3'd0; // Waiting for tx_start
    localparam START    = 3'd1; // Sending Start Bit
    localparam DATA     = 3'd2; // Sending Data Bits
    localparam STOP     = 3'd3; // Sending Stop Bit
    localparam CLEANUP  = 3'd4; // Optional short delay before returning to IDLE

    // --- 3. Internal Signals and Registers ---
    reg [12:0] baud_counter = 0; // Counter for baud rate timing (must be large enough for BAUD_COUNT)
    reg tx_tick = 0;             // High for one clock cycle when a new bit period starts

    reg [2:0] state = IDLE;      // Current state of the transmitter
    reg [3:0] bit_counter = 0;   // Counts the 8 data bits (0 to 7)
    reg [7:0] tx_data_reg = 0;   // Register to hold the data being transmitted

    // --- 4. Baud Rate Generator Logic ---
    // Generates a 'tx_tick' pulse exactly once per bit period (BAUD_COUNT clock cycles)
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            baud_counter <= 0;
            tx_tick <= 0;
        end
        else begin
            if (tx_busy == 1'b1) begin // Only count when a transmission is active
                if (baud_counter == BAUD_COUNT - 1) begin
                    baud_counter <= 0;
                    tx_tick <= 1'b1; // Pulse high for one cycle (Bit Period Tick)
                end
                else begin
                    baud_counter <= baud_counter + 1;
                    tx_tick <= 1'b0;
                end
            end
            else begin
                baud_counter <= 0;
                tx_tick <= 1'b0;
            end
        end
    end

    // --- 5. UART State Machine and Output Logic ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            state <= IDLE;
            txd <= 1'b1;         // Serial line idle is HIGH
            tx_busy <= 1'b0;
            bit_counter <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    txd <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin // Transition on tx_start pulse
                        tx_data_reg <= data_in; // Load the data
                        tx_busy <= 1'b1;
                        state <= START;
                        bit_counter <= 0;
                    end
                end

                START: begin
                    txd <= 1'b0; // Send Start Bit (Logic Low)
                    if (tx_tick) begin
                        state <= DATA;
                    end
                end

                DATA: begin
                    txd <= tx_data_reg[bit_counter]; // Send current bit (LSB first)
                    if (tx_tick) begin
                        if (bit_counter == 7) begin // Finished 8 bits
                            state <= STOP;
                        end
                        else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end

                STOP: begin
                    txd <= 1'b1; // Send Stop Bit (Logic High)
                    if (tx_tick) begin
                        state <= IDLE;
                    end
                end

                // Default state handles unexpected conditions, returning to IDLE
                default: state <= IDLE;

            endcase
        end
    end

endmodule
