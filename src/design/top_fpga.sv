module top_fpga(
  input logic clk,
  input logic rstn,
  output logic [1:0] counter,
  output logic even
);

  logic slow_clk;
  clk_div clk_div_inst (.clk_in(clk), .rstn(rstn), .clk_out(slow_clk));
  counter counter_inst (.clk(slow_clk), .rstn(rstn), .counter(counter), .even(even));

endmodule
