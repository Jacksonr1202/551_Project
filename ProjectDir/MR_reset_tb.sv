`timescale 1ns/1ps

module MR_reset_tb();

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
  $display("=== MazeRunner reset test ===");
  init();
  wait_cycles(20000);

  check(!$isunknown({INRT_SS_n,INRT_SCLK,INRT_MOSI,
                     A2D_SS_n,A2D_SCLK,A2D_MOSI,
                     lftPWM1,lftPWM2,rghtPWM1,rghtPWM2,
                     IR_lft_en,IR_cntr_en,IR_rght_en,piezo,piezo_n,LED}),
        "top-level outputs known after reset and boot",
        "unknown X/Z on top-level outputs after reset and boot");
  $display("Yahoo!!! MazeRunner reset test passed");
  $stop();
end

endmodule
