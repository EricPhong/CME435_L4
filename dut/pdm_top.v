`timescale 1ns/1ns

module pdm (
   clk,
   rst_b,
   bnd_plse,
   data_in,
   ack,
   newdata_len_1,
   proceed_1,
   data_out_1,
   newdata_len_2,
   proceed_2,
   data_out_2,
   newdata_len_3,
   proceed_3,
   data_out_3,
   newdata_len_4,
   proceed_4,
   data_out_4
);

// Input Ports
input        clk;
input        rst_b;
input        bnd_plse;
input  [7:0] data_in;
input        proceed_1;
input        proceed_2;
input        proceed_3;
input        proceed_4;

// Output Ports
output       ack;
output [4:0] newdata_len_1;
output [4:0] newdata_len_2;
output [4:0] newdata_len_3;
output [4:0] newdata_len_4;
output [7:0] data_out_1;
output [7:0] data_out_2;
output [7:0] data_out_3;
output [7:0] data_out_4;

// Core Instance
pdm_core pdm_core_inst(
   .clk(clk),
   .rst_b(rst_b),
   .bnd_plse(bnd_plse),
   .data_in(data_in),
   .ack(ack),
   .newdata_len_1(newdata_len_1),
   .proceed_1(proceed_1),
   .data_out_1(data_out_1),
   .newdata_len_2(newdata_len_2),
   .proceed_2(proceed_2),
   .data_out_2(data_out_2),
   .newdata_len_3(newdata_len_3),
   .proceed_3(proceed_3),
   .data_out_3(data_out_3),
   .newdata_len_4(newdata_len_4),
   .proceed_4(proceed_4),
   .data_out_4(data_out_4)
);

endmodule

