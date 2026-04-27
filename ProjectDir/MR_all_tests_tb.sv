`timescale 1ns/1ps
`include "MR_tb_common.svh"

module MR_all_tests_tb;

  localparam int BOOT_CYCLES = 20000;

  reg clk, RST_n;
  reg send_cmd;
  reg [15:0] cmd;
  reg [11:0] batt;

  logic cmd_sent, resp_rdy;
  logic [7:0] resp;
  logic hall_n;

  wire TX_RX, RX_TX;
  wire INRT_SS_n, INRT_SCLK, INRT_MOSI, INRT_MISO, INRT_INT;
  wire lftPWM1, lftPWM2, rghtPWM1, rghtPWM2;
  wire A2D_SS_n, A2D_SCLK, A2D_MOSI, A2D_MISO;
  wire IR_lft_en, IR_cntr_en, IR_rght_en;
  wire piezo, piezo_n;
  wire [7:0] LED;

  // DUT
  MazeRunner iDUT(
    .clk(clk), .RST_n(RST_n),
    .INRT_SS_n(INRT_SS_n), .INRT_SCLK(INRT_SCLK), .INRT_MOSI(INRT_MOSI),
    .INRT_MISO(INRT_MISO), .INRT_INT(INRT_INT),
    .A2D_SS_n(A2D_SS_n), .A2D_SCLK(A2D_SCLK), .A2D_MOSI(A2D_MOSI),
    .A2D_MISO(A2D_MISO),
    .lftPWM1(lftPWM1), .lftPWM2(lftPWM2),
    .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
    .RX(RX_TX), .TX(TX_RX), .hall_n(hall_n),
    .piezo(piezo), .piezo_n(piezo_n),
    .IR_lft_en(IR_lft_en), .IR_cntr_en(IR_cntr_en), .IR_rght_en(IR_rght_en),
    .LED(LED)
  );

  RemoteComm iCMD(
    .clk(clk), .rst_n(RST_n),
    .RX(TX_RX), .TX(RX_TX),
    .cmd(cmd), .snd_cmd(send_cmd), .cmd_snt(cmd_sent),
    .resp_rdy(resp_rdy), .resp(resp)
  );

  RunnerPhysics iPHYS(
    .clk(clk), .RST_n(RST_n),
    .SS_n(INRT_SS_n), .SCLK(INRT_SCLK),
    .MISO(INRT_MISO), .MOSI(INRT_MOSI), .INT(INRT_INT),
    .lftPWM1(lftPWM1), .lftPWM2(lftPWM2),
    .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
    .IR_lft_en(IR_lft_en), .IR_cntr_en(IR_cntr_en), .IR_rght_en(IR_rght_en),
    .A2D_SS_n(A2D_SS_n), .A2D_SCLK(A2D_SCLK),
    .A2D_MOSI(A2D_MOSI), .A2D_MISO(A2D_MISO),
    .hall_n(hall_n), .batt(batt)
  );

  // clock
  always #5 clk = ~clk;

  // reuse shared tasks
  `include "MR_tb_common_tasks.svh"

  initial begin
    $display("\n=== RUNNING FULL TEST SUITE ===");

    // reset
    reset_dut();

    // let models settle (important per project PDF)
    wait_n(BOOT_CYCLES);

    // run all tests in order
    test_calibration();
    test_turn_west();
    test_turn_east();
    test_move_forward_abbreviated();

    $display("\n=== ALL TESTS PASSED ===");
    $stop;
  end
endmodule
