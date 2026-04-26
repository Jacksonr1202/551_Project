module IR_math #(
  parameter logic [11:0] NOM_IR = 12'h900
)(
  input  logic        clk,
  input  logic        rst_n,
  input  logic        lft_opn,
  input  logic        rght_opn,
  input  logic [11:0] lft_IR,
  input  logic [11:0] rght_IR,
  input  logic signed [8:0]  IR_Dtrm,
  input  logic        en_fusion,
  input  logic signed [11:0] dsrd_hdng,
  output logic [11:0] dsrd_hdng_adj
);

  logic signed [12:0] lft13, rght13, nom13;
  logic signed [12:0] diff_full, ir_diff;
  logic signed [12:0] p_term, d_term;

  logic signed [12:0] ir_diff_q, d_term_q;
  logic               en_fusion_q;
  logic signed [11:0] dsrd_hdng_q;

  logic signed [12:0] corr, sum13;
  logic        [11:0] dsrd_hdng_adj_nxt;

  assign lft13  = $signed({1'b0, lft_IR});
  assign rght13 = $signed({1'b0, rght_IR});
  assign nom13  = $signed({1'b0, NOM_IR});

  assign diff_full = lft13 - rght13;

  assign ir_diff =
      ( lft_opn &&  rght_opn) ? 13'sd0 :
      ( lft_opn && !rght_opn) ? (nom13 - rght13) :
      (!lft_opn &&  rght_opn) ? (lft13 - nom13) :
                                (diff_full >>> 1);

  assign p_term = (ir_diff_q >>> 5);
  assign d_term = ($signed({{4{IR_Dtrm[8]}}, IR_Dtrm}) <<< 2);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ir_diff_q   <= 13'sd0;
      d_term_q    <= 13'sd0;
      en_fusion_q <= 1'b0;
      dsrd_hdng_q <= 12'sd0;
    end else begin
      ir_diff_q   <= ir_diff;
      d_term_q    <= d_term;
      en_fusion_q <= en_fusion;
      dsrd_hdng_q <= dsrd_hdng;
    end
  end

  assign corr  = en_fusion_q ? ((p_term + d_term_q) >>> 1) : 13'sd0;
  assign sum13 = $signed({dsrd_hdng_q[11], dsrd_hdng_q}) + corr;

  assign dsrd_hdng_adj_nxt =
      (sum13 >  13'sd2047)  ? 12'h7FF :
      (sum13 < -13'sd2048)  ? 12'h800 :
                              sum13[11:0];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      dsrd_hdng_adj <= 12'h000;
    else
      dsrd_hdng_adj <= dsrd_hdng_adj_nxt;
  end

endmodule
