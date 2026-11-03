/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
interface pdm_downstream_if(input logic clk, input logic rst_b);

  // Physical wires from dut output to the tb
  logic [7:0] data_out;
  logic [4:0] newdata_len;
  logic proceed;

  // Driver clocking block
  clocking cb_drv @(negedge clk); // Driver is only output the procced
    default input #1step output #0; // neg edge preponed input and re_nba oputput
    output proceed;
    input newdata_len, data_out;
  endclocking

  // Monitor clocking block
  clocking cb_mon @(posedge clk); 
    default input #1step;
    input newdata_len, data_out, proceed;
  endclocking

  // Modport from the DUTs perspective 
  // modport DUT (input clk, rst_b, proceed, output data_out, newdata_len); 
  // looks like its not required becuase of direct pin connections in the top.sv file

  // Modport for Driver and Monitor
  modport DRV (clocking cb_drv, input rst_b, clk);
  modport MON (clocking cb_mon, input rst_b, clk);
endinterface
