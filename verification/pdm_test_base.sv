// /* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
// // Example test base class that uses config objects to configure the test environment
// // and starting a reactive sequence

// `ifndef PDM_TEST_BASE_SV
// `define PDM_TEST_BASE_SV

// class pdm_test_base extends uvm_test;
//     `uvm_component_utils(pdm_test_base)

//     pdm_env     env;
//     pdm_env_cfg env_cfg;

//     function new(string name = "pdm_test_base", uvm_component parent);
//         super.new(name, parent);
//     endfunction : new

//     virtual function void build_phase(uvm_phase phase);
//         super.build_phase(phase);

//         env_cfg = pdm_env_cfg::type_id::create("env_cfg");

//         // Get the virtual interfaces from the config_db and place them in the config objects for the agents
//         if(!uvm_config_db#(virtual pdm_upstream_if)::get(this, "", "u_vif", env_cfg.upstream_cfg.vif)) begin
//             `uvm_fatal(get_type_name(), "u_vif not found in config_db with scope uvm_test_top")
//         end
//         for(int i = 0; i < 4; i++) begin
//             string vif_name = $sformatf("d_vif_%0d", i);
//             if(!uvm_config_db#(virtual pdm_downstream_if)::get(this, "", vif_name, env_cfg.downstream_cfg[i].vif)) begin
//                 `uvm_fatal(get_type_name(), $sformatf("%s not found in config_db with scope uvm_test_top", vif_name))
//             end
//             env_cfg.downstream_cfg[i].port_id = i; // Also tell the agent (cfg) what port it is connected to
//         end

//         uvm_config_db#(pdm_env_cfg)::set(this, "env", "env_cfg", env_cfg);
//         env = pdm_env::type_id::create("env", this);
//     endfunction : build_phase

//     // Listen for DUT notifications on all four downstream ports.
//     // No sanity or directed tests are run by this base test.
//     virtual task start_downstream_reactive_vseq();
//         for (int i = 0; i < 4; i++) begin
//             automatic int port = i;
//             fork
//                 begin
//                     pdm_downstream_reactive_seq seq;
//                     seq = pdm_downstream_reactive_seq::type_id::create(
//                         $sformatf("reactive_seq_%0d", port));
//                     seq.start(env_cfg.downstream_cfg[port].sqr_h);
//                 end
//             join_none
//         end
//     endtask : start_downstream_reactive_vseq

//     virtual task run_phase(uvm_phase phase);
//         phase.raise_objection(this);
//         start_downstream_reactive_vseq();
//         // Base test only: no packets are sent until you add a real test.
//         #200ns;
//         phase.drop_objection(this);
//     endtask : run_phase

// endclass : pdm_test_base

// `endif // PDM_TEST_BASE_SV
/* Eric Phong, rfp479, CME435, 11344905, Lab4 */

`ifndef PDM_TEST_BASE_SV
`define PDM_TEST_BASE_SV

class pdm_test_base extends uvm_test;
    `uvm_component_utils(pdm_test_base)

    pdm_env     env;
    pdm_env_cfg env_cfg;

    function new(string name = "pdm_test_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env_cfg = pdm_env_cfg::type_id::create("env_cfg");

        // Retrieve upstream virtual interface from config_db
        if (!uvm_config_db#(virtual pdm_upstream_if)::get(this, "", "u_vif", env_cfg.upstream_cfg.vif)) begin
            `uvm_fatal(get_type_name(), "u_vif not found in config_db with scope uvm_test_top")
        end

        // Retrieve downstream virtual interfaces from config_db
        for (int i = 0; i < 4; i++) begin
            string vif_name = $sformatf("d_vif_%0d", i);
            if (!uvm_config_db#(virtual pdm_downstream_if)::get(this, "", vif_name, env_cfg.downstream_cfg[i].vif)) begin
                `uvm_fatal(get_type_name(), $sformatf("%s not found in config_db with scope uvm_test_top", vif_name))
            end
            env_cfg.downstream_cfg[i].port_id = i;
        end

        uvm_config_db#(pdm_env_cfg)::set(this, "env", "env_cfg", env_cfg);
        env = pdm_env::type_id::create("env", this);
    endfunction : build_phase

    // Start reactive downstream sequences on all 4 output channels
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
        uvm_top.print_topology();
        start_downstream_reactive_vseq();
        #200ns;
        phase.drop_objection(this);
    endtask : run_phase

    // -------------------------------------------------------------------------
    // Report Phase: Formatted Terminal Summary (UVM-1.1d Compatible)
    // -------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        int error_count;
        int fatal_count;

        super.report_phase(phase);

        // UVM-1.1d report server retrieval (does not use uvm_coreservice_t)
        svr = uvm_report_server::get_server();

        error_count = svr.get_severity_count(UVM_ERROR);
        fatal_count = svr.get_severity_count(UVM_FATAL);

        $display("\n========================================================");
        $display("                 TEST EXECUTION SUMMARY                 ");
        $display("========================================================");
        $display("  TEST NAME    : %s", get_type_name());
        $display("  SIM TIME     : %0t", $time);
        $display("  FATAL COUNT  : %0d", fatal_count);
        $display("  ERROR COUNT  : %0d", error_count);
        $display("  WARNING COUNT: %0d", svr.get_severity_count(UVM_WARNING));
        $display("  INFO COUNT   : %0d", svr.get_severity_count(UVM_INFO));
        $display("--------------------------------------------------------");

        if (error_count == 0 && fatal_count == 0) begin
            $display("              *** UVM TEST PASSED ***                   ");
        end else begin
            $display("             !!! UVM TEST FAILED !!!                    ");
        end
        $display("========================================================\n");
    endfunction : report_phase

endclass : pdm_test_base

`endif // PDM_TEST_BASE_SV