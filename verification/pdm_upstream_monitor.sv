/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_monitor extends uvm_monitor;
  `uvm_component_utils(pdm_upstream_monitor)
  pdm_upstream_agent_cfg cfg;
  virtual pdm_upstream_if vif;
  uvm_analysis_port #(upstream_seq_item) upstream_txn_ap;
  uvm_event reset_event;
  bit collecting;
  bit [7:0] dest;
  bit [7:0] bytes[$];
  bit ack_pending;
  int unsigned ack_age;

  function new(string name,uvm_component parent);
    super.new(name,parent);
    upstream_txn_ap=new("upstream_txn_ap",this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_upstream_agent_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal("UPCFG","upstream cfg missing")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("UPVIF","virtual interface missing")
    reset_event=uvm_event_pool::get_global("pdm_reset_event");
  endfunction

  function void reset_collection();
    collecting=0;
    bytes.delete();
    ack_pending=0;
    ack_age=0;
  endfunction

  task watch_async_reset();
    forever begin
      @(negedge vif.rst_b);
      reset_collection();
      reset_event.trigger();
      `uvm_info("PDM_RST","Asynchronous reset observed",UVM_MEDIUM)
    end
  endtask

  task observe_bus();
    upstream_seq_item item;
    forever begin
      @(vif.cb_mon);
      if (vif.rst_b !== 1'b1) begin
        reset_collection();
        continue;
      end
      if (ack_pending) begin
        ack_age++;
        if (vif.cb_mon.ack === 1'b1) begin
          if (!(ack_age inside {[1:4]}))
            `uvm_error("ACKTIME",$sformatf("ACK delay %0d cycles (expected 1..4)",ack_age))
          ack_pending=0;
        end else if (ack_age > 4) begin
          `uvm_error("ACKTIME","No ACK within four cycles after final BND_PLSE")
          ack_pending=0;
        end
      end else if (vif.cb_mon.ack === 1'b1) begin
        `uvm_error("ACKEXTRA","Unexpected ACK without a completed packet")
      end

      if (!collecting) begin
        if (vif.cb_mon.bnd_plse === 1'b1) begin
          collecting=1;
          dest=vif.cb_mon.data_in;
          bytes.delete();
          if (!(dest inside {[1:4]}))
            `uvm_error("BAD_DEST",$sformatf("Invalid destination %0d",dest))
        end
      end else begin
        bytes.push_back(vif.cb_mon.data_in);
        if (vif.cb_mon.bnd_plse === 1'b1) begin
          if (!(bytes.size() inside {4,8,12,16}))
            `uvm_error("BAD_LEN",$sformatf("Payload length %0d not permitted",bytes.size()))
          item=upstream_seq_item::type_id::create("observed_packet");
          item.operation=upstream_seq_item::DATA_TRANSFER;
          item.destination=dest;
          item.data_len=bytes.size();
          item.data=new[bytes.size()];
          foreach (item.data[i]) item.data[i]=bytes[i];
          upstream_txn_ap.write(item);
          collecting=0;
          bytes.delete();
          ack_pending=1;
          ack_age=0;
        end else if (bytes.size() > 16) begin
          `uvm_error("PACKET_LONG","No terminating BND_PLSE within 16 data bytes")
          reset_collection();
        end
      end
    end
  endtask

  task run_phase(uvm_phase phase);
    fork
      watch_async_reset();
      observe_bus();
    join
  endtask
endclass
