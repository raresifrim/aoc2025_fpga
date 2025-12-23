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
            always_comb begin
                joltage_sum = max_joltage_bin[0];
                for (int j=1;j<NUM_UNITS;j++)
                    joltage_sum += max_joltage_bin[j];
            end
        end
    endgenerate

endmodule
