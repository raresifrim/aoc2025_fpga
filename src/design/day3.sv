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

module max_joltager_puzzle2#(
    parameter NUM_ACTIVE_BATTERIES=12
    )(
        input logic clock, reset, init,
        input logic [3:0] next_battery,
        input logic [7:0] battery_pack_size, //the number of batteries in a pack, up to 255
        output logic [4*NUM_ACTIVE_BATTERIES-1:0] active_joltage
    );

    logic [7:0] battery_counter;
    logic count_down;
    assign count_down = ~reset & ~init & battery_counter > '0;
    always_ff@(posedge clock) begin
        if(reset) begin
            battery_counter <= '0;
        end
        else begin
            if(init)
                battery_counter <= battery_pack_size;
            else if(count_down)
                battery_counter <= battery_counter - 1'b1;
        end
    end

    logic [NUM_ACTIVE_BATTERIES-1:0] load_bucket;
    logic [NUM_ACTIVE_BATTERIES-1:0] empty_bucket;
    logic [3:0] buckets [NUM_ACTIVE_BATTERIES];
    always_ff@(posedge clock) begin
        if (reset || init) begin
            for(int i=NUM_ACTIVE_BATTERIES-1;i>=0;i--) begin
                buckets[i] <= '0;
            end
        end
        else begin
            for(int i=NUM_ACTIVE_BATTERIES-1;i>=0;i--) begin
                if (load_bucket[i])
                    buckets[i] <= next_battery;
                else if (empty_bucket[i])
                    buckets[i] <= '0;
            end
        end
    end

    always_comb begin
        load_bucket = '0;
        empty_bucket = '0;
        for(int i=NUM_ACTIVE_BATTERIES-1;i>=0;i--) begin
            if(next_battery > buckets[i] && battery_counter > i) begin
                load_bucket[i] = 1'b1;
                for(int j=i-1;j>=0;j--)
                    empty_bucket[j] = 1'b1;
                break;
            end
        end
    end

   assign active_joltage = { <<4{buckets}};

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

module day3_puzzle1#(
    parameter NUM_UNITS = 200
    )(
        input logic clock, reset, en,
        input logic[3:0] next_battery [NUM_UNITS],
        output logic [NUM_UNITS - 1 + 7:0] joltage_sum
    );

    generate
        genvar i;
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
    endgenerate

endmodule

module day3_puzzle2#(
    parameter NUM_UNITS = 200,
    parameter NUM_ACTIVE_BATTERIES=12,
    localparam BCD_W = 4*NUM_ACTIVE_BATTERIES,
    localparam BIN_W = BCD_W*3/4+4
    )(
        input logic clock, reset, init,
        input logic[3:0] next_battery [NUM_UNITS],
        input logic[7:0] battery_pack_size [NUM_UNITS],
        output logic [BIN_W+NUM_UNITS-2:0] joltage_sum
    );

    generate
        genvar i;
        logic [BCD_W-1:0] max_joltage_bcd [NUM_UNITS];
        logic [BIN_W-1:0] max_joltage_bin [NUM_UNITS];
        logic [BIN_W-1:0] max_joltage_reg [NUM_UNITS];
        for (i=0;i<NUM_UNITS;i++) begin
            max_joltager_puzzle2 max_joltager_inst(
                .clock(clock),
                .reset(reset),
                .init(init),
                .battery_pack_size(battery_pack_size[i]),
                .next_battery(next_battery[i]),
                .active_joltage(max_joltage_bcd[i])
                );
            bcd2bin #(BIN_W) bin_converter(
                .bcd(max_joltage_bcd[i]),
                .bin(max_joltage_bin[i])
                );
        end

        always_ff@(posedge clock)
            for(int j=0;j<NUM_UNITS;j++)
                max_joltage_reg[j] <= max_joltage_bin[j];

        adder_tree #(.W(BIN_W), .NUM_INPUTS(NUM_UNITS)) adder_tree_inst(
            .clock(clock),
            .inputs(max_joltage_reg),
            .total_sum(joltage_sum)
        );
    endgenerate

endmodule