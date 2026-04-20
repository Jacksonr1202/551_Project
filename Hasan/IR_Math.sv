module IR_Math #(parameter logic [11:0] NOM_IR = 12'h900)(lft_opn, rght_opn, lft_IR, rght_IR, IR_Dtrm, en_fusion, dsrd_hdng, dsrd_hdng_adj);

input lft_opn, rght_opn;
input [11:0] lft_IR;
input [11:0] rght_IR;
input [8:0] IR_Dtrm;
input en_fusion;
input [11:0] dsrd_hdng;
output [11:0] dsrd_hdng_adj;

//set up internal variables;
logic signed [12:0] IR_diff;
logic signed [11:0] lft_diff;
logic signed [11:0] rght_diff;
logic signed [11:0] mux1out;
logic signed [11:0] mux2out;
logic signed [11:0] mux3out;
logic signed [11:0] mux4out;
logic lft_and_rght;
logic signed [12:0] mux3_div32;
logic signed [12:0] dtrm_mult4;
logic signed [12:0] sum_mux_dtrm;
logic signed [11:0] sum_dtrm_hdng;


//mux1
assign IR_diff = {1'b0, lft_IR} - {1'b0, rght_IR};
assign lft_diff = (lft_IR - NOM_IR);

assign mux1out = (rght_opn) ? lft_diff : IR_diff[12:1];

//mux2
assign rght_diff = (NOM_IR - rght_IR);
assign mux2out = (lft_opn) ? rght_diff : mux1out;

//mux3
assign lft_and_rght = lft_opn && rght_opn;
assign mux3out = (lft_and_rght) ? 12'h000 : mux2out;

//mux4
assign mux3_div32 = {{6{mux3out[11]}}, mux3out[11:5]};
assign dtrm_mult4 = {{2{IR_Dtrm[8]}}, IR_Dtrm[8:0], 2'b00};
assign sum_mux_dtrm = dtrm_mult4 + mux3_div32;
assign sum_dtrm_hdng = sum_mux_dtrm[12:1] + dsrd_hdng;

//mux5
assign dsrd_hdng_adj = (en_fusion) ? sum_dtrm_hdng : dsrd_hdng;



endmodule
