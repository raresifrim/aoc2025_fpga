module day9_puzzle1_tb();

    localparam int W = 17;
    localparam int CLK_PERIOD = 10;

    logic clock = 0, reset = 1;
    logic [W-1:0] x_coord = '0;
    logic [W-1:0] y_coord = '0;
    logic [2*W-1:0] area;
    day9_puzzle1 day9_puzzle_dut(.*);

    int fd;
    bit [W-1:0] x ,y;
    string line;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, day9_puzzle1_tb);
        forever begin
            #(CLK_PERIOD/2) clock = ~clock;
        end
    end

    initial begin
        wait(clock == 1);
        wait(clock == 0); //perform a complete clock cycle
        reset = '0;

        // Open the file in read mode
        fd = $fopen("../../inputs/day9_puzzle1_in.txt", "r");
        //fd = $fopen("../../inputs/day9_test.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt file handle was NULL. Check file path.");
            $finish;
        end

        $display("Reading data from input.txt...");
        while (!$feof(fd)) begin
            wait(clock==0);
            $fgets (line, fd);
            $sscanf(line, "%d,%d", x, y);
            $display("Seding coord: %d, %d", x,y);
            x_coord = x;
            y_coord = y;
            wait(clock == 1);
        end

        #(6*CLK_PERIOD); //we have six pipeline stages in total
        $display("Area = %d", area);
        $finish;
    end
endmodule