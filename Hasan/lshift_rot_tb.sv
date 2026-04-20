module lshift_rot_tb();
//declare variables
logic [15:0] src;
logic rot;
logic [3:0] amt;
logic [15:0] res;

//instantiate shifter
lshift_rot iDUT(.src(src), .rot(rot), .amt(amt), .res(res));

initial begin
src = 16'hAAAA;
rot = 1'b1;
amt = 4'b0001;
#10;
if(res == 16'h5555)
    $display("First test passed");
else begin
    $display("First test failed");
    $stop;
end
#5;
src = 16'h0001;
amt = 4'b0110;
#10;
if(res == 16'h0040)
    $display("Second test passed");
else begin
    $display("Second test failed");
    $stop;
end
#5;
rot = 1'b0;
src = 16'h8000;
amt = 4'b0010;
#10;
if(res == 16'h0000)
    $display("Third test passed");
else begin
    $display("Third test failed");
    $stop;
end
end

endmodule
