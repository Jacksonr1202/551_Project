`timescale 1ns/1ps

module MR_calibrate_tb();

reg clk,RST_n;
reg send_cmd;
reg [15:0] cmd;
reg [11:0] batt;

logic cmd_sent;
logic resp_rdy;
logic [7:0] resp;
logic hall_n;

wire TX_RX,RX_TX;
wire INRT_SS_n,INRT_SCLK,INRT_MOSI,INRT_MISO,INRT_INT;
wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;
wire IR_lft_en,IR_cntr_en,IR_rght_en;
wire piezo,piezo_n;
wire [7:0] LED;

`include "MR_tb_common.svh"

initial begin
  $display("");
  $display("=== MazeRunner calibration test ===");
  init();
  wait_cycles(20000);

  send_cmd_task(CMD_CAL,"calibrate");
  wait_until(LED[0]===1'b1,CAL_TIMEOUT/4,"in_cal/LED[0] never asserted");
  wait_ack(CAL_TIMEOUT,"calibrate");

  check(!$isunknown({lftPWM1,lftPWM2,rghtPWM1,rghtPWM2,TX_RX}),
        "outputs still known after calibration",
        "X/Z output after calibration");
  $display("Yahoo!!! MazeRunner calibration test passed");
  $stop();
end

endmodule
