module MtrDrv_tb;

//logic signals
  logic        clk;
  logic        rst_n;
  logic [11:0] lft_spd;
  logic [11:0] rght_spd;
  logic [11:0] vbatt;

  logic lftPWM1, lftPWM2;
  logic rghtPWM1, rghtPWM2;

//instatiate dut
  MtrDrv dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .lft_spd  (lft_spd),
    .rght_spd (rght_spd),
    .vbatt    (vbatt),
    .lftPWM1  (lftPWM1),
    .lftPWM2  (lftPWM2),
    .rghtPWM1 (rghtPWM1),
    .rghtPWM2 (rghtPWM2)
  );

//clock gen

  always #10 clk = ~clk;

//measured duty
  integer hi_lftPWM1, hi_lftPWM2, hi_rghtPWM1, hi_rghtPWM2;
  integer i;

  task automatic measure_one_frame;
    begin
      hi_lftPWM1  = 0;
      hi_lftPWM2  = 0;
      hi_rghtPWM1 = 0;
      hi_rghtPWM2 = 0;

      // Measure over one full 12-bit PWM period = 4096 clocks
      for (i = 0; i < 4096; i = i + 1) begin
        @(posedge clk);
        if (lftPWM1)  hi_lftPWM1  = hi_lftPWM1  + 1;
        if (lftPWM2)  hi_lftPWM2  = hi_lftPWM2  + 1;
        if (rghtPWM1) hi_rghtPWM1 = hi_rghtPWM1 + 1;
        if (rghtPWM2) hi_rghtPWM2 = hi_rghtPWM2 + 1;
      end
    end
  endtask

  task automatic print_result(input string label);
    real p1, p2, p3, p4;
    begin
      p1 = 100.0 * hi_lftPWM1  / 4096.0;
      p2 = 100.0 * hi_lftPWM2  / 4096.0;
      p3 = 100.0 * hi_rghtPWM1 / 4096.0;
      p4 = 100.0 * hi_rghtPWM2 / 4096.0;

      $display("------------------------------------------------------------");
      $display("%s", label);
      $display("time=%0t  vbatt=%h  lft_spd=%h  rght_spd=%h",
               $time, vbatt, lft_spd, rght_spd);
      $display("  LEFT : PWM1 high = %0d / 4096  (%0.2f%%), PWM2 high = %0d / 4096  (%0.2f%%)",
               hi_lftPWM1, p1, hi_lftPWM2, p2);
      $display("  RIGHT: PWM1 high = %0d / 4096  (%0.2f%%), PWM2 high = %0d / 4096  (%0.2f%%)",
               hi_rghtPWM1, p3, hi_rghtPWM2, p4);
    end
  endtask

  //============================================================
  // Test sequence
  //============================================================
  initial begin
    // init
    clk      = 1'b0;
    rst_n    = 1'b0;
    lft_spd  = 12'h000;
    rght_spd = 12'h000;
    vbatt    = 12'hDB0;   // upper 8 bits = DB by default

    // reset
    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    // let counters / PWM settle
    repeat (20) @(posedge clk);

    //zero in 50% duty 
    vbatt    = 12'hDB0;
    lft_spd  = 12'h000;
    rght_spd = 12'h000;
    repeat (20) @(posedge clk);
    measure_one_frame();
    print_result("TEST 1: zero input, expect approx 50/50 on both motors");


    // lft_spd = 0x3FF, vbatt[11:4] = 0xDB, 75% on PWM1, 25% on PWM2
    vbatt    = 12'hDB0;
    lft_spd  = 12'h3FF;
    rght_spd = 12'h000;
    repeat (20) @(posedge clk);
    measure_one_frame();
    print_result("TEST 2: LEFT 0x3FF @ vbatt[11:4]=DB, expect ~75% PWM1 / ~25% PWM2");


    //lft_spd = 0x3FF, vbatt[11:4] = 0xD0, 76.2% on PWM1, 23% on PWM2
    vbatt    = 12'hD00;
    lft_spd  = 12'h3FF;
    rght_spd = 12'h000;
    repeat (20) @(posedge clk);
    measure_one_frame();
    print_result("TEST 3: LEFT 0x3FF @ vbatt[11:4]=D0, expect ~76.2% PWM1 / ~23% PWM2");


    //lft_spd = 0xC00, vbatt[11:4] = 0xFF, 28.5% PWM1 and 71.4% PWM2
    vbatt    = 12'hFF0;
    lft_spd  = 12'hC00;
    rght_spd = 12'h000;
    repeat (20) @(posedge clk);
    measure_one_frame();
    print_result("TEST 4: LEFT 0xC00 @ vbatt[11:4]=FF, expect ~28.5% PWM1 / ~71.4% PWM2");


    $display("Finished MtrDrv_tb");
    $stop;
  end

endmodule