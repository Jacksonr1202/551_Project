`timescale 1ns/1ps

module MR_heading_east_tb();

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
  $display("=== MazeRunner east heading test ===");
  boot_and_calibrate();

  send_cmd_task(CMD_EAST,"heading east");

  wait_until((iPHYS.omega_lft > 16'sd150) && (iPHYS.omega_rght < -16'sd150),
             MOVE_TIMEOUT,
             "east heading did not create expected wheel polarity");

  check(iPHYS.heading_v < 16'sd0,
        "east heading velocity went negative",
        "east heading_v did not go negative");

  wait_ack(TURN_TIMEOUT,"heading east");

  wait_until((iPHYS.heading_robot[19:8] > 12'hB00) &&
             (iPHYS.heading_robot[19:8] < 12'hCD0),
             MOVE_TIMEOUT,
             "robot did not settle near east");
  $display("Yahoo!!! MazeRunner east heading test passed");
  $stop();
end

endmodule
