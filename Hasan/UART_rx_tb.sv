module UART_rx_tb();

    // Inputs
    reg clk;
    reg rst_n;
    reg RX;
    reg clr_rdy;

    // Outputs
    wire [7:0] rx_data;
    wire rdy;

    // Instantiate UART_rx module
    UART_rx iDUT (
        .clk(clk), 
        .rst_n(rst_n), 
        .RX(RX), 
        .clr_rdy(clr_rdy), 
        .rx_data(rx_data), 
        .rdy(rdy)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        RX = 1; // idle state of RX is high
        clr_rdy = 0;

        // Wait for global reset to finish
        #10;
        
        // Release reset
        rst_n = 1;

        #10;

        // Check if ready signal is high after reset
        if(rdy) begin
            $display("Test 1 passed");
        end else begin
            $display("Reset failed: Ready signal is low.");
            $stop();
        end

        // Simulate receiving a byte (e.g., 0xA5) 19200
        #10 RX = 0; // start bit
        #6864 RX = 1; // bit 0
        #6864 RX = 0; // bit 1
        #6864 RX = 1; // bit 2
        #6864 RX = 0; // bit 3
        #6864 RX = 0; // bit 4
        #6864 RX = 1; // bit 5
        #6864 RX = 0; // bit 6
        #6864 RX = 1; // bit 7
        #6864 RX = 1; // stop bit

        // Wait for the data to be processed
        #1000;

        // Check the received data and ready signal here (using $display or assertions)
        if(rx_data == 8'hA5) begin
            $display("Test 2 passed");
        end else begin
            $display("Test Failed: Received data or ready signal is incorrect.");
            $stop();
        end

        clr_rdy = 1; // Clear ready signal
        if(!rdy) begin
            $display("Test 3 passed");
        end else begin
            $display("Failed to clear ready signal.");
            $stop();
        end
        $stop();
    end
    
    always #5 clk = ~clk; //clock signal

endmodule