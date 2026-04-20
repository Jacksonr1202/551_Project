module lshift_rot(src, rot, amt, res);
//declare input and output
input [15:0] src;
input rot;
input [3:0] amt;
output [15:0] res;

//declare internal variables
logic [15:0] r1, r2, r3, r4;

//if amt[3] is 1 then shift by 8
always_comb begin
    if(amt[3]) begin
	if(rot)
	    r1 = {src[7:0], src[15:8]};
	else
	    r1 = {src[7:0], 8'b0};
    end else 
	r1 = src;
end

//if amt[2] is 1 then shift by 4
always_comb begin
    if(amt[2]) begin
	if(rot)
	    r2 = {r1[11:0], r1[15:12]};
	else
	    r2 = {r1[11:0], 4'b0};
    end else 
	r2 = r1;
end

//if amt[1] is 1 then shift by 2
always_comb begin
    if(amt[1]) begin
	if(rot)
	    r3 = {r2[13:0], r2[15:14]};
	else
	    r3 = {r2[13:0], 2'b0};
    end else 
	r3 = r2;
end

//if amt[0] is 1 then shift by 1
always_comb begin
    if(amt[0]) begin
	if(rot)
	    r4 = {r3[14:0], r3[15]};
	else
	    r4 = {r3[14:0], 1'b0};
    end else 
	r4 = r3;
end

//set res to the combined shifts
assign res = r4;

endmodule
