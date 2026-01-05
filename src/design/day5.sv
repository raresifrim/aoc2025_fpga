module processing_element1#(
    parameter WIDTH=64
    )(
        input logic clock,
        input logic reset,
        input logic we,
        input logic [WIDTH-1:0] start_range_in, end_range_in,
        input logic [WIDTH-1:0] id_in,
        input logic in_range_in,
        output logic [WIDTH-1:0] start_range_out, end_range_out,
        output logic [WIDTH-1:0] id_out,
        output logic in_range_out
    );

    logic [WIDTH-1:0] start_reg = '0, end_reg = '0;

    assign start_range_out = start_reg;
    assign end_range_out = end_reg;

    always_ff@(posedge clock) begin
        if(reset) begin
            start_reg <= '0;
            end_reg <= '0;
            id_out <= '0;
            in_range_out <= '0;
        end
        else begin
            if(we) begin
                start_reg <= start_range_in;
                end_reg <= end_range_in;
                in_range_out <= '0;
            end
            else begin
                if((start_reg <= id_in && id_in <= end_reg) || in_range_in) begin
                    in_range_out <= '1;
                end
                else
                    in_range_out <= '0;
            end
            id_out <= id_in;
        end
    end

endmodule

module day5_puzzle1#(
    parameter WIDTH=64,
    parameter DEPTH=183
    )(
        input logic clock, reset,
        input logic load_ranges,
        input logic [WIDTH-1:0] start_range, end_range,
        input logic [WIDTH-1:0] id,
        output logic [31:0] total_fresh
    );

    generate
        logic [WIDTH-1:0] start_ranges [DEPTH+1];
        logic [WIDTH-1:0] end_ranges [DEPTH+1];
        logic [WIDTH-1:0] ids [DEPTH+1];
        logic [DEPTH:0] in_range;
        assign start_ranges[0] = start_range;
        assign end_ranges[0] = end_range;
        assign ids[0] = id;
        assign in_range[0] = '0;

        genvar i;
        for(i=0;i<DEPTH;i++) begin
            processing_element1#(.WIDTH(WIDTH)) processing_element_inst(
                .clock(clock),
                .reset(reset),
                .we(load_ranges),
                .start_range_in(start_ranges[i]),
                .end_range_in(end_ranges[i]),
                .start_range_out(start_ranges[i+1]),
                .end_range_out(end_ranges[i+1]),
                .id_in(ids[i]),
                .id_out(ids[i+1]),
                .in_range_in(in_range[i]),
                .in_range_out(in_range[i+1])
                );
        end

        counter #(.W(32)) counter_inst(.clock(clock), .reset(reset), .load('0), .cnt_up(in_range[DEPTH] & ~load_ranges), .cnt_in('0), .cnt_out(total_fresh));

    endgenerate

endmodule