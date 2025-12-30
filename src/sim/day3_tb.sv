//`include "day3.sv"

module day3_puzzle1_tb();

    localparam NUM_UNITS=200; //we instantiate a unit for each range
    localparam CLK_PERIOD = 10;

    logic clock = 0, reset = 1, en = 0;
    logic [3:0] next_battery [NUM_UNITS]; //being a single digit, 4 bits are enough
    logic [NUM_UNITS -1 + 7:0] joltage_sum ; //for wdigit numbers, 8 bits are enough

    day3_puzzle1 #(.NUM_UNITS(NUM_UNITS)) day3_puzzle_dut(.*);

    int fd, max=0;
    string line [NUM_UNITS];

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, day3_puzzle1_tb);
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


module day3_puzzle2_tb();

    localparam NUM_UNITS=200; //we instantiate a unit for each range
    localparam NUM_ACTIVE_BATTERIES = 12;
    localparam BCD_W = 4*NUM_ACTIVE_BATTERIES;
    localparam BIN_W = BCD_W*3/4+4;
    localparam CLK_PERIOD = 10;

    logic clock, reset, init;
    logic [3:0] next_battery [NUM_UNITS];
    logic [7:0] battery_pack_size [NUM_UNITS];
    logic [BIN_W+NUM_UNITS-2:0] joltage_sum;

    day3_puzzle2#(.NUM_UNITS(NUM_UNITS), .NUM_ACTIVE_BATTERIES(NUM_ACTIVE_BATTERIES)) day3_puzzle_dut(.*);

    int fd, max=0;
    string line [NUM_UNITS];

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, day3_puzzle1_tb);
        forever begin
            #(CLK_PERIOD/2) clock = ~clock;
        end
    end

    initial begin
        wait(clock == 1);
        wait(clock == 0); //perform a complete clock cycle
        reset = '0;

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

        for (int i=0;i<NUM_UNITS;i++) begin
            battery_pack_size[i] = line[i].len();
            if(line[i].getc(battery_pack_size[i]-1) == 8'hA) // newline(0XA) is included, so we exclude it manually
                battery_pack_size[i] -= 1;
        end
        init = 1'b1;
        wait(clock == 1);
        wait(clock == 0);

        init = 1'b0;
        for (int j=0;j<battery_pack_size[0];j++) begin //we assume all pack sizes are equal in this testbench
            foreach (line[i]) begin
                next_battery[i] = line[i].getc(j) - "0";
            end
            wait(clock == 1);
            wait(clock == 0);
        end
        next_battery = '{default:0};

        #(10 * CLK_PERIOD); //log3(200) is ~ 5, but allow twice as much to check that the sum is not affected
        $display("Total joltage is =%d", joltage_sum);
        $finish;
    end

endmodule