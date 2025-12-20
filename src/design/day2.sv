module bin2bcd #(
    parameter W = 32 // input width
    )(
        input logic [W-1:0] bin,  // binary
        output logic [W+(W-4)/3:0] bcd
    ); // bcd {...,thousands,hundreds,tens,ones}

  //can scale on any type of input compared with a look-up table,
  //but maybe will need to split it in multiple pipeline to account for better latency
  always_comb begin
    for(int i = 0; i <= W+(W-4)/3; i++) bcd[i] = 0;     // initialize with zeros
    bcd[W-1:0] = bin;                                   // initialize with input vector
    for(int i = 0; i <= W-4; i++)                       // iterate on structure depth
      for(int j = 0; j <= i/3; j++)                     // iterate on structure width
        if (bcd[W-i+4*j -: 4] > 4)                      // if > 4
          bcd[W-i+4*j -: 4] = bcd[W-i+4*j -: 4] + 4'd3; // add 3
  end

endmodule

module bcd2bin #(
    parameter W = 32 // input width
    )(
        input logic [W+(W-4)/3:0] bcd,
        output logic [W-1:0] bin
    ); 

    logic [(W+(W-4)/3)/4:0][3:0] digits; //split into digits

   always_comb begin
        bin = '0;
        digits = bcd;
        for (int i=0; i < W; i++) begin
            bin = {digits[0][0],bin[W-1:1]};
            digits >>= 1;
            for (int j=0; j<(W+(W-4)/3)/4; j++)
                if(digits[j][3] == 1'b1) //we have a number >= 8
                    digits[j] -= 4'd3;
        end
   end

endmodule

module counter #(
    parameter W = 32 // input width
    )(
        input logic clock, reset,
        input logic load, cnt_up,
        input logic [W-1:0] cnt_in,
        output logic [W-1:0] cnt_out
    );

    var logic [W-1:0] cnt_ff = '0;
    assign cnt_out = cnt_ff;

    always_ff@(posedge clock) begin
        if (reset)
            cnt_ff <= '0;
        else if(load)
            cnt_ff <= cnt_in;
        else if(cnt_up)
            cnt_ff <= cnt_ff + 1'b1;
    end

endmodule


module msb_digit #(
    parameter W = 32 // input width
    )(
       input logic [W+(W-4)/3:0] bcd,
       output logic [7:0] msb_digit //up to 255 digits should be enough to cover any possible number
    );

    logic [(W+(W-4)/3)/4 - 1:0][3:0] digits; //split into digits
    assign digits = bcd;

    logic [(W+(W-4)/3)/4 - 1:0] non_zero; //check which digit is not zero
    always_comb
        for (int i=0; i<(W+(W-4)/3)/4; i++)
            non_zero[i] = |digits[i];

    always_comb begin//get the most significant digit based on a priority encoder
        msb_digit = '0;
        for (int i = (W+(W-4)/3)/4 - 1; i >= 0; i--) begin
            if(non_zero[i]) begin
                msb_digit = i + 1'b1; //don't index from zero
                break; //systemverilog allows this break to be synthesized
            end
        end
    end
endmodule

