/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
// Example test base class that uses config objects to configure the test environment
// and starting a reactive sequence

`ifndef PDM_TEST_BASE_SV
`define PDM_TEST_BASE_SV

class pdm_test_base extends uvm_test;
    `uvm_component_utils(pdm_test_base)

    pdm_env     env;
    pdm_env_cfg env_cfg;

    function new(string name = "pdm_test_base", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env_cfg = pdm_env_cfg::type_id::create("env_cfg");

        // Get the virtual interfaces from the config_db and place them in the config objects for the agents
        if(!uvm_config_db#(virtual pdm_upstream_if)::get(this, "", "u_vif", env_cfg.upstream_cfg.vif)) begin
            `uvm_fatal(get_type_name(), "u_vif not found in config_db with scope uvm_test_top")
        end
        for(int i = 0; i < 4; i++) begin
            string vif_name = $sformatf("d_vif_%0d", i);
            if(!uvm_config_db#(virtual pdm_downstream_if)::get(this, "", vif_name, env_cfg.downstream_cfg[i].vif)) begin
                `uvm_fatal(get_type_name(), $sformatf("%s not found in config_db with scope uvm_test_top", vif_name))
            end
            env_cfg.downstream_cfg[i].port_id = i; // Also tell the agent (cfg) what port it is connected to
        end

        uvm_config_db#(pdm_env_cfg)::set(this, "env", "env_cfg", env_cfg);
        env = pdm_env::type_id::create("env", this);
    endfunction : build_phase

    // Listen for DUT notifications on all four downstream ports.
    // No sanity or directed tests are run by this base test.
    virtual task start_downstream_reactive_vseq();
        for (int i = 0; i < 4; i++) begin
            automatic int port = i;
            fork
                begin
                    pdm_downstream_reactive_seq seq;
                    seq = pdm_downstream_reactive_seq::type_id::create(
                        $sformatf("reactive_seq_%0d", port));
                    seq.start(env_cfg.downstream_cfg[port].sqr_h);
                end
            join_none
        end
    endtask : start_downstream_reactive_vseq

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_downstream_reactive_vseq();
        // Base test only: no packets are sent until you add a real test.
        #200ns;
        phase.drop_objection(this);
    endtask : run_phase

endclass : pdm_test_base

`endif // PDM_TEST_BASE_SV
