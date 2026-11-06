/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_agent extends uvm_agent; // extend uvm agent
  
  `uvm_component_utils(pdm_upstream_agent)//registration with factory
  
  pdm_upstream_agent_cfg cfg;
  pdm_upstream_sequencer sequencer;
  pdm_upstream_driver driver;
  pdm_upstream_monitor monitor;

  //std constructor
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  // build phase get the config file from the config db and virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  
    if (!uvm_config_db#(pdm_upstream_agent_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal("UPCFG","upstream cfg missing")
    uvm_config_db#(pdm_upstream_agent_cfg)::set(this,"*","cfg",cfg);
    
    // start constructs
    // setup monitor 
    monitor=pdm_upstream_monitor::type_id::create("monitor",this);
    // if in active mode setup the sequencer and the driver
    if (cfg.is_active == UVM_ACTIVE) begin
      sequencer=pdm_upstream_sequencer::type_id::create("sequencer",this);
      driver=pdm_upstream_driver::type_id::create("driver",this);
    end
  endfunction
  
  // connect thigns together
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE) 
    begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      cfg.sqr_h=sequencer; // sequencer hand assignemnt
    end
  endfunction
endclass
