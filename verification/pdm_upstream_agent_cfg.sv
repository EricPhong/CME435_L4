/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_agent_cfg extends uvm_object; // Class extend uvm_object

  `uvm_object_utils(pdm_upstream_agent_cfg) // Factory registration

  virtual pdm_upstream_if vif; // pointer to a virtual interface
  uvm_active_passive_enum is_active = UVM_ACTIVE; // activate the passive
  pdm_upstream_sequencer sqr_h; // declares the sequencer

  function new(string name="pdm_upstream_agent_cfg");
    super.new(name);
  endfunction

endclass
