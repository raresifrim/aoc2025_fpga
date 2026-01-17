# AOC 2025 FPGA

## About
Motivated by the [Advent of FPGA — A Jane Street Challenge](https://blog.janestreet.com/advent-of-fpga-challenge-2025/), I implemented my own version of the puzzles keeping in mind some of the suggested exploration points:

- Scalability: can your design handle inputs 10× or even 1000× larger?
- Efficiency: push area/performance trade-offs in the hardware.
- Architecture: exploit FPGA-native parallelism and pipelining you can’t do on a CPU.

My proposed designs are targeted towards FPGAs, specifically the AMD/Xilinx ones, and in partcular, all designs were synthesized against the [Cmod A7-35T: Breadboardable Artix-7 FPGA Module](https://digilent.com/shop/cmod-a7-35t-breadboardable-artix-7-fpga-module/?srsltid=AfmBOopMxw0Y1LE5Bvj_7DnCtTgIe88tj7wl0Z2mjqP5s7y1wymjgEUt).

Because of lack of time until the proposed deadline January 16, I was able to solve puzzles for days 1,2,3,5 and first half of day 9. Also, another bigger issue in my opinion is that not all problems could be mapped efficiently on a FPGA, espeially the Artix-7 A7-35T. Anyway, I will try to solve the rest of the puzzles as well, for fun, in my spare time.

## Design philosophy

1. The main scope for each design was first to be able to handle any kind of input, not only the specific one proposed as the puzzle input, and it should also be able to handle larger input sizes (up to a limit of course).

2. Secondly, each design should fit in the Artix-7 A7-35T. For some of the designs I had to make a trade-off between performance and area. But as a generat idea, each design solution can be seen as a unit which can fit in the specified FPGA. But as I also like performance, where there was opporunity for parallelism, especially for each input, I went for it. Basically some of the design actual solution involve parallel units to process the input as fast as possible (and of course this will increase the area), but a single unit can also be able to solve the puzzle, if some additional overhead is added to handle the partial results.

3. Last, I also pushed for each design to have some reasonable input and output ports.

Each day has its own page dedidcated with an overview of the design, and the resource estimation after synthesis. The provided tcl scripts are able to simulate the designs under different simulators: vivado, verilator, iverilog, and also are able to synthesize the designs with vivado.

For evaluation I will provide for each design the main FPGA primitives consumed (LUTs, FFs, DSPs, BRAMs, CARRYs) and the latency of the design in clock cycles for the given puzzle inputs

## Solved puzzles

- [Day 1](./docs/day1.md)
- [Day 2](./docs/day2.md)
- [Day 3](./docs/day3.md)
- [Day 5](./docs/day5.md)
- [Day 9(first part)](./docs/day9.md)

## Project structure

1. `docs`: dir containing the explanation files for each puzzle
2. `inputs`: txt files with the puzzle inputs (the testbenches are using them as they are)
3. `src/design`: SystemVerilog source files for all solved puzzles
4. `src/sim`: SystemVerilog testbench files for all solved puzzles 
5. `*.tcl + Makefile`: scripts that simulate/synth/implement the designs using Vivado mainly

## Tools used for sim/synth

- Verilator 5.041 devel rev v5.040-201-g21dbdbf69
- Vivado v2025.1

## How to run

The designs are mainly tested with the Vivado simulator. For iverilog, some modifications have to be made. Apart for the Day1 puzzle, all designs also provide the correct response under verilator as well. The Day1 puzzles work under Vivado, but not under Verilator, but I didn't had the time to check why.

In order to run a specific day puzzle (denoted by _x_) and puzzle part (denoted by _y_) under Vivado, you can run the following command format:

```
make sim top_module=day<x>_puzzle<y>_tb
```
For example to run the second part of the Day 1 puzzle, one can run:
```
make sim top_module=day1_puzzle2_tb
```
If you wish tu use verilator instead, you run it as:
```
make sim top_module=day1_puzzle2_tb simulator=verilator
```
For synthesis, the Artix7 A7-35T part is set by default and you can run it as (for the second part of the Day3 puzzle):
```
make synth top_module=day3_puzzle1
```

All results (sim/synth/implementation) will be added to a `.\build` folder. For each testbench a _dump.vcd_ file is generated.

## Last remarks
Of course some of the designs have parameters set by default for testbench, so one needs to modify them accordingly if different inputs are desired, or a specific area/performance trade-off is desired for synthesis. Anyway each puzzle dedicated README page explains the parameters and also provides the command for running the testbench.

Have fun exploring the repo! Will hopefully continue to add solutions to the other puzzles as well.