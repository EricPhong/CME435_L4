/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_downstream_agent_cfg extends uvm_object;
  `uvm_object_utils(pdm_downstream_agent_cfg)
  virtual pdm_downstream_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  int unsigned reset_epoch = 0; // Incremented by monitor on async reset.
  int unsigned port_id; // Logical output index 0..3
  int unsigned min_proceed_delay = 1;
  int unsigned max_proceed_delay = 4;
  pdm_downstream_sequencer sqr_h;
  function new(string name="pdm_downstream_agent_cfg");
    super.new(name);
  endfunction
endclass
