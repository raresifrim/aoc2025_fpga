module max_joltager_puzzle1(
        input logic clock, reset, en,
        input logic [3:0] next_battery,
        output logic [7:0] max_joltage
    );

    logic [7:0] high;
    logic [7:0] low;
    logic [7:0] current_joltage;
    logic [3:0] next_battery_reg; //register the inputs

    logic high_bigger, low_bigger;

    assign high = {current_joltage[7:4], next_battery_reg};
    assign low = {current_joltage[3:0], next_battery_reg};

    assign high_bigger = high >= current_joltage & high >= low;
    assign low_bigger = low > current_joltage & low > high;

    always_ff @( posedge clock ) begin
        if (reset) begin
            current_joltage <= '0;
            next_battery_reg <= '0;
        end
        else if(en) begin
            next_battery_reg <= next_battery;
            if (high_bigger)
                current_joltage <= high;
            else if (low_bigger)
                current_joltage <= low;
        end
    end

    assign max_joltage = current_joltage;

endmodule

module twobcd2bin(
        input logic clock, //make it part of the pipeline in order to get better timing
        input logic [7:0] bcd,
        output logic [7:0] bin
    );

    //optimise for 2 digit numbers only
    logic [5:0] multiplied_by2;
    logic [7:0] multiplied_by8;
    assign multiplied_by2 = {bcd[7:4], 1'b0};
    assign multiplied_by8 = {1'b0, bcd[7:4], 3'b000}; //get tens digit as x*2 + x*8
    always_ff@(posedge clock)
        bin <= (multiplied_by8 + multiplied_by2) + bcd[3:0];

endmodule

// CARRY8 primitive for Xilinx FPGAs
// Compatible with Verilator tool (www.veripool.org)
// Copyright (c) 2019-2022 Frédéric REQUIN
// License : BSD
// Imported it in order to simulate the CARRY8 primitive in verilator/iverilog

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

module day3_puzzle#(
    parameter NUM_UNITS = 200,
    parameter PUZZLE = 1
    )(
        input logic clock, reset, en,
        input logic[3:0] next_battery [NUM_UNITS],
        output logic [NUM_UNITS - 1 + 7:0] joltage_sum
    );

    generate
        genvar i;
        if (PUZZLE == 1) begin
            logic [7:0] max_joltage_bcd [NUM_UNITS];
            logic [7:0] max_joltage_bin [NUM_UNITS];
            for (i=0;i<NUM_UNITS;i++) begin
                max_joltager_puzzle1 max_joltager_inst(
                    .clock(clock),
                    .reset(reset),
                    .en(en),
                    .next_battery(next_battery[i]),
                    .max_joltage(max_joltage_bcd[i])
                    );
                twobcd2bin bcd2bin_inst(
                    .clock(clock),
                    .bcd(max_joltage_bcd[i]),
                    .bin(max_joltage_bin[i])
                );
            end

            adder_tree #(.W(8), .NUM_INPUTS(NUM_UNITS)) adder_tree_inst(
                .clock(clock),
                .inputs(max_joltage_bin),
                .total_sum(joltage_sum)
            );
        end
    endgenerate

endmodule
