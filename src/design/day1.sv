module day1_puzzle1#(
    parameter WIDTH=16,
    parameter PUZZLE = 1
    )(
    input wire clock,
    input wire reset,
    input wire init,
    input wire valid,
    input wire rotation, //1-right,0-left
    input wire [WIDTH-1:0] rotate_amount,
    input wire [WIDTH-1:0] max_number,
    output wire ready, ///ready to receive a (new) input
    output wire [WIDTH-1:0] password
    );

    logic [WIDTH-1:0] number_ff;
    logic [WIDTH-1:0] max_ff;
    logic [WIDTH-1:0] password_ff;
    typedef enum bit { ROTATE, REDUCE} fsm_state;
    fsm_state current_state, next_state;
    logic [WIDTH-1:0] next_number;
    logic [WIDTH-1:0] load_next;
    logic [WIDTH:0] temp;

    assign password = password_ff;
    assign ready = valid & (current_state == ROTATE);

    always_ff@(posedge clock) begin
        if (reset)
            current_state <= ROTATE;
        else
            current_state <= next_state;
    end

    logic overflow;
    generate
        if (PUZZLE == 1)
            always_ff@(posedge clock) begin
                if (reset)
                    password_ff <= '0;
                else if (load_next == 1'b1 && next_number == '0)
                    password_ff <= password_ff + 1'b1;
            end
        else begin 
            logic overflow;
            assign overflow = load_next && ((temp >= max_ff && number_ff != '0) || temp == '0);
            always_ff@(posedge clock) begin
                if (reset)
                    password_ff <= '0;
                else if (overflow || reduction_en)
                    password_ff <= password_ff + 1'b1;
            end
        end
    endgenerate

    always_ff@(posedge clock) begin
        if (reset)
            max_ff <= '0;
        else if (init)
            max_ff <= max_number + 1'b1;
    end

    always_ff@(posedge clock) begin
       if (reset)
            number_ff <= '0;
        else if (init == 1'b1)
            number_ff <= rotate_amount;
        else if (load_next)
            number_ff <= next_number;
    end

    logic rotation_reg;
    logic reduction_en, rotation_en;
    logic [WIDTH-1:0] rotate_amount_reg, rotate_amount_reduced;
    assign rotate_amount_reduced = rotate_amount_reg - max_ff;
    always_ff@(posedge clock)
        if (reset)
            rotate_amount_reg <= '0;
        else if(rotation_en) begin
            rotation_reg <= rotation;
            rotate_amount_reg <= rotate_amount;
        end
        else if (reduction_en)
            rotate_amount_reg <= rotate_amount_reduced;

    assign temp = rotation_reg == 1'b1 ? number_ff + rotate_amount_reg : number_ff - rotate_amount_reg;
    assign next_number = temp < max_ff ? temp : (rotation_reg == 1'b1 ? temp - max_ff : temp + max_ff);

    always_comb begin
        //default values
        next_state = ROTATE;
        rotation_en = 1'b0;
        load_next = 1'b0;
        reduction_en = 1'b0;

        unique case(current_state)
            ROTATE: begin
                if (valid) begin
                    if (rotate_amount_reg >= max_ff) begin
                        rotation_en = 1'b0;
                        next_state = REDUCE;
                        load_next = 1'b0;
                    end
                    else begin
                        rotation_en = 1'b1;
                        next_state = ROTATE;
                        load_next = 1'b1;
                    end
                end
            end
            REDUCE: begin
                if (rotate_amount_reg < max_ff) begin
                    next_state = ROTATE;
                    rotation_en = 1'b1;
                    reduction_en = 1'b0;
                    load_next = 1'b1;
                end
                else begin
                    next_state = REDUCE;
                    reduction_en = 1'b1;
                    rotation_en = 1'b0;
                    load_next = 1'b0;
                end
            end
        endcase

    end
endmodule
 