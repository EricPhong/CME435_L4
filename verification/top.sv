/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
`timescale 1ns/1ps

module top;

    // Package Importing
    import uvm_pkg::*; 
    import pdm_pkg::*;

    // Known Synchronous to CLK (50 MHz, 20ns period)

    // Clock parameters USE CLOCKING BLOCK?
    parameter real CLK_PERIOD = 20.0;             // Total period in ns (20 ns = 50 MHz)
    localparam real HALF_PERIOD = CLK_PERIOD / 2.0; // 10 ns toggle delay

    bit clk = 0;
    always #(HALF_PERIOD) clk = ~clk;

    // Physical interfaces: 
    // 1 input if and 4 output if
    pdm_upstream_if   u_if(clk); // Global clk sync
    pdm_downstream_if d_if0(clk, u_if.rst_b); // Global clk sync and reset sync
    pdm_downstream_if d_if1(clk, u_if.rst_b);
    pdm_downstream_if d_if2(clk, u_if.rst_b);
    pdm_downstream_if d_if3(clk, u_if.rst_b);
    // pdm_downstream_if d_if[4](clk, u_if.rst_b);

    // Existing DUT wrapper: dut/pdm_top.v defines module "pdm".
    
    pdm dut (
        // DUT 
        .clk           (clk),
        // Upstream_interface
        .rst_b         (u_if.rst_b),
        .bnd_plse      (u_if.bnd_plse),
        .data_in       (u_if.data_in),
        .ack           (u_if.ack),
        // Downstream_interface (0->3)
        .newdata_len_1 (d_if0.newdata_len),
        .proceed_1     (d_if0.proceed),
        .data_out_1    (d_if0.data_out),
        .newdata_len_2 (d_if1.newdata_len),
        .proceed_2     (d_if1.proceed),
        .data_out_2    (d_if1.data_out),
        .newdata_len_3 (d_if2.newdata_len),
        .proceed_3     (d_if2.proceed),
        .data_out_3    (d_if2.data_out),
        .newdata_len_4 (d_if3.newdata_len),
        .proceed_4     (d_if3.proceed),
        .data_out_4    (d_if3.data_out)
    );

    // Register virtual interfaces to the UVM Configuration Database
    // initial begin
    //     uvm_config_db#(virtual pdm_upstream_if)::set(
    //         null, "uvm_test_top", "u_vif", u_if); // null indicates no parent

    //     for (int i = 0; i < 4; i++) begin
    //         uvm_config_db#(virtual pdm_downstream_if)::set(
    //             null, "uvm_test_top", $sformatf("d_vif_%0d", i), d_if[i]);
    //     end

    //     run_test();
    // end
    // // Doesn't work

    initial begin
        uvm_config_db#(virtual pdm_upstream_if)::set( 
            null, "uvm_test_top", "u_vif", u_if);
        uvm_config_db#(virtual pdm_downstream_if)::set(
            null, "uvm_test_top", "d_vif_0", d_if0);
        uvm_config_db#(virtual pdm_downstream_if)::set(
            null, "uvm_test_top", "d_vif_1", d_if1);
        uvm_config_db#(virtual pdm_downstream_if)::set(
            null, "uvm_test_top", "d_vif_2", d_if2);
        uvm_config_db#(virtual pdm_downstream_if)::set(
            null, "uvm_test_top", "d_vif_3", d_if3);
        run_test();
    end
endmodule