module id_checker #(
    parameter W = 32,
    parameter PUZZLE=1 // input width
    )(
        input logic [W+(W-4)/3:0] bcd,
        input logic [7:0] msb_digit,
        output logic invalid_id
    );
    generate

    if (PUZZLE == 1) begin
        logic [(W+(W-4)/3)/8 - 1:0][3:0] half1, half2;
        assign half1 = bcd >> ((msb_digit >> 1) << 2);
        assign half2 = bcd - (half1 << (((msb_digit >> 1) << 2)));
        assign invalid_id = (half1 == half2);
    end

    else if (PUZZLE == 2) begin
        localparam bit [3:0] MAX_DIGITS = (W+(W-4)/3)/4; //15 digits are enough for 48-bits
        localparam bit [2:0] HALF_MAX_DIGITS = (W+(W-4)/3)/8;
        //this is an ideal combinational case where we comapre all possible repeatitions in parallel at once in once clock cycle
        //for better timing we coulg split this in a pipeline as well for each repetition
        //we have MAX_DIGITS maximum number of digits in BCD as (W+(W-4)/3)/4 where is W is the width in number of bits of our numbers
        //we have HALF_MAX_DIGITS which is the half of the above amount as best case we only have two halves that are equal => invalid id
        //we will have HALF_MAX_DIGITS repeaters that repeats each BCD digit as needed, afterwards we check if the resulted number is equal to our initial number

        //generate a look-up table to avoid the modulo operator
        typedef bit LUT_t [0:2**7 - 1]; //enough for our 48-bit inputs or 15-digit numbers
        function automatic LUT_t LUT_init();
            LUT_t data = '{default: 0};
            for(bit[7:0] i = '0; i<(2**7); i++) begin
                bit[3:0] msb = i[3:0];
                bit[3:0] idx = i[6:4] + 1'b1;
                bit val = ~|(msb % idx);
                data[i] = val;
            end
            return data;
        endfunction

        (* ram_style = "block" *) LUT_t Mask_Array = LUT_init;

        //we use the repeater operator to repeat each possible sequnce of a BCD (up to the half) until we fill an entire number
        //we compare then the obtained number with our original BCD and check if they are equal
        //if so, the it means our original BCD is composed for a sequence of repeating digits
        //as we don't know before hand how large our input BCD is, we fill an entire [W+(W-4)/3:0] number, but this will not be exactly our BCD
        //so we create masks depending on the repeating step in order to obatin a sequence of repeating digits equal in size with our BCD
        // as a number like 5.2175.2175 will generate for the sequence 2175 the number 2175.2175.2175.2175 which truncated will result in to 5.2175.2175 which is a false postive
        //so as second check, we only check sequences that fill in perfectly the size of our BCD based on the detected most significant digit
        //and it is why we generate the lookup table above in order to avoid the modulo operator

        logic [(W+(W-4)/3)/4:0][3:0] digits; //split into digits
        assign digits = bcd;
        logic [W+(W-4)/3:0] sequences [0:HALF_MAX_DIGITS-1];
        logic [HALF_MAX_DIGITS-1:0] is_invalid;

        logic [W+(W-4)/3:0] mask;
        assign mask = ~('1 << (msb_digit << 2));

        genvar i;
        assign sequences[0] = {MAX_DIGITS{digits[0]}};
        for (i=1; i<HALF_MAX_DIGITS; i++) 
            assign sequences[i] = Mask_Array[{i, msb_digit[3:0]}] ? {'0,{(HALF_MAX_DIGITS-i+1){digits[i:0]}}} : '0;
        for(i=0; i<HALF_MAX_DIGITS; i++)
            assign is_invalid[i] = (sequences[i] & mask) == bcd;

        logic [HALF_MAX_DIGITS-1:0] flag_mask;
        assign flag_mask = ~(HALF_MAX_DIGITS'('1) << (msb_digit >> 1));
        assign invalid_id = |(is_invalid & flag_mask);
    end
    endgenerate

endmodule

module accumulator #(
    parameter W=32
    )(
        input logic clock, reset, acc_en,
        input logic [W-1:0] next_input,
        output logic [W-1:0] current
    );
    logic [W-1:0] acc_reg = '0;
    assign current = acc_reg;

    always_ff@(posedge clock) begin
        if (reset)
            acc_reg <= '0;
        else if (acc_en)
            acc_reg <= acc_reg + next_input;
    end

endmodule

module id_finder #(
    parameter W = 32, // input width
    parameter PUZZLE = 1
    )(
        input logic clock, reset,
        input logic load, en,
        input logic [W-1:0] start_id,
        input logic [W-1:0] end_id,
        output logic [W-1:0] id_sum,
        output logic done
    );


    logic [W-1:0] current_id_bin_s1, current_id_bin_s2, current_id_bin_s3;
    logic in_range_s1, in_range_s2, in_range_s3, in_range_s4, in_range_s5;
    logic [W+(W-4)/3:0] current_id_bcd_s1, current_id_bcd_s2, current_id_bcd_s3, current_id_bcd_s4;
    logic [7:0] msb_digit_s1, msb_digit_s2;
    logic is_invalid_s1, is_invalid_s2, is_invalid_s3;

    always_ff@(posedge clock) begin
        if (reset) begin
            current_id_bcd_s2 <= '0;
            current_id_bcd_s3 <= '0;
            current_id_bcd_s4 <= '0;
            current_id_bin_s3 <= '0;
            is_invalid_s2 <= '0;
            is_invalid_s3 <= '0;
            msb_digit_s2 <= '0;
            in_range_s2 <= '0;
            in_range_s3 <= '0;
            in_range_s4 <= '0;
            in_range_s5 <= '0;
        end
        else begin
            current_id_bcd_s2 <= current_id_bcd_s1;
            current_id_bcd_s3 <= current_id_bcd_s2;
            current_id_bcd_s4 <= current_id_bcd_s3;
            current_id_bin_s3 <= current_id_bin_s2;
            is_invalid_s2 <= is_invalid_s1;
            is_invalid_s3 <= is_invalid_s2;
            msb_digit_s2 <= msb_digit_s1;
            in_range_s2 <= in_range_s1;
            in_range_s3 <= in_range_s2;
            in_range_s4 <= in_range_s3;
            in_range_s5 <= in_range_s4;
        end
    end

    assign in_range_s1 = (current_id_bin_s1 <= end_id);
    counter #(W) cnt(.*, .cnt_up(en & in_range_s1), .cnt_in(start_id), .cnt_out(current_id_bin_s1));
    bin2bcd #(W) bcd_converter(.bin(current_id_bin_s1), .bcd(current_id_bcd_s1)); //stage 1
    msb_digit #(W) msb_digit_prioenc(.bcd(current_id_bcd_s2), .msb_digit(msb_digit_s1)); //stage 2
    id_checker #(.W(W), .PUZZLE(PUZZLE)) id_validator(.bcd(current_id_bcd_s3), .msb_digit(msb_digit_s2), .invalid_id(is_invalid_s1)); //stage 3
    bcd2bin #(W) bin_converter(.bcd(current_id_bcd_s4), .bin(current_id_bin_s2)); //stage 4
    accumulator #(W) acc_inst(.*, .acc_en(en & is_invalid_s3 & in_range_s5), .next_input(current_id_bin_s3), .current(id_sum)); //stage 5

    assign done = (en & ~in_range_s5 & ~in_range_s1);
