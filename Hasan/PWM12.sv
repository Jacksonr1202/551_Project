module PWM12(clk, rst_n, duty, PWM1, PWM2);

// declare inputs and outputs
input clk;
input rst_n;
input [11:0] duty;
output reg PWM1;
output reg PWM2;

localparam NONOVERLAP = 12'h02C;
localparam MAX_CNT    = 12'hFFF;

// declare internal variables
reg [11:0] cnt;
wire [12:0] duty_plus_nonoverlap;

// use 13 bits so overflow is visible
assign duty_plus_nonoverlap = {1'b0, duty} + {1'b0, NONOVERLAP};

// counter
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        cnt <= 12'h000;
    else if (cnt == MAX_CNT)
        cnt <= 12'h000;
    else
        cnt <= cnt + 1'b1;
end

// PWM1: high from NONOVERLAP to duty
// if duty <= NONOVERLAP, PWM1 should stay low
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        PWM1 <= 1'b0;
    else if (cnt == duty)
        PWM1 <= 1'b0;   // reset gets priority
    else if ((cnt == NONOVERLAP) && (duty > NONOVERLAP))
        PWM1 <= 1'b1;
end

// PWM2: high from duty+NONOVERLAP to end of count
// if duty+NONOVERLAP overflows, PWM2 should stay low for that cycle
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        PWM2 <= 1'b0;
    else if (&cnt)
        PWM2 <= 1'b0;   // turn off at end of cycle
    else if ((!duty_plus_nonoverlap[12]) && (cnt == duty_plus_nonoverlap[11:0]) && (duty_plus_nonoverlap[11:0] != 12'hFFF))
        PWM2 <= 1'b1;
end

endmodule