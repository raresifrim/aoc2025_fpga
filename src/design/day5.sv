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

module processing_element2#(
    parameter WIDTH=64,
    parameter DEPTH=512 //an entire BRAM
)(
    input logic clock, reset, we,
    input logic start,
    input logic [WIDTH-1:0] start_range_in, end_range_in,
    output logic [WIDTH-1:0] start_range_out, end_range_out,
    output logic valid, stop
);

    logic [WIDTH-1:0] start_reg, end_reg;
    logic [DEPTH-1:0] valid_ranges = '0;

    logic cnt_load, cnt_up;
    logic [$clog2(DEPTH)-1:0] cnt_in, cnt_out;
    logic done;

    counter #(.W($clog2(DEPTH))) counter_inst(
        .clock(clock), .reset(reset),
        .load(cnt_load), .cnt_up(cnt_up),
        .cnt_in('0), .cnt_out(cnt_out)
    );
    assign cnt_load = (last_address - 1'b1) == cnt_out;
    assign cnt_up = start & ~done;

    logic [$clog2(DEPTH)-1:0] last_address, max_address;
    always_ff@(posedge clock) begin
        if(reset)
            last_address <= '0;
        else begin
            if(we)
                last_address <= last_address + 1'b1;
            else if(cnt_load)
                last_address <= last_address - 1'b1;

            if (we)
                max_address <= last_address;
            else if(done && max_address != '0)
                max_address <= max_address - 1'b1;
        end
    end
    assign done = last_address == '0;

    logic mem_write;
    logic [WIDTH-1:0] start_mem_in, end_mem_in;
    logic [WIDTH-1:0] start_mem_out, end_mem_out;
    logic [$clog2(DEPTH)-1:0] mem_address_w, mem_address_r;

    dp_dc_ram #(.WIDTH(WIDTH),.DEPTH(DEPTH)) start_mem(
        .clka(clock), .clkb(~clock), .we(mem_write),
        .addra(mem_address_w),
        .addrb(mem_address_r),
        .dia(start_mem_in),
        .dob(start_mem_out)
        );

    dp_dc_ram #(.WIDTH(WIDTH),.DEPTH(DEPTH)) end_mem(
        .clka(clock), .clkb(~clock), .we(mem_write),
        .addra(mem_address_w),
        .addrb(mem_address_r),
        .dia(end_mem_in),
        .dob(end_mem_out)
        );
    assign start_mem_in = we ? start_range_in : start_extended;
    assign end_mem_in = we ? end_range_in : end_extended;
    assign mem_write = we | (expand_range & ~done);
    assign mem_address_w = we ? last_address : cnt_out;
    assign mem_address_r = done ? max_address : (cnt_load ? last_address - 1'b1 : cnt_out);

    logic expand_range;
    logic [WIDTH-1:0] start_extended, end_extended;
    assign expand_range = (start_mem_out <= start_reg && end_mem_out >= start_reg) |
                          (start_mem_out <= end_reg && end_mem_out >= end_reg);
    assign start_extended = (start_mem_out <= start_reg) ? start_mem_out : start_reg;
    assign end_extended = (end_mem_out >= end_reg) ? end_mem_out : end_reg;

    logic load_ranges;
    always_ff@(posedge clock) begin
        if(reset) begin
            start_reg <= '0;
            end_reg <= '0;
            valid_ranges <= '0;
            stop <= '0;
        end
        else if(we) begin
            start_reg <= start_range_in;
            end_reg <= end_range_in;
        end
        else if(cnt_load) begin
            start_reg <= start_mem_out;
            end_reg <= end_mem_out;
        end

        if(we)
            valid_ranges[last_address] <= 1'b1;
        else if(cnt_up && expand_range)
            valid_ranges[last_address] <= 1'b0;

        if(we)
            stop <= '0;
        else 
            stop <= done & max_address == '0;
    end

    assign valid = valid_ranges[max_address] & done;
    assign start_range_out = start_mem_out;
    assign end_range_out = end_mem_out;

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

module day5_puzzle2#(
    parameter WIDTH=64,
    parameter DEPTH=512
    )(
        input logic clock, reset,
        input logic load_ranges,
        input logic start_transfer,
        input logic [WIDTH-1:0] start_range, end_range,
        output logic [WIDTH-1:0] total_fresh,
        output logic stop
    );

    logic [WIDTH-1:0] r2, r1;
    logic valid;
    processing_element2#(.WIDTH(WIDTH), .DEPTH(DEPTH)) processing_element_inst(
                .clock(clock),
                .reset(reset),
                .we(load_ranges),
                .start(start_transfer),
                .start_range_in(start_range),
                .end_range_in(end_range),
                .start_range_out(r1),
                .end_range_out(r2),
                .valid(valid),
                .stop(stop)
                );

        logic [WIDTH-1:0] total_fresh_reg = '0;
        always_ff @(posedge clock) begin
            if(reset | load_ranges)
                total_fresh_reg <= '0;
            else if(valid & ~stop) begin
                total_fresh_reg <= total_fresh_reg + (r2 - r1 + 1'b1);
            end
        end
        assign total_fresh = total_fresh_reg;

endmodule