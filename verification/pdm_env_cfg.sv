/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
// Configuration for the one upstream and four downstream agents.
class pdm_env_cfg extends uvm_object;
    `uvm_object_utils(pdm_env_cfg)

    pdm_upstream_agent_cfg   upstream_cfg;
    pdm_downstream_agent_cfg downstream_cfg[4];

    function new(string name = "pdm_env_cfg");
        super.new(name);
        upstream_cfg = pdm_upstream_agent_cfg::type_id::create("upstream_cfg");
        foreach (downstream_cfg[i])
            downstream_cfg[i] = pdm_downstream_agent_cfg::type_id::create(
                $sformatf("downstream_cfg_%0d", i));
    endfunction
endclass
