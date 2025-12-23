`include "day3.sv"

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

        #(3 * CLK_PERIOD);
        $display("Joltage sum is %d", joltage_sum);
        $finish;
    end

endmodule