`timescale 1ns/1ps

module MR_move_forward_tb();

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
  $display("=== MazeRunner move forward test ===");
  boot_and_calibrate();

  send_cmd_task(CMD_MOVE,"move forward");

  // The project handout suggests checking that omega_sum ramps up.  Do not
  // require equal wheel speeds here because PID may correct heading while moving.
  wait_until(iPHYS.omega_sum > 17'sd3000,
             MOVE_TIMEOUT,
             "move command did not ramp omega_sum forward");

  check(iPHYS.omega_lft > 16'sd0 && iPHYS.omega_rght > 16'sd0,
        "both wheels have positive velocity during move",
        "one wheel is reversed during move");

  $display("INFO: omega_lft=%0d omega_rght=%0d omega_sum=%0d",
           iPHYS.omega_lft,iPHYS.omega_rght,iPHYS.omega_sum);
  $display("Yahoo!!! MazeRunner move forward test passed");
  $stop();
end

endmodule
