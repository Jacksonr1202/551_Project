module PWM12_tb();

//declare registers
reg clk;
reg rst_n;
reg [11:0] duty;
reg PWM1;
reg PWM2;

//instantiate PWM12
PWM12 iDUT(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM1(PWM1), .PWM2(PWM2));

initial begin
clk = 0;
rst_n = 0; //reset system
duty = 12'h7FF; //set duty to 50%
repeat(10)@(posedge clk); //wait ten clk cycles
rst_n = 1;
@(posedge clk); //wait one clk cycle

if(PWM1 == 1'b0 && PWM2 == 1'b0)
    $display("First test passed");
else begin
    $display("First test failed");
    $stop();
end


repeat(8192)@(posedge clk); //wait 2 cycles
$stop();

end

//clk logic
always
    #5 clk = ~clk;


endmodule