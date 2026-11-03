/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_downstream_agent_cfg extends uvm_object; // extend

  `uvm_object_utils(pdm_downstream_agent_cfg)// Factory registation

  virtual pdm_downstream_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  int unsigned reset_count = 0; // Monitor adds to the count on async reset.
  int unsigned port_id; // ports 0,1,2,3
  int unsigned min_proceed_delay = 1; // min delay setttings
  int unsigned max_proceed_delay = 4; // max delay setttings
  
  pdm_downstream_sequencer sqr_h;

  // constructor  
  function new(string name="pdm_downstream_agent_cfg");
    super.new(name);
  endfunction

endclass
