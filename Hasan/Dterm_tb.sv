module Dterm_tb();
//declare variables
reg clk, rst_n;
reg hdng_vld;
reg [9:0] err_sat;
reg [12:0] D_term;

//instantiate Dterm
Dterm iDUT(.clk(clk), .rst_n(rst_n), .hdng_vld(hdng_vld), .err_sat(err_sat), .D_term(D_term));

initial begin
    //set up simulation
    clk = 0;
    rst_n = 0;
    err_sat = 10'h001;
    hdng_vld = 1;
    @(negedge clk) rst_n = 1;
    repeat(10)@(posedge clk);
    //D_term should be zero since no change in err
    if(D_term == 12'h000)
	$display("First test passed");
    else begin
	$display("First test failed");
	$stop;
    end

    err_sat = 10'h002;
    repeat(2)@(posedge clk);
    //check if properly finding dterm
    if(D_term == 12'h00E)
	$display("Second test passed");
    else begin
	$display("Second test failed");
	$stop;
    end
    
    repeat(10)@(posedge clk);
    hdng_vld = 0;
    repeat(2)@(posedge clk);
    err_sat = 10'h001;
    //check for corrent invalid hdng logic
    if(D_term == 12'h000)
	$display("Third test passed");
    else begin
	$display("Third test failed");
	$stop;
    end
    hdng_vld = 1;

    repeat(10)@(posedge clk);
    err_sat = 10'h111;
    repeat(2)@(posedge clk);
    //check for corrent saturation
    if(D_term == (12'h07F*5'h0E))
	$display("Fourth test passed");
    else begin
	$display("Fourth test failed");
	$stop;
    end

    $stop;
end

always begin
    #5;
    clk = ~clk;
end

endmodule
