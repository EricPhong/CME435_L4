`ifndef PDM_PACKET_LEN_TEST_SV
`define PDM_PACKET_LEN_TEST_SV

class pdm_packet_len_test extends pdm_test_base;
  `uvm_component_utils(pdm_packet_len_test)

  function new(string name = "pdm_packet_len_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual task run_phase(uvm_phase phase);
    pdm_pkt_len_seq len_seq;

    phase.raise_objection(this);
    start_downstream_reactive_vseq();

    // Await reset deassertion
    if (env_cfg.upstream_cfg.vif.rst_b !== 1'b1)
      @(posedge env_cfg.upstream_cfg.vif.rst_b);
    repeat (5) @(posedge env_cfg.upstream_cfg.vif.clk);

    len_seq = pdm_pkt_len_seq::type_id::create("len_seq");

    // Phase 1: Directed sweep across all 4 ports x 4 valid lengths
    `uvm_info(get_type_name(), "--- Phase 1: Directed length sweep across all ports ---", UVM_LOW)
    if (!len_seq.randomize() with { mode == pdm_pkt_len_seq::SWEEP_ALL; })
      `uvm_fatal("TESTRAND", "Failed to randomize sweep sequence")
    len_seq.start(env_cfg.upstream_cfg.sqr_h);

    // Phase 2: Boundary corner-case stress (min 4B and max 16B)
    `uvm_info(get_type_name(), "--- Phase 2: Min (4B) and Max (16B) corner-case length testing ---", UVM_LOW)
    if (!len_seq.randomize() with {
      mode        == pdm_pkt_len_seq::CORNER_MIN_MAX;
      num_packets == 12;
    }) `uvm_fatal("TESTRAND", "Failed to randomize corner-case sequence")
    len_seq.start(env_cfg.upstream_cfg.sqr_h);

    #500ns;
    phase.drop_objection(this);
  endtask : run_phase

endclass : pdm_packet_len_test

`endif // PDM_PACKET_LEN_TEST_SV