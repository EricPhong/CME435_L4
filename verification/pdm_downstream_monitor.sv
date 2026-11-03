/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_downstream_monitor extends uvm_monitor;
  `uvm_component_utils(pdm_downstream_monitor)
  pdm_downstream_agent_cfg cfg;
  virtual pdm_downstream_if vif;
  uvm_analysis_port #(downstream_seq_item) req_ap;
  uvm_analysis_port #(downstream_seq_item) downstream_txn_ap;
  bit waiting, capturing, prev_new, prev_proceed;
  int unsigned cycle_no, notify_cycle, received, expected;
  bit [7:0] bytes[$];

  function new(string name,uvm_component parent);
    super.new(name,parent);
    req_ap=new("req_ap",this);
    downstream_txn_ap=new("downstream_txn_ap",this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal("DNCFG","downstream cfg missing")
    vif=cfg.vif;
    if (vif==null) `uvm_fatal("DNVIF","virtual interface missing")
  endfunction
  function void clear_state();
    waiting=0;
    capturing=0;
    prev_new=0;
    prev_proceed=0;
    received=0;
    expected=0;
    bytes.delete();
  endfunction
  task watch_reset();
    forever begin
      @(negedge vif.rst_b);
      cfg.reset_epoch++;
      clear_state();
      if (cfg.sqr_h!=null) cfg.sqr_h.mon_req_fifo.flush();
    end
  endtask
  task observe_bus();
    downstream_seq_item item;
    bit new_now, proc_now;
    forever begin
      @(vif.cb_mon);
      cycle_no++;
      if (vif.rst_b !== 1'b1) begin
        clear_state();
        continue;
      end
      new_now=(vif.cb_mon.newdata_len !== 5'd0);
      proc_now=(vif.cb_mon.proceed === 1'b1);
      if (new_now && prev_new)
        `uvm_error("NDPULSE",$sformatf("Port %0d NEWDATA_LEN lasted >1 cycle",cfg.port_id))
      if (proc_now && prev_proceed)
        `uvm_error("PROCPULSE",$sformatf("Port %0d PROCEED lasted >1 cycle",cfg.port_id))

      // Capture data on every cycle AFTER the PROCEED sample.
      if (capturing) begin
        bytes.push_back(vif.cb_mon.data_out);
        received++;
        if (received == expected) begin
          item=downstream_seq_item::type_id::create("completed_packet");
          item.kind=downstream_seq_item::RSP;
          item.port_id=cfg.port_id;
          item.newdata_len=expected;
          item.reset_epoch=cfg.reset_epoch;
          item.data=new[bytes.size()];
          foreach(item.data[i]) item.data[i]=bytes[i];
          downstream_txn_ap.write(item);
          capturing=0;
          waiting=0;
          bytes.delete();
        end
      end
      if (new_now && !prev_new) begin
        if (waiting || capturing)
          `uvm_error("OVERLAP",$sformatf("Port %0d got overlapping packet",cfg.port_id))
        if (!(vif.cb_mon.newdata_len inside {4,8,12,16}))
          `uvm_error("BAD_NDL",$sformatf("Port %0d invalid NEWDATA_LEN %0d",cfg.port_id,vif.cb_mon.newdata_len))
        else begin
          expected=vif.cb_mon.newdata_len;
          notify_cycle=cycle_no;
          waiting=1;
          item=downstream_seq_item::type_id::create("notification_req");
          item.kind=downstream_seq_item::REQ;
          item.port_id=cfg.port_id;
          item.newdata_len=expected;
          item.reset_epoch=cfg.reset_epoch;
          req_ap.write(item);
        end
      end
      if (waiting && !capturing && !proc_now && cycle_no-notify_cycle==5)
        `uvm_error("NO_READY",$sformatf("Port %0d: ready missing after 4 cycles",cfg.port_id))
      if (proc_now && !prev_proceed) begin
        if (!waiting || capturing)
          `uvm_error("UNEXP_READY",$sformatf("Port %0d unexpected PROCEED",cfg.port_id))
        else begin
          if (!(cycle_no-notify_cycle inside {[1:4]}))
            `uvm_error("READY_TIME",$sformatf("Port %0d ready delay %0d",cfg.port_id,cycle_no-notify_cycle))
          capturing=1;
          received=0;
          bytes.delete();
        end
      end
      prev_new=new_now;
      prev_proceed=proc_now;
    end
  endtask
  task run_phase(uvm_phase phase);
    fork
      watch_reset();
      observe_bus();
    join
  endtask
endclass
