module day2_puzzle_tb();

    localparam W=48; //large enough for the provided ranges, while also being able to map to DSPs
    localparam NUM_UNITS=38; //we instantiate a unit for each range
    localparam CLK_PERIOD = 10;
    localparam PUZZLE = 2;
    localparam DSP_UNITS = (NUM_UNITS / 2) + (NUM_UNITS % 2);

    logic clock = 0, reset = 1,load = 0, en = 0;
    logic [W-1:0] start_id [0:NUM_UNITS-1]; 
    logic [W-1:0] end_id [0:NUM_UNITS-1];
    logic [W-1:0] id_sum;
    logic done;

    day2_puzzle #(.W(W), .NUM_UNITS(NUM_UNITS), .PUZZLE(PUZZLE)) day2_puzzle_dut(.*);

    int fd, range_idx=0;
    bit [W-1:0] a ,b;
    string line; //compatible with both vivado and iverilog

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, day2_puzzle_tb);
        forever begin
            #(CLK_PERIOD/2) clock = ~clock;
        end
    end

    initial begin
        wait(clock == 1);
        wait(clock == 0); //perform a complete clock cycle
        reset = '0;
        load = 1'b1;

        // Open the file in read mode
        fd = $fopen("../../inputs/day2_puzzle1_in.txt", "r");
        //fd = $fopen("../../inputs/day2_test.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt file handle was NULL. Check file path.");
            $finish;
        end

        $display("Reading data from input.txt...");
        //test single range...NUM_UNITS must be set to 1
        //start_id[0] = 527473787;
        //end_id[0] = 527596071;
        //test from file
        while (!$feof(fd)) begin
            $fgets (line, fd);
            $sscanf(line, "%d:%d", a, b); //had to modify the range separator to work in verilator
            start_id[range_idx] = a;
            end_id[range_idx] = b;
            $display("%d -> %d", start_id[range_idx], end_id[range_idx]);
            range_idx += 1;
        end

        wait(clock == 1);
        wait(clock == 0);
        load = 0;
        en = 1;

        wait(done == 1);
        #((DSP_UNITS+1)*CLK_PERIOD); //worst case wait for all DSPs to propagate their values
       $display("Result is: %x", id_sum);
        $finish;
    end

endmodule