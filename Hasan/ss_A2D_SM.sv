module ss_A2D_SM(clk,rst_n,strt_cnv,smp_eq_8,gt,clr_dac,inc_dac,
                 clr_smp,inc_smp,accum,cnv_cmplt);

    input clk,rst_n;			// clock and asynch reset
    input strt_cnv;			// asserted to kick off a conversion
    input smp_eq_8;			// from datapath, tells when we have 8 samples
    input gt;					// gt signal, has to be double flopped
  
    output logic clr_dac;			// clear the input counter to the DAC
    output logic inc_dac;			// increment the counter to the DAC
    output logic clr_smp;			// clear the sample counter
    output logic inc_smp;			// increment the sample counter
    output logic accum;				// asserted to make accumulator accumulate sample
    output logic cnv_cmplt;			// indicates when the conversion is complete

    /////////////////////////////////////////////////////////////////
    // You fill in the SM implementation. I want to see the use   //
    // of enumerated type for state, and proper SM coding style. //
    //////////////////////////////////////////////////////////////
    
    //state enum
    typedef enum { IDLE, WAIT_GT, ACCUM, DONE } state_t;
    state_t state, next_state;


    //state logic
    always_comb begin
        // default values for all outputs
        clr_dac   = 0;
        inc_dac   = 0;
        clr_smp   = 0;
        inc_smp   = 0;
        accum     = 0;
        cnv_cmplt = 0;

        case (state)
            IDLE: begin
                if (strt_cnv) begin
                    clr_dac = 1;
                    clr_smp = 1;
                    next_state = WAIT_GT;
                end else begin
                    next_state = IDLE;
                end
            end

            WAIT_GT: begin
                if (gt) begin
                    next_state = ACCUM;
                end else begin
                    inc_dac = 1;
                    next_state = WAIT_GT;
                end
            end

            ACCUM: begin
                accum   = 1; 
                clr_dac = 1;
                inc_smp = 1; 

                if (smp_eq_8) begin
                    next_state = DONE;  
                end else begin
                    next_state = WAIT_GT;
                end
            end

            DONE: begin
                cnv_cmplt = 1; 
                if (!strt_cnv)
                    next_state = IDLE;
                else
                    next_state = DONE;
            end

            default: next_state = IDLE;
        endcase
    end

    //transition to next state
    always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
    end

endmodule