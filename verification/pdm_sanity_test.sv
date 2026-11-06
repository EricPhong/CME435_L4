`ifndef PDM_SANITY_TEST_SV
`define PDM_SANITY_TEST_SV

class pdm_sanity_test extends pdm_test_base;
    `uvm_component_utils(pdm_sanity_test)

    function new(string name = "pdm_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual task run_phase(uvm_phase phase);
        pdm_sanity_seq seq;

        phase.raise_objection(this);

        // 1. Launch reactive downstream sequences on all 4 output channels
        start_downstream_reactive_vseq();

        // 2. Wait for hardware reset release
        if (env_cfg.upstream_cfg.vif.rst_b !== 1'b1) begin
            `uvm_info(get_type_name(), "Waiting for reset deassertion (rst_b == 1)...", UVM_LOW)
            @(posedge env_cfg.upstream_cfg.vif.rst_b);
        end
        // Allow settling cycles after reset deassertion
        repeat (5) @(posedge env_cfg.upstream_cfg.vif.clk);

        // 3. Instantiate and run the sanity sequence on the upstream sequencer
        `uvm_info(get_type_name(), "Executing pdm_sanity_seq on upstream sequencer...", UVM_LOW)
        seq = pdm_sanity_seq::type_id::create("seq");
        seq.start(env_cfg.upstream_cfg.sqr_h);

        // 4. Drain time: allow in-flight transfers and PROCEED/DATA_OUT handshakes to complete
        `uvm_info(get_type_name(), "Waiting for final downstream handshakes to drain...", UVM_LOW)
        #500ns;

        phase.drop_objection(this);
    endtask : run_phase

endclass : pdm_sanity_test

`endif // PDM_SANITY_TEST_SV