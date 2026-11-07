/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
//Note only clk is an input as the driver controls the rst_b variable
interface pdm_upstream_if(input logic clk);

  //Declare wires
  logic rst_b;
  logic [7:0] data_in;
  logic bnd_plse;
  logic ack;

  // DRIVER CLOCKING BLOCK
  clocking cb_drv @(negedge clk); 
    default input #1step output #0; // Preponed input | Re-NBA Output
    output data_in, bnd_plse; // Driver will be sending the data in and bnd plse out to the dut
    input ack; // Driver will be looking for ack to know yes packet is accepted
  endclocking

  // MONITOR CLOCKING BLOCK
  clocking cb_mon @(posedge clk);
    default input #1step output #1ns; // Crucial for avoiding monitor/driver races
    input data_in, bnd_plse, ack;
  endclocking

  // Modport Defines the inputs and outputs from the perspective of the DUT
  // modport DUT (input clk, rst_b, data_in, bnd_plse, output ack); // dut takes in clock, reset, data_in, bnd_plse and ack
  // looks like its not required becuase of direct pin connections in the top.sv file


  // Driver and Monitor modport for the upstream agent
  modport DRV (clocking cb_drv, output rst_b, input clk);
  modport MON (clocking cb_mon, input rst_b, clk);
endinterface
