`timescale 1ns/1ps

module MazeRunner_tb();

  reg clk, RST_n;
  reg send_cmd;
  reg [15:0] cmd;
  reg [11:0] batt;

  logic cmd_sent;
  logic resp_rdy;
  logic [7:0] resp;
  logic hall_n;

  wire TX_RX, RX_TX;
  wire INRT_SS_n, INRT_SCLK, INRT_MOSI, INRT_MISO, INRT_INT;
  wire lftPWM1, lftPWM2, rghtPWM1, rghtPWM2;
  wire A2D_SS_n, A2D_SCLK, A2D_MOSI, A2D_MISO;
  wire IR_lft_en, IR_cntr_en, IR_rght_en;
  wire piezo;

  MazeRunner iDUT(
    .clk(clk), .RST_n(RST_n),
    .INRT_SS_n(INRT_SS_n), .INRT_SCLK(INRT_SCLK), .INRT_MOSI(INRT_MOSI),
    .INRT_MISO(INRT_MISO), .INRT_INT(INRT_INT),
    .A2D_SS_n(A2D_SS_n), .A2D_SCLK(A2D_SCLK), .A2D_MOSI(A2D_MOSI),
    .A2D_MISO(A2D_MISO),
    .lftPWM1(lftPWM1), .lftPWM2(lftPWM2),
    .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
    .RX(RX_TX), .TX(TX_RX),
    .hall_n(hall_n),
    .piezo(piezo), .piezo_n(),
    .IR_lft_en(IR_lft_en), .IR_rght_en(IR_rght_en), .IR_cntr_en(IR_cntr_en),
    .LED()
  );

  RemoteComm iCMD(
    .clk(clk), .rst_n(RST_n),
    .RX(TX_RX), .TX(RX_TX),
    .cmd(cmd), .snd_cmd(send_cmd),
    .cmd_snt(cmd_sent), .resp_rdy(resp_rdy), .resp(resp)
  );

  RunnerPhysics iPHYS(
    .clk(clk), .RST_n(RST_n),
    .SS_n(INRT_SS_n), .SCLK(INRT_SCLK), .MISO(INRT_MISO), .MOSI(INRT_MOSI),
    .INT(INRT_INT),
    .lftPWM1(lftPWM1), .lftPWM2(lftPWM2),
    .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
    .IR_lft_en(IR_lft_en), .IR_cntr_en(IR_cntr_en), .IR_rght_en(IR_rght_en),
    .A2D_SS_n(A2D_SS_n), .A2D_SCLK(A2D_SCLK), .A2D_MOSI(A2D_MOSI),
    .A2D_MISO(A2D_MISO),
    .hall_n(hall_n), .batt(batt)
  );

  always #5 clk = ~clk;


`define WAIT_EXPR(expr, cycles, msg) \
  begin \
    int __i; \
    bit __seen; \
    __seen = 0; \
    for (__i = 0; __i < cycles; __i++) begin \
      @(posedge clk); \
      if (expr) begin \
        $display("PASS at %0t: %s", $time, msg); \
        __seen = 1; \
        break; \
      end \
    end \
    if (!__seen) begin \
      $display("FAIL at %0t: timeout waiting for %s", $time, msg); \
      $stop(); \
    end \
  end


  task automatic fail(input string msg);
    begin
      $display("FAIL at %0t: %s", $time, msg);
      $stop();
    end
  endtask

  task automatic pass(input string msg);
    begin
      $display("PASS at %0t: %s", $time, msg);
    end
  endtask

  task automatic wait_expr_frwrd_spd(input [10:0] target, input int cycles);
    int i;
    begin
      for (i = 0; i < cycles; i++) begin
        @(posedge clk);
        if (iDUT.frwrd_spd >= target) begin
          pass("forward speed reached target");
          return;
        end
      end
      fail("timeout waiting for forward speed");
    end
  endtask

task automatic send_and_expect_ack(input [15:0] c, input string name);
  begin
    $display("Sending %s cmd=%h at %0t", name, c, $time);

    cmd = c;
    repeat (2) @(negedge clk);

    send_cmd = 1'b1;
    repeat (5) @(posedge clk);
    send_cmd = 1'b0;

    `WAIT_EXPR(resp_rdy, 3000000, {name, " resp_rdy"})

    if (resp !== 8'hA5)
      fail({name, " expected resp 0xA5"});
    else
      pass({name, " response 0xA5"});

    repeat (20) @(posedge clk);
  end
endtask

  initial begin
    $display("Starting MazeRunner self-checking TB");

    $monitor("t=%0t actl=%h dsrd=%h adj=%h at_hdng=%b moving=%b lft=%h rght=%h mv_cmplt=%b",
         $time, iDUT.actl_hdng, iDUT.dsrd_hdng, iDUT.dsrd_hdng_adj,
         iDUT.at_hdng, iDUT.moving, iDUT.lft_spd, iDUT.rght_spd, iDUT.mv_cmplt);
    clk = 0;
    RST_n = 0;
    send_cmd = 0;
    cmd = 16'h0000;
    batt = 12'hD80;

    repeat (5) @(negedge clk);
    RST_n = 1;
    repeat (20) @(posedge clk);

    if (lftPWM1 !== 0 || lftPWM2 !== 0 || rghtPWM1 !== 0 || rghtPWM2 !== 0)
      fail("motors should be stopped after reset");
    else
      pass("reset motor outputs low");

    repeat (10000) @(posedge clk);

    fork
      begin
        `WAIT_EXPR(iDUT.strt_hdng, 1000000, "strt_hdng during heading command")
      end
      begin
        send_and_expect_ack(16'h27FF, "heading command");
      end
    join

    `WAIT_EXPR((iDUT.actl_hdng >= 12'h7D0 && iDUT.actl_hdng <= 12'h830),
              30000000,
              "actl_hdng reached 7FF target")

    force iDUT.frwrd_opn = 1'b1;
    send_and_expect_ack(16'h4000, "forward move command");
    wait_expr_frwrd_spd(11'h2A0, 1000000);

    repeat (50000) @(posedge clk);

    force iDUT.frwrd_opn = 1'b0;
    `WAIT_EXPR(iDUT.mv_cmplt, 3000000, "mv_cmplt after obstacle")
    force iDUT.frwrd_opn = 1'b1;

    repeat (1000) @(posedge clk);

    pass("ALL TESTS PASSED");
    $stop();
  end

endmodule