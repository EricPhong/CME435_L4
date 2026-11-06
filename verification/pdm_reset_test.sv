`ifndef PDM_RESET_TEST_SV
`define PDM_RESET_TEST_SV

class pdm_reset_test extends pdm_test_base;
  `uvm_component_utils(pdm_reset_test)

  function new(string name = "pdm_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    pdm_reset_traffic_seq rst_seq;

    phase.raise_objection(this);
    start_downstream_reactive_vseq();

    if (env_cfg.upstream_cfg.vif.rst_b !== 1'b1)
      @(posedge env_cfg.upstream_cfg.vif.rst_b);
    repeat (5) @(posedge env_cfg.upstream_cfg.vif.clk);

    rst_seq = pdm_reset_traffic_seq::type_id::create("rst_seq");
    if (!rst_seq.randomize() with { iterations == 4; })
      `uvm_fatal("TESTRAND", "Failed to randomize reset sequence iterations")

    `uvm_info(get_type_name(), "--- Executing asynchronous reset sequence (between & during packets) ---", UVM_LOW)
    rst_seq.start(env_cfg.upstream_cfg.sqr_h);

    #600ns;
    phase.drop_objection(this);
  endtask : run_phase

endclass : pdm_reset_test

`endif // PDM_RESET_TEST_SV