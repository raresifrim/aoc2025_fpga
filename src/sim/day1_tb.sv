module day1_puzzle1_tb();

    localparam int PUZZLE = 1;
    localparam int WIDTH = 16;

    logic clock = 1'b0;
    logic reset = 1'b1;
    logic init = 1'b0, valid = 1'b0, rotation = 1'b0;
    logic ready;
    logic [WIDTH-1:0] rotate_amount, max_number, password;

    int fd, num;
    string line;
    byte direction;

    day1_puzzle #(.WIDTH(WIDTH), .PUZZLE(PUZZLE)) dut(.*);

    always #5 clock = ~clock;

    initial begin: resetBehaviour
        #0 reset = 1'b0;
        wait(clock==1);
        reset = 1'b1;
        wait(clock==0);
        reset = 1'b0;
    end

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, day1_puzzle1_tb);
        //$monitor ("[$monitor] time=%0t password = %d", $time, password);

        #10;

        wait(clock==1 && reset==0);
        init = 1'b1;
        rotate_amount = 50;
        max_number = 99;
        wait(clock==0);
        init = 1'b0;

        // Open the file in read mode
        fd = $fopen("../../inputs/day1_puzzle1_in.txt", "r");
        //fd = $fopen("../../inputs/day1_test.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt file handle was NULL. Check file path.");
            $finish;
        end

        $display("Reading data from input.txt...");

        while (!$feof(fd)) begin
            //if (dut.ready)
            //   $write("[%d,%d]", dut.number_ff, dut.password_ff);
            wait(clock==1);
            if (!ready) begin
                valid = 1'b1;
                wait(clock==0);
            end
            else begin
                $fgets (line, fd);
                $sscanf(line, "%c%d", direction, num);
                //we sync each new input at beggining of a clock cycle
                rotate_amount = num;
                rotation = (direction == "R");
                valid = 1'b1;
                //$display("Current rotation: %d, Current direction: %d", num, rotation);
                wait(clock==0);
                //if (dut.number_ff == 0)
                    //$display("Accumulator equal to zero!");
            end
        end

        // Close the file
        $fclose(fd);

        wait(clock==1);
        valid = 1'b0;
        $display("Finished reading file. Password is %d", password);
        #10
        $finish;
    end

endmodule


module day1_puzzle2_tb();

    localparam int PUZZLE = 2;
    localparam int WIDTH = 16;

    logic clock = 1'b0;
    logic reset = 1'b1;
    logic init = 1'b0, valid = 1'b0, rotation = 1'b0;
    logic ready;
    logic [WIDTH-1:0] rotate_amount, max_number, password;

    int fd, num;
    string line;
    byte direction;

    day1_puzzle #(.WIDTH(WIDTH), .PUZZLE(PUZZLE)) dut(.*);

    always #5 clock = ~clock;

    initial begin: resetBehaviour
        #0 reset = 1'b0;
        wait(clock==1);
        reset = 1'b1;
        wait(clock==0);
        reset = 1'b0;
    end

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, day1_puzzle2_tb);
        //$monitor ("[$monitor] time=%0t password = %d", $time, password);

        #10;

        wait(clock==1 && reset==0);
        init = 1'b1;
        rotate_amount = 50;
        max_number = 99;
        wait(clock==0);
        init = 1'b0;

        // Open the file in read mode
        fd = $fopen("../../inputs/day1_puzzle1_in.txt", "r");
        //fd = $fopen("../../inputs/day1_test.txt", "r");
        if (fd == 0) begin
            $display("Error: input.txt file handle was NULL. Check file path.");
            $finish;
        end

        $display("Reading data from input.txt...");

        while (!$feof(fd)) begin
            //if (dut.ready)
            //   $write("[%d,%d]", dut.number_ff, dut.password_ff);
            wait(clock==1);
            if (!ready) begin
                valid = 1'b1;
                wait(clock==0);
            end
            else begin
                $fgets (line, fd);
                $sscanf(line, "%c%d", direction, num);
                //we sync each new input at beggining of a clock cycle
                rotate_amount = num;
                rotation = (direction == "R");
                valid = 1'b1;
                //$display("Current rotation: %d, Current direction: %d", num, rotation);
                wait(clock==0);
                //if (dut.number_ff == 0)
                    //$display("Accumulator equal to zero!");
            end
        end

        // Close the file
        $fclose(fd);

        wait(clock==1);
        valid = 1'b0;
        $display("Finished reading file. Password is %d", password);
        #10
        $finish;
    end

endmodule
