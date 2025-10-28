// Timescale directive: defines simulation time unit (1ns) and time precision (1ps)
`timescale 1ns / 1ps

// SPI (Serial Peripheral Interface) State Machine Module
module spi_state(
    input    wire  clk,           // System clock input
    input    wire  reset,         // Asynchronous reset input (active high)
    input    wire  [15:0] datain, // 16-bit parallel data input to be transmitted
    output   wire  spi_cs_l,      // SPI Chip Select output (active low)
    output   wire  spi_sclk,      // SPI Clock output
    output   wire  spi_data,      // SPI Data output (MOSI - Master Out Slave In)
    output   [4:0]counter         // Debug output showing current bit position
);

    // Internal registers
    reg [15:0] MOSI;     // Holds the current bit being transmitted
    reg [4:0] count;     // Counts from 16 down to 0 (tracks bits remaining)
    reg cs_l;            // Internal chip select signal
    reg sclk;            // Internal SPI clock signal
    reg [2:0]state;      // State machine current state register

    // Main state machine logic
    // Triggers on either positive clock edge or positive reset edge
    always @ (posedge clk or posedge reset)
        if (reset) begin
            // Reset condition - initialize all registers
            MOSI <= 16'b0;        // Clear MOSI register
            count<= 5'd16;        // Set counter to 16 (total bits to transmit)
            cs_l <= 1'b1;         // Deactivate chip select (active low)
            sclk <= 1'b0;         // Initialize clock to low
        end		
    
        else begin
            case (state)
                // State 0: Idle/Initialize State
                0: begin
                    sclk <= 1'b0;      // Keep clock low
                    cs_l <= 1'b1;      // Keep chip select inactive
                    state<=1;          // Move to next state
                end
    
                // State 1: Setup Data Bit
                1: begin
                    sclk <= 1'b0;      // Set clock low for setup
                    cs_l <= 1'b0;      // Activate chip select
                    MOSI <=datain[count-1];  // Load next bit from input data
                    count <=count-1;    // Decrement bit counter
                    state <=2;          // Move to clock high state
                end
    
                // State 2: Clock High / Data Valid
                2: begin
                    sclk <= 1'b1;      // Set clock high to latch data
                    if(count > 0)       // If more bits to send
                        state<=1;       // Go back to setup next bit
                    else begin          // If all bits sent
                        count<=16;      // Reset counter for next transmission
                        state<=0;       // Go back to idle state
                    end
                end
    
                // Default case - go to idle state
                default:state<=0;
    
            endcase
        end

    // Output assignments
    assign spi_cs_l = cs_l;     // Connect internal chip select to output
    assign spi_sclk = sclk;     // Connect internal clock to output
    assign spi_data = MOSI;     // Connect internal data to output
    assign counter=count;        // Connect internal counter to output
    
endmodule
