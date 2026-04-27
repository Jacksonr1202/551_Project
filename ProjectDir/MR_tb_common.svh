// MR_tb_common.svh
// Common full-system MazeRunner testbench wiring/tasks.
// Include this file inside one test module after declaring:
// reg clk, RST_n, send_cmd; reg [15:0] cmd; reg [11:0] batt;
// logic cmd_sent, resp_rdy; logic [7:0] resp; logic hall_n;
// wire TX_RX,RX_TX; wire INRT_SS_n,INRT_SCLK,INRT_MOSI,INRT_MISO,INRT_INT;
// wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
// wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;
// wire IR_lft_en,IR_cntr_en,IR_rght_en;
// wire piezo,piezo_n; wire [7:0] LED;

localparam POS_ACK      = 8'hA5;
localparam CMD_CAL      = 16'h0000;
localparam CMD_WEST     = 16'h23FF;
localparam CMD_EAST     = 16'h2C00;
localparam CMD_MOVE     = 16'h4000;

localparam UART_TIMEOUT = 2500000;
localparam CAL_TIMEOUT  = 3500000;
localparam TURN_TIMEOUT = 5000000;
localparam MOVE_TIMEOUT = 1000000;

MazeRunner iDUT(.clk(clk),.RST_n(RST_n),
  .INRT_SS_n(INRT_SS_n),.INRT_SCLK(INRT_SCLK),.INRT_MOSI(INRT_MOSI),
  .INRT_MISO(INRT_MISO),.INRT_INT(INRT_INT),
  .A2D_SS_n(A2D_SS_n),.A2D_SCLK(A2D_SCLK),.A2D_MOSI(A2D_MOSI),
  .A2D_MISO(A2D_MISO),
  .lftPWM1(lftPWM1),.lftPWM2(lftPWM2),.rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),
  .RX(RX_TX),.TX(TX_RX),.hall_n(hall_n),
  .piezo(piezo),.piezo_n(piezo_n),
  .IR_lft_en(IR_lft_en),.IR_cntr_en(IR_cntr_en),.IR_rght_en(IR_rght_en),
  .LED(LED));

RemoteComm iCMD(.clk(clk),.rst_n(RST_n),.RX(TX_RX),.TX(RX_TX),
  .cmd(cmd),.snd_cmd(send_cmd),.cmd_snt(cmd_sent),
  .resp_rdy(resp_rdy),.resp(resp));

RunnerPhysics iPHYS(.clk(clk),.RST_n(RST_n),
  .SS_n(INRT_SS_n),.SCLK(INRT_SCLK),.MISO(INRT_MISO),.MOSI(INRT_MOSI),.INT(INRT_INT),
  .lftPWM1(lftPWM1),.lftPWM2(lftPWM2),.rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),
  .IR_lft_en(IR_lft_en),.IR_cntr_en(IR_cntr_en),.IR_rght_en(IR_rght_en),
  .A2D_SS_n(A2D_SS_n),.A2D_SCLK(A2D_SCLK),.A2D_MOSI(A2D_MOSI),.A2D_MISO(A2D_MISO),
  .hall_n(hall_n),.batt(batt));

always #5 clk = ~clk;

task fail;
  input [1023:0] msg;
  begin
    $display("");
    $display("ERR at %0t: %0s",$time,msg);
    $display("  cmd=%h resp=%h resp_rdy=%b cmd_sent=%b",cmd,resp,resp_rdy,cmd_sent);
    $display("  PWM L=%b%b R=%b%b",lftPWM1,lftPWM2,rghtPWM1,rghtPWM2);
    $display("  omega_lft=%0d omega_rght=%0d omega_sum=%0d heading=%h",
      iPHYS.omega_lft,iPHYS.omega_rght,iPHYS.omega_sum,iPHYS.heading_robot[19:8]);
    $stop();
  end
endtask

task check;
  input condition;
  input [1023:0] good_msg;
  input [1023:0] bad_msg;
  begin
    if (condition) $display("GOOD: %0s",good_msg);
    else fail(bad_msg);
  end
endtask

task wait_cycles;
  input integer num;
  begin
    repeat(num) @(posedge clk);
  end
endtask

task init;
  begin
    clk = 0;
    RST_n = 0;
    send_cmd = 0;
    cmd = 16'h0000;
    batt = 12'hD80;
    hall_n = 1'b1;
    wait_cycles(10);
    @(negedge clk);
    RST_n = 1;
    wait_cycles(20);
    check({lftPWM1,lftPWM2,rghtPWM1,rghtPWM2}===4'b0000,
          "motors stopped after reset",
          "motors not stopped after reset");
  end
endtask

task wait_until;
  input condition;
  input integer timeout;
  input [1023:0] msg;
  integer i;
  begin
    i = 0;
    while ((i < timeout) && !condition) begin
      @(posedge clk);
      i = i + 1;
    end
    if (!condition)
      fail(msg);
  end
endtask

task send_cmd_task;
  input [15:0] command;
  input [1023:0] name;
  begin
    @(negedge clk);
    cmd = command;
    send_cmd = 1'b1;
    @(negedge clk);
    send_cmd = 1'b0;
    wait_until(cmd_sent,UART_TIMEOUT,{"timeout waiting for RemoteComm to send ",name});
    $display("GOOD: command sent: %0s",name);
  end
endtask

task wait_ack;
  input integer timeout;
  input [1023:0] name;
  begin
    wait_until(resp_rdy,timeout,{"timeout waiting for ACK on ",name});
    check(resp===POS_ACK,{"ACK received for ",name},{"bad ACK byte for ",name});
    wait_cycles(10);
  end
endtask

task boot_and_calibrate;
  begin
    init();
    wait_cycles(20000);
    send_cmd_task(CMD_CAL,"calibrate");
    wait_until(LED[0]===1'b1,CAL_TIMEOUT/4,"in_cal/LED[0] never asserted during calibration");
    wait_ack(CAL_TIMEOUT,"calibrate");
  end
endtask
