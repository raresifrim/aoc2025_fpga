// Reusable modules across multiple puzzles

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

// CARRY8 primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
// Imported it in order to simulate the CARRY8 primitive in verilator/iverilog
// Comment it when using Vivado

/* verilator coverage_off */
module CARRY8
#(
    parameter CARRY_TYPE = "SINGLE_CY8" // "SINGLE_CY8", "DUAL_CY4"
)
(
    // Carry cascade input
    input  wire       CI,
    // Second carry input (in DUAL_CY4 mode)
    input  wire       CI_TOP,
    // Carry MUX data input
    input  wire [7:0] DI,
    // Carry MUX select line
    input  wire [7:0] S,
    // Carry out of each stage of the chain
    output wire [7:0] CO,
    // Carry chain XOR general data out
    output wire [7:0] O
);
    wire _w_CO0 = (S[0]) ?     CI : DI[0];
    wire _w_CO1 = (S[1]) ? _w_CO0 : DI[1];
    wire _w_CO2 = (S[2]) ? _w_CO1 : DI[2];
    wire _w_CO3 = (S[3]) ? _w_CO2 : DI[3];
    wire _w_CI  = (CARRY_TYPE == "DUAL_CY4") ? CI_TOP : _w_CO3;
    wire _w_CO4 = (S[4]) ?  _w_CI : DI[4];
    wire _w_CO5 = (S[5]) ? _w_CO4 : DI[5];
    wire _w_CO6 = (S[6]) ? _w_CO5 : DI[6];
    wire _w_CO7 = (S[7]) ? _w_CO6 : DI[7];

    assign CO   = { _w_CO7, _w_CO6, _w_CO5, _w_CO4, _w_CO3, _w_CO2, _w_CO1, _w_CO0 };
    assign O    =  S ^ { _w_CO6, _w_CO5, _w_CO4, _w_CI, _w_CO2, _w_CO1, _w_CO0, CI };

endmodule
/* verilator coverage_on */

//implemented 3:2 compressor inspired by https://community.element14.com/technologies/fpga-group/b/blog/posts/the-art-of-fpga-design---post-16
module fast_adderNb#(
    parameter W = 8
    )(
        input logic clock, //always register the output
        input logic [W-1:0] A,B,C,
        output logic [W+1:0] P //2 extra bits needed
    );

    localparam int MSB = W + 1;

    generate
        logic [MSB+1         : 0] O5;
        logic [MSB           : 0] O6;
        logic [(MSB+8)/8*8   : 0] CY;
        logic [(MSB+8)/8*8-1 : 0] SI,DI,O;
        logic [MSB           : 0] SA,SB,SC;

        assign O5[0] = '0;
        assign CY[0] = '0;
        assign SA = {'0,A};
        assign SB = {'0,B};
        assign SC = {'0,C};

        genvar i;
        for(i=0;i<=MSB;i++) begin
            assign O6[i] = SA[i] ^ SB[i] ^ SC[i] ^ O5[i];
            assign O5[i+1] = (SA[i] & SB[i]) | (SC[i] & SB[i]) | ((SA[i] & SC[i]));
        end
        assign SI = {'0,O6};
        assign DI = {'0,O5};

        for(i=0;i<=MSB/8;i++)
            CARRY8 CARRY8_inst(
                .CI(CY[i*8]),
                .CI_TOP('0),
                .DI(DI[8*i+7:8*i]),
                .S(SI[8*i+7:8*i]),
                .CO(CY[8*i+8:8*i+1]),
                .O(O[8*i+7:8*i]));

        always_ff@(posedge clock)
            P <= O;

    endgenerate

endmodule


module adder_tree#(
    parameter W = 8,
    parameter NUM_INPUTS = 2
    )(
        input logic clock,
        input logic [W-1:0] inputs [NUM_INPUTS],
        output logic [W + NUM_INPUTS - 2:0] total_sum
    );

    generate
        genvar i;
        if (NUM_INPUTS == 2)
            always_ff@(posedge clock)
                total_sum <= inputs[0] + inputs[1];
        else if (NUM_INPUTS == 3)
            fast_adderNb #(.W(W)) fast_adderNb_inst(
                .clock(clock),
                .A(inputs[0]),
                .B(inputs[1]),
                .C(inputs[2]),
                .P(total_sum));
        else begin
            if (NUM_INPUTS % 3 == 0) begin
                logic [W + 1:0] temp_sums [NUM_INPUTS/3];
                for (i=0;i<NUM_INPUTS;i=i+3)
                    fast_adderNb #(.W(W)) fast_adderNb_inst(
                        .clock(clock),
                        .A(inputs[i]),
                        .B(inputs[i+1]),
                        .C(inputs[i+2]),
                        .P(temp_sums[i/3]));
                adder_tree #(.W(W+2), .NUM_INPUTS(NUM_INPUTS/3)) adder_tree_inst(
                    .clock(clock),
                    .inputs(temp_sums),
                    .total_sum(total_sum));
            end
            else if (NUM_INPUTS % 3 == 1) begin
               logic [W + 1:0] temp_sums [NUM_INPUTS/3 + 1];
                for (i=0;i<NUM_INPUTS-1;i=i+3)
                    fast_adderNb #(.W(W)) fast_adderNb_inst(
                        .clock(clock),
                        .A(inputs[i]),
                        .B(inputs[i+1]),
                        .C(inputs[i+2]),
                        .P(temp_sums[i/3]));

                always_ff@(posedge clock) //propagate remaning iput into next layer
                    temp_sums[NUM_INPUTS/3] <= inputs[NUM_INPUTS-1];

                adder_tree #(.W(W+2), .NUM_INPUTS(NUM_INPUTS/3 + 1)) adder_tree_inst(
                    .clock(clock),
                    .inputs(temp_sums),
                    .total_sum(total_sum));
            end
            else if (NUM_INPUTS % 3 == 2) begin
               logic [W + 1:0] temp_sums [NUM_INPUTS/3 + 1];
                for (i=0;i<NUM_INPUTS-2;i=i+3)
                    fast_adderNb #(.W(W)) fast_adderNb_inst(
                        .clock(clock),
                        .A(inputs[i]),
                        .B(inputs[i+1]),
                        .C(inputs[i+2]),
                        .P(temp_sums[i/3]));

                always_ff@(posedge clock) //propagate remaning iput into next layer
                    temp_sums[NUM_INPUTS/3] <= inputs[NUM_INPUTS-2] + inputs[NUM_INPUTS-1];

                adder_tree #(.W(W+2), .NUM_INPUTS(NUM_INPUTS/3 + 1)) adder_tree_inst(
                    .clock(clock),
                    .inputs(temp_sums),
                    .total_sum(total_sum));
            end
        end
    endgenerate

endmodule

(* use_dsp = "yes" *)
module mult24x24 (input logic clock,
                  input logic signed [23:0] A,
                  input logic signed[23:0] B,
                  output logic signed [47:0] P);
   
   logic signed [47:0] PL [2:0];
   logic signed [23:0] RA;
   logic signed [23:0] RB;
   
   //behaviour of two cascaded DSPs that produce a 24x24 multiplication
   //here we can infer the DSPs instead of instantiating them as Vivado understands what we want and produces the desired circuit
   //this produces an output in 4 cycles at max DSP frequency
   always_ff@(posedge clock) begin
    //first pipeline level
        RA<=A;
        RB<=B;
    //second pipeline level
        PL[0]<=RA*RB;
    //the rest of pipeline levels
        PL[1] <= PL[0];
        PL[2] <= PL[1];
   end

   assign P = PL[2];

endmodule