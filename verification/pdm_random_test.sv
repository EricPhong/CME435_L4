`ifndef PDM_RANDOM_TEST_SV
`define PDM_RANDOM_TEST_SV

class pdm_random_test extends pdm_test_base;
  `uvm_component_utils(pdm_random_test)

  function new(string name = "pdm_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    pdm_random_traffic_seq seq;

    phase.raise_objection(this);
    start_downstream_reactive_vseq();

    if (env_cfg.upstream_cfg.vif.rst_b !== 1'b1)
      @(posedge env_cfg.upstream_cfg.vif.rst_b);
    repeat (5) @(posedge env_cfg.upstream_cfg.vif.clk);

    // Randomize downstream reactive delays between 1 and 4 cycles
    for (int p = 0; p < 4; p++) begin
      env_cfg.downstream_cfg[p].min_proceed_delay = 1;
      env_cfg.downstream_cfg[p].max_proceed_delay = 4;
    end

    seq = pdm_random_traffic_seq::type_id::create("seq");
    if (!seq.randomize() with { count == 30; })
      `uvm_fatal("TESTRAND", "Failed to randomize random test count")

    `uvm_info(get_type_name(), "--- Running full constrained-random test (30 packets) ---", UVM_LOW)
    seq.start(env_cfg.upstream_cfg.sqr_h);

    #800ns;
    phase.drop_objection(this);
  endtask : run_phase

endclass : pdm_random_test

`endif // PDM_RANDOM_TEST_SV