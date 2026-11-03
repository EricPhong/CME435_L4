/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
// Example environment class showing how to retrieve configuration objects from the
// UVM Config DB and use that to initialize environment sub-compoenents (agents)
`ifndef PDM_ENV_SV
`define PDM_ENV_SV

class pdm_env extends uvm_env;

    // Factory Registration
    `uvm_component_utils(pdm_env) 

    // Config & Constructs
    pdm_env_cfg          env_cfg;

    pdm_upstream_agent   upstream_agent;
    pdm_downstream_agent downstream_agent[4];

    // Constructor
    function new(string name = "pdm_env", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Builder Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get config info from config_data base
        if(!uvm_config_db#(pdm_env_cfg)::get(this, "", "env_cfg", env_cfg)) begin
            `uvm_fatal(get_type_name(), "pdm_env_cfg not found in config_db")
        end

        // Register upstream agent configuration and instantiate upstream agent
        uvm_config_db#(pdm_upstream_agent_cfg)::set(this, "upstream_agent*", "cfg", env_cfg.upstream_cfg);
        upstream_agent = pdm_upstream_agent::type_id::create("upstream_agent", this);

        // Register downstream agent configurations and instantiate 4 downstream agents
        for(int i = 0; i < 4; i++) begin
            uvm_config_db#(pdm_downstream_agent_cfg)::set(
                this,
                $sformatf("downstream_agent_%0d*", i),
                "cfg",
                env_cfg.downstream_cfg[i]
            );
            downstream_agent[i] = pdm_downstream_agent::type_id::create($sformatf("downstream_agent_%0d", i), this);
        end
    endfunction : build_phase

endclass : pdm_env

`endif // PDM_ENV_SV
