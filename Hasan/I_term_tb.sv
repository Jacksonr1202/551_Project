module I_term_tb();
//variables
reg clk;
reg rst_n;
reg moving;
reg hdng_vld;
reg [9:0] err_sat;
wire [11:0] I_term;

//instantiate iDUT
I_term iDUT(.clk(clk), .rst_n(rst_n), .moving(moving), .hdng_vld(hdng_vld), .err_sat(err_sat), .I_term(I_term));

//set up tests
initial begin
    clk = 0;
    rst_n = 0;
    moving = 1;
    hdng_vld = 1;
    err_sat = 10'h001;
    @(negedge clk);
    rst_n = 1;

    repeat(10)@(posedge clk);

    //test behavior
    @(negedge clk);
    hdng_vld = 0;
    if(I_term == 12'h00A)
	$display("First test passed");
    else begin
	$display("First test failed");
	$stop;
    end
    

    hdng_vld = 1;
    moving = 0;
    repeat(10)@(posedge clk);
    if(I_term == 12'h000)
	$display("Second test passed");
    else begin
	$display("Second test failed");
	$stop;
    end

    moving = 1;
    err_sat = 10'h3FF;
    repeat(10)@(posedge clk);
    if(I_term !== 12'h3FF)
	$display("Third test passed");
    else begin
	$display("Third test failed");
	$stop;
    end

    $stop();

end

//clk logic
always
    #5 clk = ~clk;


endmodule
