/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_agent_cfg extends uvm_object;
  `uvm_object_utils(pdm_upstream_agent_cfg)
  virtual pdm_upstream_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  pdm_upstream_sequencer sqr_h;
  function new(string name="pdm_upstream_agent_cfg");
    super.new(name);
  endfunction
endclass
