/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_downstream_agent extends uvm_agent; // extend agent

  `uvm_component_utils(pdm_downstream_agent)//factory registation

  // handle definitions
  pdm_downstream_agent_cfg cfg; 
  pdm_downstream_sequencer sequencer;
  pdm_downstream_driver driver;
  pdm_downstream_monitor monitor;

  // std constructor
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  //build phase
  // import configs
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal("DNCFG","downstream cfg missing")
    uvm_config_db#(pdm_downstream_agent_cfg)::set(this,"*","cfg",cfg);

    //make montior every time
    monitor=pdm_downstream_monitor::type_id::create("monitor",this);

    //only make driver and sequencer if in active mode
    if (cfg.is_active==UVM_ACTIVE) begin
      sequencer=pdm_downstream_sequencer::type_id::create("sequencer",this);
      driver=pdm_downstream_driver::type_id::create("driver",this);
    end
  endfunction

  // connecting driver to sequencer via tlm pull port
  // config assignment
  // monitor requst anal port
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active==UVM_ACTIVE)
     begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      cfg.sqr_h=sequencer;
      monitor.req_ap.connect(sequencer.mon_req_fifo.analysis_export);
    end
  endfunction
endclass
