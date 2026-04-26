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
logic [12:0] scale_factor_r;
logic [11:0] lft_spd_r;
logic [11:0] rght_spd_r;
logic [23:0] lft_prod_nxt;
logic [23:0] rght_prod_nxt;
logic [23:0] lft_prod_r;
logic [23:0] rght_prod_r;
logic [23:0] lft_prod;
logic [23:0] rght_prod;
logic [11:0] lft_scaled;
logic [11:0] rght_scaled;
logic [11:0] lft_scaled_r;
logic [11:0] rght_scaled_r;
logic [11:0] lft_final;
logic [11:0] rght_final;
logic [11:0] lft_final_r;
logic [11:0] rght_final_r;

DutyScaleROM scaleROM(.clk(clk),.batt_level(vbatt[9:4]),.scale(scale_factor));
PWM12 lPWM(.clk(clk),.rst_n(rst_n),.duty(lft_final_r),.PWM1(lftPWM1),.PWM2(lftPWM2));
PWM12 rPWM(.clk(clk),.rst_n(rst_n),.duty(rght_final_r),.PWM1(rghtPWM1),.PWM2(rghtPWM2));


//scale speed then divide by 2048 and saturate to 12 bits
assign lft_prod_nxt = lft_spd_r * scale_factor_r;
assign rght_prod_nxt = rght_spd_r * scale_factor_r;
assign lft_prod = lft_prod_r;
assign rght_prod = rght_prod_r;

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

// Pipeline cut #0: register inputs to the multiplier stage.
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lft_spd_r <= 12'h000;
        rght_spd_r <= 12'h000;
        scale_factor_r <= 13'h0000;
    end else begin
        lft_spd_r <= lft_spd;
        rght_spd_r <= rght_spd;
        scale_factor_r <= scale_factor;
    end
end

// Pipeline cut #0.5: register multiplier outputs before saturation logic.
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lft_prod_r <= 24'h000000;
        rght_prod_r <= 24'h000000;
    end else begin
        lft_prod_r <= lft_prod_nxt;
        rght_prod_r <= rght_prod_nxt;
    end
end

// Pipeline cut #1: register post-saturation values from multiplier stage.
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lft_scaled_r <= 12'h000;
        rght_scaled_r <= 12'h000;
    end else begin
        lft_scaled_r <= lft_scaled;
        rght_scaled_r <= rght_scaled;
    end
end

// Build final motor duty from registered values.
always_comb begin
    lft_final_r = lft_scaled_r + 12'h800;
    rght_final_r = 12'h800 - rght_scaled_r;
end


endmodule