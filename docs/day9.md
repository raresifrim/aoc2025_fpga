# Day 9 - Part 1 only

The design for Day 9 (first part) is implemented in a pipeline fashion.

The reasoning for finding the largest area is that, especially as we care about identifying rectangles by opposing corners, is that the furtherest opposite points in the entire 2D plan will give us the largest area availbale.

Of course there are four corners of a rectangle:
- upper left
- upper right
- bottom left
- bottom right

In a pipeline fashion, we receive every clock cycle a new coordinate (x,y) as input, and what we are doing is checking if that coordinate is either one of the following:

- Most upper right point possible
- Most upper left point possible
- Most bottom right point possible
- Most bottom left point possible

and save it in the corresponding register corner pair (x and y).

In order to get "maximum" possible corners in each direction we start off at reset with our registers that hold out coordinates for each corner with the maximum possible values:

```verilog
if (reset) begin
    right_up_corner_x <= '0; //all 0s
    right_up_corner_y <= '1; //all 1s
    right_low_corner_x <= '0;
    right_low_corner_y <= '0;
    left_up_corner_x <= '1;
    left_up_corner_y <= '1;
    left_low_corner_x <= '1;
    left_low_corner_y <= '0;
end
```

For a new received coordinate, we first check if the difference between its coordinates and the current max coordinates of our cornes is positive in the direction of the corner, meaning that the new cooridnate sits further than the current one on that direction.

As example, lets consider the following:
- **x_coord** and **y_coord** are a new set of inputs we received in our pipeline
- **right_up_corner_x** and **right_up_corner_y** our registers that hold the current highest found coordinates for the upper right corner. These registers are initializes at reset as right_up_corner_x = 0x0, right_up_corner_y = 0xFFF..; as the right-most upper corner possible sits at the opposite coordinates (0XFFFF, 0x0), anything that is "better" than our reset values is better.
- **right_up** will be our temp result where we check if the sum of the difference of the coordinates is greater than zero. The bigger the value the better. As differences can be negative we need to use the signed values.

Our system verilog implementation for it is the following and it is similar for the other corners:
```verilog
logic signed [W+1:0] right_up = (signed'({1'b0,x_coord}) - signed'({1'b0,right_up_corner_x})) + (signed'({1'b0,right_up_corner_y}) - signed'({1'b0,y_coord}));

logic signed [W+1:0] right_low = (signed'({1'b0,x_coord}) - signed'({1'b0,right_low_corner_x})) + (signed'({1'b0,y_coord}) - signed'({1'b0,right_low_corner_y}));

logic signed [W+1:0] left_up = (signed'({1'b0,left_up_corner_x}) - signed'({1'b0,x_coord})) + (signed'({1'b0,left_up_corner_y}) - signed'({1'b0,y_coord}));

logic signed [W+1:0] left_low = (signed'({1'b0,left_low_corner_x}) - signed'({1'b0,x_coord})) + (signed'({1'b0,y_coord}) - signed'({1'b0,left_low_corner_y}));
```
With these "directions" computed for each corner, we just need to check that the difference is always positive and that at least one of the coordinate (x or y) of the new point is greater/lower (depending on the corner) than our current registered values. If so, we can update our registers with the new coordinates:

```verilog
if (right_up > 0 && (x_coord >= right_up_corner_x || y_coord <= right_up_corner_x)) begin
    right_up_corner_x <= x_coord;
    right_up_corner_y <= y_coord;
end

if (right_low > 0 && (x_coord >= right_low_corner_x || y_coord >= right_low_corner_y)) begin
    right_low_corner_x <= x_coord;
    right_low_corner_y <= y_coord;
end

if (left_up > 0 && (x_coord <= left_up_corner_x || y_coord <= left_up_corner_y)) begin
    left_up_corner_x <= x_coord;
    left_up_corner_y <= y_coord;
end

if (left_low > 0 && (x_coord <= left_low_corner_x && y_coord >= left_low_corner_y)) begin
    left_low_corner_x <= x_coord;
    left_low_corner_y <= y_coord;
end
```

As we have the maximum possible coordinates of our four corners maintained in the pipeline registers, at each clock cycle, in the next pipeline stage, we compute the possible side sizes of the two rectangels we can form as:
```verilog
square1_w <= right_up_corner_x - left_low_corner_x + 1'b1;
square1_h <= left_low_corner_y - right_up_corner_y + 1'b1;
square2_w <= right_low_corner_x - left_up_corner_x + 1'b1;
square2_h <= right_low_corner_y - left_up_corner_y + 1'b1;
```
Afterwards, in the next pipeline stage, using two parallel multipliers implemented through DSPs we compute the areas of the two rectangles. Here we limited ourselves to only one DSP per multiplier, meaning we can only have inputs for up to 17-bits. Scalling the size of the input is straightforward as the multipliers just have to be implemented using a series of multiple DSPs. I have an example [here](https://github.com/raresifrim/dsp-wrappers/blob/main/design_sources/mult64x64.v) for a 64-bit multiplier using 16 DSPs.

In our final pipeline stage, we then compare the two areas and register the highest one.

The initial pipeline stage contains the entire direction computation (two parallel subtractions followed by their sum) and the comparison. This is just for the purpose of the puzzle, but if we care about timing closure, we can split this stage in tree stages: subtraction, sum of subtractions and comparison. We just need to invest some more FFs in order to also propagate our coordinates up until the stage where we compute the rectangle sides.

## Input/Output ports

```verilog
input logic clock, reset,
input logic [W-1:0] x_coord,
input logic [W-1:0] y_coord,
output logic [2*W-1:0] area
```

## Parameters

```verilog
//should be enough for our puzzle inputs, and it also fits nicely into a DSP for multiplication
// in case bigger inputs are needed, we just need to modify our DSP-based multiplier
localparam W=17
```

## FPGA Resource Consumption

We consider 17-bit inputs.

### Part 1

| LUT as Logic | LUT as Memory | Register as Flip Flop | Register as Latch | BRAMs | DSPs | CARRY |
| :----------: |:-------------:| :--------------------:|:-----------------:|:-----:|:----:|:-----:|
| 395          | 0             | 272                    |0                  |0      |4     |82     |

**LATENCY FOR DAY 9 PUZZLE INPUT= 500 Clock Cycles**

[Back to main page](../README.md)