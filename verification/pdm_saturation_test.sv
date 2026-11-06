`ifndef PDM_SATURATION_TEST_SV
`define PDM_SATURATION_TEST_SV

class pdm_saturation_test extends pdm_test_base;
  `uvm_component_utils(pdm_saturation_test)

  function new(string name = "pdm_saturation_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    pdm_saturation_seq sat_seq;

    phase.raise_objection(this);
    start_downstream_reactive_vseq();

    if (env_cfg.upstream_cfg.vif.rst_b !== 1'b1)
      @(posedge env_cfg.upstream_cfg.vif.rst_b);
    repeat (5) @(posedge env_cfg.upstream_cfg.vif.clk);

    // Apply maximum downstream backpressure to saturate internal DUT storage
    `uvm_info(get_type_name(), "Setting downstream PROCEED delay to 4 cycles to induce pipeline backpressure", UVM_LOW)
    for (int p = 0; p < 4; p++) begin
      env_cfg.downstream_cfg[p].min_proceed_delay = 4;
      env_cfg.downstream_cfg[p].max_proceed_delay = 4;
    end

    sat_seq = pdm_saturation_seq::type_id::create("sat_seq");
    if (!sat_seq.randomize() with { burst_size == 32; })
      `uvm_fatal("TESTRAND", "Failed to randomize saturation sequence")

    `uvm_info(get_type_name(), "--- Injecting saturating burst of 32 packets ---", UVM_LOW)
    sat_seq.start(env_cfg.upstream_cfg.sqr_h);

    // Drain time: allow queued packets to exit across all channels
    `uvm_info(get_type_name(), "Saturation stimulus complete. Draining downstream FIFOs...", UVM_LOW)
    #1500ns;

    phase.drop_objection(this);
  endtask : run_phase

endclass : pdm_saturation_test

`endif // PDM_SATURATION_TEST_SV