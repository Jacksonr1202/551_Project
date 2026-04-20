module P_term(error, P_term);
//declare input/output
input [11:0] error;
output [13:0] P_term;

//internal logic
logic [9:0] err_sat;
localparam logic [3:0] P_COEFF = 4'h3;
logic [9:0] mux1out;
logic [9:0] mux2out;
logic [2:0] containsZero;
logic [2:0] containsOne;

//checks to see if saturation is needed
assign containsZero = error[11:9] & 3'b111;
assign containsOne  = error[11:9] | 3'b000;

//chose between saturating and truncating
assign mux1out = ((error[11] == 1'b1) && (error[11:9] != 3'b111)) ? 10'b1000000000 : error[9:0];
assign mux2out  = ((error[11] == 1'b0) && (error[11:9] != 3'b000)) ? 10'b0111111111 : mux1out;

assign err_sat = mux2out;
//signed multiply
assign P_term = (err_sat * P_COEFF);
endmodule