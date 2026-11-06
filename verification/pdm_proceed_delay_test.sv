`ifndef PDM_PROCEED_DELAY_TEST_SV
`define PDM_PROCEED_DELAY_TEST_SV

class pdm_proceed_delay_test extends pdm_test_base;
  `uvm_component_utils(pdm_proceed_delay_test)

  function new(string name = "pdm_proceed_delay_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    pdm_random_traffic_seq traffic_seq;

    phase.raise_objection(this);
    start_downstream_reactive_vseq();

    if (env_cfg.upstream_cfg.vif.rst_b !== 1'b1)
      @(posedge env_cfg.upstream_cfg.vif.rst_b);
    repeat (5) @(posedge env_cfg.upstream_cfg.vif.clk);

    traffic_seq = pdm_random_traffic_seq::type_id::create("traffic_seq");

    // Phase 1: Minimum Delay (1 cycle - fast reactive handshake)
    `uvm_info(get_type_name(), "--- Phase 1: Testing minimum PROCEED delay (1 clock cycle) ---", UVM_LOW)
    for (int p = 0; p < 4; p++) begin
      env_cfg.downstream_cfg[p].min_proceed_delay = 1;
      env_cfg.downstream_cfg[p].max_proceed_delay = 1;
    end
    if (!traffic_seq.randomize() with { count == 8; })
      `uvm_fatal("TESTRAND", "Failed to randomize traffic count")
    traffic_seq.start(env_cfg.upstream_cfg.sqr_h);
    #200ns;

    // Phase 2: Maximum Delay (4 cycles - maximum protocol backpressure)
    `uvm_info(get_type_name(), "--- Phase 2: Testing maximum PROCEED delay (4 clock cycles) ---", UVM_LOW)
    for (int p = 0; p < 4; p++) begin
      env_cfg.downstream_cfg[p].min_proceed_delay = 4;
      env_cfg.downstream_cfg[p].max_proceed_delay = 4;
    end
    if (!traffic_seq.randomize() with { count == 8; })
      `uvm_fatal("TESTRAND", "Failed to randomize traffic count")
    traffic_seq.start(env_cfg.upstream_cfg.sqr_h);
    #300ns;

    // Phase 3: Randomized delay range (1 to 4 cycles with per-channel jitter)
    `uvm_info(get_type_name(), "--- Phase 3: Testing randomized PROCEED delays (1 to 4 cycles) ---", UVM_LOW)
    for (int p = 0; p < 4; p++) begin
      env_cfg.downstream_cfg[p].min_proceed_delay = 1;
      env_cfg.downstream_cfg[p].max_proceed_delay = 4;
    end
    if (!traffic_seq.randomize() with { count == 12; })
      `uvm_fatal("TESTRAND", "Failed to randomize traffic count")
    traffic_seq.start(env_cfg.upstream_cfg.sqr_h);

    #500ns;
    phase.drop_objection(this);
  endtask : run_phase

endclass : pdm_proceed_delay_test

`endif // PDM_PROCEED_DELAY_TEST_SV