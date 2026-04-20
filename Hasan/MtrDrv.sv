module MtrDrv(
    input clk,
    input rst_n,
    input [11:0] rght_spd,
    input [11:0] lft_spd,
    input [9:0] vbatt,
    output lftPWM1,
    output lftPWM2,
    output rghtPWM1,
    output rghtPWM2
);

//internal signals
logic [12:0] scale_factor;
logic [23:0] lft_prod;
logic [23:0] rght_prod;
logic [11:0] lft_scaled;
logic [11:0] rght_scaled;
logic [11:0] lft_final;
logic [11:0] rght_final;

DutyScaleROM scaleROM(.clk(clk),.batt_level(vbatt[9:4]),.scale(scale_factor));
PWM12 lPWM(.clk(clk),.rst_n(rst_n),.duty(lft_final),.PWM1(lftPWM1),.PWM2(lftPWM2));
PWM12 rPWM(.clk(clk),.rst_n(rst_n),.duty(rght_final),.PWM1(rghtPWM1),.PWM2(rghtPWM2));


//scale speed then divide by 2048 and saturate to 12 bits
assign lft_prod = lft_spd * scale_factor;
assign rght_prod = rght_spd * scale_factor;

assign lft_scaled =
    (lft_prod[23:22] == 2'b01) ? 12'h7FF :   // positive overflow
    (lft_prod[23:22] == 2'b10) ? 12'h800 :   // negative overflow
    lft_prod[22:11];

assign rght_scaled =
    (rght_prod[23:22] == 2'b01) ? 12'h7FF :  // positive overflow
    (rght_prod[23:22] == 2'b10) ? 12'h800 :  // negative overflow
    rght_prod[22:11];

//generate PWM signals
assign lft_final = lft_scaled + 12'h800;
assign rght_final = 12'h800 - rght_scaled;


endmodule