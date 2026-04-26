module I_term(clk, rst_n, hdng_vld, moving, err_sat, I_term);
//declare inputs and outputs
input clk, rst_n;
input hdng_vld;
input moving;
input logic signed [9:0] err_sat;
output logic signed [11:0] I_term;

//declare internal variables
logic signed [9:0]  err_sat_q;     // pipelined to break path through PID's 12b sub + saturation
logic               hdng_vld_q;
logic               moving_q;
logic signed [15:0] err_ext;
logic signed [15:0] integrator;
logic signed [15:0] sum;
logic signed [15:0] mux1out;
logic mux1sel;
logic signed [15:0] nxt_integrator;
logic ov;

// Register the inputs once. Keeps integration gating (hdng_vld, moving) aligned with the err_sat sample they belong to.
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        err_sat_q  <= 10'sd0;
        hdng_vld_q <= 1'b0;
        moving_q   <= 1'b0;
    end else begin
        err_sat_q  <= err_sat;
        hdng_vld_q <= hdng_vld;
        moving_q   <= moving;
    end
end

//function logic
assign err_ext = {{6{err_sat_q[9]}}, err_sat_q};
assign sum = integrator + err_ext;

//find if there is overflow
assign ov = (~(err_ext[15] ^ integrator[15]) & (sum[15] ^ integrator[15]));

//add err if no overflow
assign mux1sel = hdng_vld_q & ~ov;
assign mux1out = (mux1sel) ? sum : integrator;
//only correct when moving
assign nxt_integrator = (moving_q) ? mux1out : 16'h0000;

//flip flop to assign integrator
always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
	integrator <= 16'h0000;
    else 
	integrator <= nxt_integrator;
end

assign I_term = integrator[15:4];

endmodule
