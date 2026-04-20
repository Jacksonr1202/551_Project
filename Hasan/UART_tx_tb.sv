module UART_tx_tb;

  // clock and reset
  reg clk;
  reg rst_n;

  // DUT interface
  reg trmt;
  reg [7:0] tx_data;
  wire TX;
  wire tx_done;

  // instantiate transmitter under test
  UART_tx iDUT (
      .clk(clk),
      .rst_n(rst_n),
      .TX(TX),
      .trmt(trmt),
      .tx_data(tx_data),
      .tx_done(tx_done)
  );

  // 19200 baud corresponds to a bit period of ~52.083 us = 52083 ns
  localparam integer BAUD_PERIOD = 52083;

  // main test sequence – simple single‑byte exercise
  initial begin
    reg sampled;
    clk = 0;

    // initialize
    rst_n = 0;
    trmt = 0;
    tx_data = 8'h00;
    #100;               // hold reset
    rst_n = 1;

    // transmit one byte (0xA5) and check start/data/stop bits
    @(posedge clk);
    tx_data = 8'hF0;
    trmt = 1;
    @(posedge clk);
    trmt = 0;

    #(BAUD_PERIOD/2);
    sampled = TX;
    if (sampled !== 1'b0)
      $display("ERROR: start bit wrong, got %b", sampled);

    // bit0
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b1) $display("ERROR: data bit0 wrong");
    // bit1
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b1) $display("ERROR: data bit1 wrong");
    // bit2
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b1) $display("ERROR: data bit2 wrong");
    // bit3
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b1) $display("ERROR: data bit3 wrong");
    // bit4
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b0) $display("ERROR: data bit4 wrong");
    // bit5
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b0) $display("ERROR: data bit5 wrong");
    // bit6
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b0) $display("ERROR: data bit6 wrong");
    // bit7
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b0) $display("ERROR: data bit7 wrong");

    // stop bit
    #(BAUD_PERIOD);
    sampled = TX;
    if (sampled !== 1'b1)
      $display("ERROR: stop bit wrong, got %b", sampled);

    @(posedge tx_done);
    $display("TEST COMPLETE");
    $stop();
  end

  always
    #5 clk = ~clk; // 100 MHz clock for better timing resolution

endmodule
