module P_term_tb();

//declare variables
logic [11:0] error;
logic [13:0] P_term;

//instantiate method
P_term iDUT(.error(error), .P_term(P_term));


initial begin
    error = 12'd255;
    #10;
    if(P_term != (12'd765)) begin
	$display("First test failed");
	$stop();
    end else
	  $display("First test passed");

    error = 12'b101111000000;
    #10;
    if(P_term != (12'h200 * 4'h3)) begin
	$display("Second test failed");
	$stop();
    end else
	  $display("Second test passed");

    error = 12'b011010000111;
    #10;
    if(P_term != (12'h1FF * 4'h3)) begin
	$display("Third test failed");
	$stop();
    end else
	  $display("Third test passed");

    $stop();
end

endmodule