endmodule


(* use_dsp = "yes" *)
module adder_cascade#(
    parameter W = 48 //force it into DSP if we can
    )(
        input logic clock,
        input logic signed [W-1:0] a,
        input logic signed [W-1:0] b,
        input logic signed [W-1:0] pcin,
        output logic signed [W-1:0] pcout
);

   always_ff@(posedge clock)
    pcout <= a + b + pcin;
endmodule

//used for at least 2 parallel units
module id_gatherer #(
    parameter W = 32,
    parameter NUM_UNITS = 2
    )(
        input logic clock,
        input logic [W-1:0] partial_sums [0:NUM_UNITS-1],
        input logic [NUM_UNITS-1:0] partial_dones,
        output logic [W-1:0] id_sum,
        output logic done
    );

    assign done = &partial_dones;
    generate
        localparam ADDER_WIDTH = W > 48 ? W : 48;
        localparam DSP_UNITS = (NUM_UNITS / 2) + (NUM_UNITS % 2);
        if (DSP_UNITS == 1)
            adder_cascade #(ADDER_WIDTH) adder_cascade_inst(
                .clock(clock),
                .a({{(48-W){'0}},partial_sums[0]}),
                .b({{(48-W){'0}},partial_sums[1]}),
                .pcin('0),
                .pcout(id_sum)
            );
        else if (DSP_UNITS > 1)begin
            genvar i;
            logic [47:0] carry_outs [0:DSP_UNITS-2];

            adder_cascade #(ADDER_WIDTH) adder_cascade_first(
                .clock(clock),
                .a({{(48-W){'0}},partial_sums[0]}),
                .b({{(48-W){'0}},partial_sums[1]}),
                .pcin('0),
                .pcout(carry_outs[0]));

            for (i=1;i <= DSP_UNITS - 2;i++) begin
                adder_cascade #(ADDER_WIDTH) adder_cascade_middle(
                .clock(clock),
                .a({{(48-W){'0}},partial_sums[i*2]}),
                .b({{(48-W){'0}},partial_sums[i*2+1]}),
                .pcin(carry_outs[i-1]),
                .pcout(carry_outs[i]));
            end

            logic [47:0] a, b;
            if ((NUM_UNITS % 2) != 0) begin
                assign b = '0;
                assign a = {{(48-W){'0}},partial_sums[NUM_UNITS-1]};
            end
            else begin 
                assign b = {{(48-W){'0}},partial_sums[NUM_UNITS-1]};
                assign a = {{(48-W){'0}},partial_sums[NUM_UNITS-2]};
            end

            adder_cascade #(ADDER_WIDTH) adder_cascade_last(
                .clock(clock),
                .a(a),
                .b(b),
                .pcin(carry_outs[DSP_UNITS - 2]),
                .pcout(id_sum));
        end
    endgenerate

endmodule

module day2_puzzle#(
    parameter W = 48,
    parameter NUM_UNITS = 8,
    parameter PUZZLE = 2
    )(
        input logic clock, reset, en, load,
        input logic [W-1:0] start_id [0:NUM_UNITS-1],
        input logic [W-1:0] end_id [0:NUM_UNITS-1],
        output logic [W-1:0] id_sum,
        output logic done
    );

    generate
        genvar i;
        logic [W-1:0] partial_sums [0:NUM_UNITS-1];
        logic [NUM_UNITS-1:0] partial_dones;
        for (i=0; i<NUM_UNITS;i++) begin
            id_finder #(.W(W), .PUZZLE(PUZZLE)) id_finder_inst( .*,
                .start_id(start_id[i]),
                .end_id(end_id[i]),
                .id_sum(partial_sums[i]),
                .done(partial_dones[i])
            );
        end
        if(NUM_UNITS > 1)
            id_gatherer #(.W(W),.NUM_UNITS(NUM_UNITS)) id_gatherer_inst(.*);
        else begin
            assign id_sum = partial_sums[0];
            assign done = partial_dones[0];
        end
    endgenerate

endmodule