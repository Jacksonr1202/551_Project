module MtrDrv(
    input clk,
    input rst_n,
    input [11:0] rght_spd,
    input [11:0] lft_spd,
    input [11:0] vbatt,
    output lftPWM1,
    output lftPWM2,
    output rghtPWM1,
    output rghtPWM2
);

//internal signals
logic [12:0] scale_factor;
logic [11:0] lft_spd_q, rght_spd_q;          // pipeline stage 1: register inputs from PID
logic [23:0] lft_prod, rght_prod;
logic [23:0] lft_prod_q, rght_prod_q;        // pipeline stage 2: register multiplier outputs
logic [11:0] lft_scaled;
logic [11:0] rght_scaled;
logic [11:0] lft_final;
logic [11:0] rght_final;

DutyScaleROM scaleROM(.clk(clk),.batt_level(vbatt[11:6]),.scale(scale_factor));
PWM12 lPWM(.clk(clk),.rst_n(rst_n),.duty(lft_final),.PWM1(lftPWM1),.PWM2(lftPWM2));
PWM12 rPWM(.clk(clk),.rst_n(rst_n),.duty(rght_final),.PWM1(rghtPWM1),.PWM2(rghtPWM2));

// Stage 1: capture PID outputs so the long PID->MtrDrv combinational chain ends here.
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
        lft_spd_q  <= 12'h000;
        rght_spd_q <= 12'h000;
    end else begin
        lft_spd_q  <= lft_spd;
        rght_spd_q <= rght_spd;
    end

//scale speed then divide by 2048 and saturate to 12 bits
assign lft_prod  = lft_spd_q * scale_factor;
assign rght_prod = rght_spd_q * scale_factor;

// Stage 2: capture the 12x13 multiplier outputs so the saturation/add/PWM logic
// doesn't have to follow the multiplier in one cycle.
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
        lft_prod_q  <= 24'h0;
        rght_prod_q <= 24'h0;
    end else begin
        lft_prod_q  <= lft_prod;
        rght_prod_q <= rght_prod;
    end

assign lft_scaled =
    (lft_prod_q[23:22] == 2'b01) ? 12'h7FF :   // positive overflow
    (lft_prod_q[23:22] == 2'b10) ? 12'h800 :   // negative overflow
    lft_prod_q[22:11];

assign rght_scaled =
    (rght_prod_q[23:22] == 2'b01) ? 12'h7FF :  // positive overflow
    (rght_prod_q[23:22] == 2'b10) ? 12'h800 :  // negative overflow
    rght_prod_q[22:11];

//generate PWM signals
assign lft_final = lft_scaled + 12'h800;
assign rght_final = 12'h800 - rght_scaled;


endmodule