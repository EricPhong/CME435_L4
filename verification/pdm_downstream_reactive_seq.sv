/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_downstream_reactive_seq extends uvm_sequence #(downstream_seq_item);
  `uvm_object_utils(pdm_downstream_reactive_seq)
  `uvm_declare_p_sequencer(pdm_downstream_sequencer)
  pdm_downstream_agent_cfg cfg;
  function new(string name="pdm_downstream_reactive_seq");
    super.new(name);
  endfunction
  task body();
    downstream_seq_item notification, ready;
    int unsigned min_d,max_d;
    if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(p_sequencer,"","cfg",cfg))
      `uvm_fatal("REACFG","Reactive sequencer has no downstream config")
    min_d=cfg.min_proceed_delay;
    max_d=cfg.max_proceed_delay;
    if (min_d < 1 || max_d > 4 || min_d > max_d)
      `uvm_fatal("DELAYCFG","PROCEED delay range must stay within 1..4")
    forever begin
      p_sequencer.mon_req_fifo.get(notification);
      if (notification.kind != downstream_seq_item::REQ ||
          notification.reset_epoch != cfg.reset_epoch ||
          cfg.vif.rst_b !== 1'b1) continue;
      ready=downstream_seq_item::type_id::create("ready");
      start_item(ready);
      if (!ready.randomize() with {
            proceed_delay >= local::min_d;
            proceed_delay <= local::max_d;
          }) `uvm_fatal("DNRAND","Cannot randomize PROCEED delay")
      ready.kind=downstream_seq_item::READY;
      ready.port_id=cfg.port_id;
      ready.newdata_len=notification.newdata_len;
      ready.reset_epoch=notification.reset_epoch;
      finish_item(ready);
    end
  endtask
endclass
