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