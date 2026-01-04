module day9_puzzle1#(
    localparam W=17 //should be enough for our puzzle inputs, and it also fits nicely into a DSP for multiplication
)(
    input logic clock, reset,
    input logic [W-1:0] x_coord,
    input logic [W-1:0] y_coord,
    output logic [2*W-1:0] area
);

    //try to find the furthest corners possible on all directions
    logic [W-1:0] right_up_corner_x = '0, right_up_corner_y = '1;
    logic [W-1:0] right_low_corner_x = '0, right_low_corner_y = '0;
    logic [W-1:0] left_up_corner_x = '1, left_up_corner_y = '1;
    logic [W-1:0] left_low_corner_x = '1, left_low_corner_y = '0;

    always_ff@(posedge clock) begin
        if (reset) begin
            right_up_corner_x <= '0;
            right_up_corner_y <= '1;
            right_low_corner_x <= '0;
            right_low_corner_y <= '0;
            left_up_corner_x <= '1;
            left_up_corner_y <= '1;
            left_low_corner_x <= '1;
            left_low_corner_y <= '0;
        end
        else begin
            logic signed [W+1:0] right_up = (signed'({1'b0,x_coord}) - signed'({1'b0,right_up_corner_x})) + (signed'({1'b0,right_up_corner_y}) - signed'({1'b0,y_coord}));
            logic signed [W+1:0] right_low = (signed'({1'b0,x_coord}) - signed'({1'b0,right_low_corner_x})) + (signed'({1'b0,y_coord}) - signed'({1'b0,right_low_corner_y}));
            logic signed [W+1:0] left_up = (signed'({1'b0,left_up_corner_x}) - signed'({1'b0,x_coord})) + (signed'({1'b0,left_up_corner_y}) - signed'({1'b0,y_coord}));
            logic signed [W+1:0] left_low = (signed'({1'b0,left_low_corner_x}) - signed'({1'b0,x_coord})) + (signed'({1'b0,y_coord}) - signed'({1'b0,left_low_corner_y}));

            if (right_up > 0 && (x_coord >= right_up_corner_x || y_coord <= right_up_corner_x)) begin
                right_up_corner_x <= x_coord;
                right_up_corner_y <= y_coord;
            end

            if (right_low > 0 && (x_coord >= right_low_corner_x || y_coord >= right_low_corner_y)) begin
                right_low_corner_x <= x_coord;
                right_low_corner_y <= y_coord;
            end

            if (left_up > 0 && (x_coord <= left_up_corner_x || y_coord <= left_up_corner_y)) begin
                left_up_corner_x <= x_coord;
                left_up_corner_y <= y_coord;
            end

            if (left_low > 0 && (x_coord <= left_low_corner_x && y_coord >= left_low_corner_y)) begin
                left_low_corner_x <= x_coord;
                left_low_corner_y <= y_coord;
            end
        end
    end

    //the largest area is always provided by the opposing corners
    logic [W-1:0] square1_h, square1_w;
    logic [W-1:0] square2_h, square2_w;
    always_ff@(posedge clock) begin
        if (reset) begin
            square1_h <= '0;
            square1_w <= '0;
            square2_h <= '0;
            square2_w <= '0;
        end
        else begin
            square1_w <= right_up_corner_x - left_low_corner_x + 1'b1;
            square1_h <= left_low_corner_y - right_up_corner_y + 1'b1;
            square2_w <= right_low_corner_x - left_up_corner_x + 1'b1;
            square2_h <= right_low_corner_y - left_up_corner_y + 1'b1;
        end
    end


    logic [47:0] P1,P2;
    mult24x24 mult_inst1 (.clock(clock), .A({'0,square1_w}), .B({'0,square1_h}),.P(P1));
    mult24x24 mult_inst2 (.clock(clock), .A({'0,square2_w}), .B({'0,square2_h}),.P(P2));
    always_ff@(posedge clock) begin
        area <= P1 > P2 ? P1:P2;
    end

endmodule