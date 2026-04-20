module PID_tb;

  localparam int NUM_VECTORS = 2000;

  logic clk;
  logic rst_n;
  logic moving;
  logic [11:0] dsrd_hdng;
  logic [11:0] actl_hdng;
  logic hdng_vld;
  logic [10:0] frwrd_spd;
  logic at_hdng;
  logic [11:0] lft_spd;
  logic [11:0] rght_spd;
  logic [37:0] stim_mem [0:NUM_VECTORS-1];
  logic [24:0] resp_mem [0:NUM_VECTORS-1];
  logic [24:0] dut_resp;

  integer i;
  integer errors;

  //instantiate dut
  PID iDUT (
    .clk(clk), .rst_n(rst_n), .moving(moving), .dsrd_hdng(dsrd_hdng), .actl_hdng(actl_hdng),
    .hdng_vld(hdng_vld), .frwrd_spd(frwrd_spd), .at_hdng(at_hdng), .lft_spd(lft_spd), .rght_spd(rght_spd)
  );


  always begin
    #5 clk = ~clk;
  end


  initial begin
    clk = 1'b0;
    errors = 0;

    //default inputs
    rst_n = 1'b0;
    moving = 1'b0;
    hdng_vld = 1'b0;
    dsrd_hdng = 12'h000;
    actl_hdng = 12'h000;
    frwrd_spd = 11'h000;

    //load files
    $readmemh("PID_stim.hex", stim_mem);
    $readmemh("PID_resp.hex", resp_mem);

    //go through all vectors
    for (i = 0; i < NUM_VECTORS; i = i + 1) begin
      //start when clk low
      if (i == 0)
        wait (clk == 1'b0);
      else
        @(negedge clk);

      //load data
      {rst_n, moving, hdng_vld, dsrd_hdng, actl_hdng, frwrd_spd} = stim_mem[i];


      @(posedge clk);
      #1;

      //load response
      dut_resp = {at_hdng, lft_spd, rght_spd};

      //check response
      if (dut_resp !== resp_mem[i]) begin
        errors = errors + 1;
        $display("ERROR vector %0d expected %h got %h", i, resp_mem[i], dut_resp);
      end
    end

    if (errors == 0)
      $display("SUCCESS. Hasan Ali");
    else
      $display("FAIL: %0d mismatches found", errors);

    $stop();
  end

endmodule
