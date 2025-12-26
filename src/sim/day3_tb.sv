//`include "day3.sv"

module day3_puzzle_tb();

    localparam NUM_UNITS=200; //we instantiate a unit for each range
    localparam CLK_PERIOD = 10;
    localparam PUZZLE = 1;

    logic clock = 0, reset = 1, en = 0;
    logic [3:0] next_battery [NUM_UNITS]; //being a single digit, 4 bits are enough
    logic [NUM_UNITS -1 + 7:0] joltage_sum ; //for wdigit numbers, 8 bits are enough

    day3_puzzle #(.NUM_UNITS(NUM_UNITS), .PUZZLE(PUZZLE)) day3_puzzle_dut(.*);

    int fd, max=0;
    string line [NUM_UNITS];

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, day3_puzzle_tb);
        forever begin
            #(CLK_PERIOD/2) clock = ~clock;
        end
    end

    initial begin
        wait(clock == 1);
        wait(clock == 0); //perform a complete clock cycle
        reset = '0;
        en = 1'b1;

        // Open the file in read mode
        fd = $fopen("../../inputs/day3_puzzle1_in.txt", "r");
        //fd = $fopen("../../inputs/day3_test.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt file handle was NULL. Check file path.");
            $finish;
        end

        $display("Reading data from input.txt...");
        for (int i=0;i<NUM_UNITS;i++)
            $fgets (line[i], fd);

        max = line[0].len();

        for (int j=0;j<max;j++) begin
            foreach (line[i]) begin
                next_battery[i] = line[i].getc(j) - "0";
            end
            wait(clock == 1);
            wait(clock == 0);
        end

        en = 0;

        #(10 * CLK_PERIOD); //log3(200) is ~ 5, but allow twice as much to check that the sum is not affected
        $display("Joltage sum is %d", joltage_sum);
        $finish;
    end

endmodule

module fast_adderNb_tb();

    localparam W = 32;

    logic clock = 0;
    logic [W-1:0] A,B,C;
    logic [W+1:0] P;
    fast_adderNb #(.W(W)) dut(.*);

    initial
        forever #5 clock = ~clock;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fast_adderNb_tb);
        $monitor("A = %d, B = %d, C = %d, P=%d", A,B,C,P);
        #0 A=1;B=2;C=3;
        #10 A=10;B=12;C=13;
        #10 A=15;B=15;C=15;
        #10 A=15;B=15;C=15;
        #10 A=115;B=123;C=145;
        #10 A=275;B=324;C=454;
        #10 A=24750;B=32324;C=45354;
        #10 $finish;
    end


endmodule

module adder_tree_tb();

    localparam W = 16;
    localparam N = 200;
    localparam INPUT_START=16'hFFFF/2;

    logic clock = 0;
    logic [W-1:0] inputs [N];
    logic [W+N-2:0] total_sum;
    adder_tree #(.W(W), .NUM_INPUTS(N)) dut(.*);

    logic [W+N-2:0] gold_sum = 0;
    initial
        forever #5 clock = ~clock;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, adder_tree_tb);
        #0
        for (int i=0;i<N;i++) begin 
            inputs[i] = i+INPUT_START;
            gold_sum += i+INPUT_START;
        end
        #100
        if (total_sum == gold_sum)
            $display("Got correct P result is %d", total_sum);
        else
            $display("ERROR detected! Correct P result is %d, while we got %d", gold_sum, total_sum);
        $finish;
    end


endmodule