module navigate(clk,rst_n,strt_hdng,strt_mv,stp_lft,stp_rght,mv_cmplt,hdng_rdy,moving,
                en_fusion,at_hdng,lft_opn,rght_opn,frwrd_opn,frwrd_spd);

  parameter FAST_SIM = 1;

  input clk,rst_n;
  input strt_hdng;
  input strt_mv;
  input stp_lft;
  input stp_rght;
  input hdng_rdy;
  output logic mv_cmplt;
  output logic moving;
  output en_fusion;
  input at_hdng;
  input logic lft_opn,rght_opn,frwrd_opn;
  output reg [10:0] frwrd_spd;

  logic inc_frwrd;
  logic [5:0] frwrd_inc;
  logic init_frwrd;
  logic dec_frwrd;
  logic dec_frwrd_fast;

  logic lft_opn_d, rght_opn_d;
  logic lft_rise, rght_rise;

  logic [3:0] hdng_wait_cnt;
  logic hdng_wait_done;

  localparam MAX_FRWRD = 11'h2A0;
  localparam MIN_FRWRD = 11'h0D0;

  assign frwrd_inc = (FAST_SIM) ? 6'h18 : 6'h02;

  typedef enum logic [2:0] {IDLE, HDNG_INIT, HDNG, MOVE_INIT, MOVE, MV_STOP, MV_STOP_FAST} state_t;
  state_t state, nxt_state;

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      frwrd_spd <= 11'h000;
    else if (init_frwrd)
      frwrd_spd <= MIN_FRWRD;
    else if (hdng_rdy && inc_frwrd && (frwrd_spd < MAX_FRWRD))
      frwrd_spd <= frwrd_spd + {5'h00, frwrd_inc};
    else if (hdng_rdy && (frwrd_spd > 11'h000) && (dec_frwrd | dec_frwrd_fast))
      frwrd_spd <= ((dec_frwrd_fast) && (frwrd_spd > {2'h0, frwrd_inc, 3'b000})) ? frwrd_spd - {2'h0, frwrd_inc, 3'b000} :
                   (dec_frwrd_fast) ? 11'h000 :
                   (frwrd_spd > {4'h0, frwrd_inc, 1'b0}) ? frwrd_spd - {4'h0, frwrd_inc, 1'b0} :
                   11'h000;
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      hdng_wait_cnt <= 4'h0;
    else if (state == HDNG_INIT)
      hdng_wait_cnt <= 4'h0;
    else if (state == HDNG && !hdng_wait_done)
      hdng_wait_cnt <= hdng_wait_cnt + 1'b1;
  end

  assign hdng_wait_done = (hdng_wait_cnt >= 4'h8);

  always_comb begin
    nxt_state = state;
    moving = 0;
    mv_cmplt = 0;
    init_frwrd = 0;
    inc_frwrd = 0;
    dec_frwrd = 0;
    dec_frwrd_fast = 0;

    case(state)
      IDLE: begin
        if (strt_hdng) begin
          nxt_state = HDNG_INIT;
        end else if (strt_mv) begin
          nxt_state = MOVE_INIT;
          init_frwrd = 1;
        end
      end

      HDNG_INIT: begin
        moving = 1;
        nxt_state = HDNG;
      end

      HDNG: begin
        moving = 1;
        if (hdng_wait_done && at_hdng) begin
          mv_cmplt = 1;
          nxt_state = IDLE;
        end
      end

      MOVE_INIT: begin
        moving = 1;
        inc_frwrd = 1;
        nxt_state = MOVE;
      end

      MOVE: begin
        moving = 1;
        inc_frwrd = 1;
        if (~frwrd_opn) begin
          nxt_state = MV_STOP_FAST;
        end else if (stp_lft && lft_rise) begin
          nxt_state = MV_STOP;
        end else if (stp_rght && rght_rise) begin
          nxt_state = MV_STOP;
        end
      end

      MV_STOP_FAST: begin
        dec_frwrd_fast = 1;
        moving = 1;
        if (frwrd_spd == 0) begin
          mv_cmplt = 1;
          nxt_state = IDLE;
        end
      end

      MV_STOP: begin
        dec_frwrd = 1;
        moving = 1;
        if (frwrd_spd == 0) begin
          mv_cmplt = 1;
          nxt_state = IDLE;
        end
      end

      default: begin
        nxt_state = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      lft_opn_d <= 0;
      rght_opn_d <= 0;
    end else begin
      lft_opn_d <= lft_opn;
      rght_opn_d <= rght_opn;
    end
  end

  assign lft_rise  = lft_opn  & ~lft_opn_d;
  assign rght_rise = rght_opn & ~rght_opn_d;

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  assign en_fusion = (frwrd_spd > (MAX_FRWRD >> 1)) ? 1'b1 : 1'b0;

endmodule