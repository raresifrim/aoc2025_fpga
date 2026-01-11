module day5_puzzle1_tb();

    localparam int WIDTH = 64;
    localparam int DEPTH = 183;
    localparam int CLK_PERIOD = 10;
    localparam int TOTAL_RANGES = 183;
    localparam int TOTAL_IDS = 1000;

    logic clock = '0, reset = '1, load_ranges='0;
    logic [WIDTH-1:0] start_range, end_range;
    logic [WIDTH-1:0] id;
    logic [WIDTH-1:0] total_fresh;

    day5_puzzle1#(.DEPTH(DEPTH),.WIDTH(WIDTH)) day5_puzzle_dut(.*);

    int fd;
    string line;
    int range_or_ids=0;
    logic [WIDTH-1:0] start_ranges [TOTAL_RANGES];
    logic [WIDTH-1:0] end_ranges [TOTAL_RANGES];
    logic [WIDTH-1:0] ids [TOTAL_IDS];

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, day5_puzzle1_tb);
        forever begin
            #(CLK_PERIOD/2) clock = ~clock;
        end
    end

    //read ranges and ids
    initial begin
        // Open the file in read mode
        fd = $fopen("../../inputs/day5_puzzle1_in.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt file handle was NULL. Check file path.");
            $finish;
        end

        $display("Reading data from input.txt...");
        for(int i=0;i<TOTAL_RANGES;i++) begin
            $fgets (line, fd);
            $sscanf(line, "%d:%d", start_ranges[i], end_ranges[i]);
        end
        $fgets (line, fd);//skip over empty line
        for(int i=0;i<TOTAL_IDS;i++) begin
            $fgets (line, fd);
            $sscanf(line, "%d", ids[i]);
            //$display("Current id:%d",ids[i]);
        end
    end

    initial begin
        wait(clock == 1);
        wait(clock == 0); //perform a complete clock cycle
        reset = '0;

        load_ranges = '1;
        for(int i=0;i<TOTAL_RANGES;i++) begin
            wait(clock == 0);
            start_range = start_ranges[i];
            end_range = end_ranges[i];
            wait(clock == 1);
        end
        wait(clock == 0);
        load_ranges = '0;

        for(int i=0;i<TOTAL_IDS;i++) begin
            wait(clock == 0);
            id = ids[i];
            wait(clock == 1);
        end
        wait(clock == 0); //wait one more clock cycle for last value
        id = '0;
        wait(clock == 1);

        #((DEPTH+1)*CLK_PERIOD);
        $display("Total fresh indredients:%d", total_fresh);
        $finish;
    end
endmodule

module day5_puzzle2_tb();

    localparam int WIDTH = 64;
    localparam int DEPTH = 256;
    localparam int CLK_PERIOD = 10;
    localparam int TOTAL_RANGES = 5;

    logic clock = '0, reset = '1, load_ranges='0, start_transfer='0;
    logic valid, stop;
    logic [WIDTH-1:0] start_range, end_range;
    logic [WIDTH-1:0] total_fresh;

    day5_puzzle2#(.DEPTH(DEPTH),.WIDTH(WIDTH)) day5_puzzle_dut(.*);

    int fd;
    string line;
    int range_or_ids=0;
    logic [WIDTH-1:0] start_ranges [TOTAL_RANGES];
    logic [WIDTH-1:0] end_ranges [TOTAL_RANGES];

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, day5_puzzle2_tb);
        forever begin
            #(CLK_PERIOD/2) clock = ~clock;
        end
    end

    //read ranges and ids
    initial begin
        // Open the file in read mode
        //fd = $fopen("../../inputs/day5_puzzle1_in.txt", "r");
        fd = $fopen("../../inputs/day5_test.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt file handle was NULL. Check file path.");
            $finish;
        end

        $display("Reading data from input.txt...");
        for(int i=0;i<TOTAL_RANGES;i++) begin
            $fgets (line, fd);
            $sscanf(line, "%d:%d", start_ranges[i], end_ranges[i]);
        end
    end

    longint gold_value = '0;
    initial begin
        wait(clock == 1);
        wait(clock == 0); //perform a complete clock cycle
        reset = '0;

        load_ranges = '1;
        for(int i=0;i<TOTAL_RANGES;i++) begin
            wait(clock == 0);
            start_range = start_ranges[i];
            end_range = end_ranges[i];
            wait(clock == 1);
        end

        wait(clock == 0);
        load_ranges = '0;
        start_range = '0;
        end_range = '0;

        start_transfer='1;
        wait(stop == 1);
        #(CLK_PERIOD);
        $display("Total fresh indredients:%d", total_fresh);
        for (int i=0;i<TOTAL_RANGES;i++) begin
          $display("Range @%d = [%d,%d] is valid(%d); Original Range [%d, %d]",
            i,
            day5_puzzle_dut.processing_element_inst.start_mem.ram[i],
            day5_puzzle_dut.processing_element_inst.end_mem.ram[i],
            day5_puzzle_dut.processing_element_inst.valid_ranges[i],
            start_ranges[i],
            end_ranges[i]
            );
          if(day5_puzzle_dut.processing_element_inst.valid_ranges[i] == '1)
            gold_value += (day5_puzzle_dut.processing_element_inst.end_mem.ram[i] - day5_puzzle_dut.processing_element_inst.start_mem.ram[i] + 1'b1);
        end
        $display("Gold value = %d", gold_value);
        $finish;
    end
endmodule