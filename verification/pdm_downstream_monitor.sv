// /* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
// class pdm_downstream_monitor extends uvm_monitor;
//   `uvm_component_utils(pdm_downstream_monitor)
//   pdm_downstream_agent_cfg cfg;
//   virtual pdm_downstream_if vif;
//   uvm_analysis_port #(downstream_seq_item) req_ap;
//   uvm_analysis_port #(downstream_seq_item) downstream_txn_ap;
//   bit waiting, capturing, prev_new, prev_proceed;
//   int unsigned cycle_no, notify_cycle, received, expected;
//   bit [7:0] bytes[$];

//   function new(string name,uvm_component parent);
//     super.new(name,parent);
//     req_ap=new("req_ap",this);
//     downstream_txn_ap=new("downstream_txn_ap",this);
//   endfunction
//   function void build_phase(uvm_phase phase);
//     super.build_phase(phase);
//     if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this,"","cfg",cfg))
//       `uvm_fatal("DNCFG","downstream cfg missing")
//     vif=cfg.vif;
//     if (vif==null) `uvm_fatal("DNVIF","virtual interface missing")
//   endfunction
//   function void clear_state();
//     waiting=0;
//     capturing=0;
//     prev_new=0;
//     prev_proceed=0;
//     received=0;
//     expected=0;
//     bytes.delete();
//   endfunction
//   task watch_reset();
//     forever begin
//       @(negedge vif.rst_b);
//       cfg.reset_count++;
//       clear_state();
//       if (cfg.sqr_h!=null) cfg.sqr_h.mon_req_fifo.flush();
//     end
//   endtask
//   task observe_bus();
//     downstream_seq_item item;
//     bit new_now, proc_now;
//     forever begin
//       @(vif.cb_mon);
//       cycle_no++;
//       if (vif.rst_b !== 1'b1) begin
//         clear_state();
//         continue;
//       end
//       new_now=(vif.cb_mon.newdata_len !== 5'd0);
//       proc_now=(vif.cb_mon.proceed === 1'b1);
//       if (new_now && prev_new)
//         `uvm_error("NDPULSE",$sformatf("Port %0d NEWDATA_LEN lasted >1 cycle",cfg.port_id))
//       if (proc_now && prev_proceed)
//         `uvm_error("PROCPULSE",$sformatf("Port %0d PROCEED lasted >1 cycle",cfg.port_id))

//       // Capture data on every cycle AFTER the PROCEED sample.
//       if (capturing) begin
//         bytes.push_back(vif.cb_mon.data_out);
//         received++;
//         if (received == expected) begin
//           item=downstream_seq_item::type_id::create("completed_packet");
//           item.kind=downstream_seq_item::RSP;
//           item.port_id=cfg.port_id;
//           item.newdata_len=expected;
//           item.reset_count=cfg.reset_count;
//           item.data=new[bytes.size()];
//           foreach(item.data[i]) item.data[i]=bytes[i];
//           downstream_txn_ap.write(item);
//           capturing=0;
//           waiting=0;
//           bytes.delete();
//         end
//       end
//       if (new_now && !prev_new) begin
//         if (waiting || capturing)
//           `uvm_error("OVERLAP",$sformatf("Port %0d got overlapping packet",cfg.port_id))
//         if (!(vif.cb_mon.newdata_len inside {4,8,12,16}))
//           `uvm_error("BAD_NDL",$sformatf("Port %0d invalid NEWDATA_LEN %0d",cfg.port_id,vif.cb_mon.newdata_len))
//         else begin
//           expected=vif.cb_mon.newdata_len;
//           notify_cycle=cycle_no;
//           waiting=1;
//           item=downstream_seq_item::type_id::create("notification_req");
//           item.kind=downstream_seq_item::REQ;
//           item.port_id=cfg.port_id;
//           item.newdata_len=expected;
//           item.reset_count=cfg.reset_count;
//           req_ap.write(item);
//         end
//       end
//       if (waiting && !capturing && !proc_now && cycle_no-notify_cycle==5)
//         `uvm_error("NO_READY",$sformatf("Port %0d: ready missing after 4 cycles",cfg.port_id))
//       if (proc_now && !prev_proceed) begin
//         if (!waiting || capturing)
//           `uvm_error("UNEXP_READY",$sformatf("Port %0d unexpected PROCEED",cfg.port_id))
//         else begin
//           if (!(cycle_no-notify_cycle inside {[1:4]}))
//             `uvm_error("READY_TIME",$sformatf("Port %0d ready delay %0d",cfg.port_id,cycle_no-notify_cycle))
//           capturing=1;
//           received=0;
//           bytes.delete();
//         end
//       end
//       prev_new=new_now;
//       prev_proceed=proc_now;
//     end
//   endtask
//   task run_phase(uvm_phase phase);
//     fork
//       watch_reset();
//       observe_bus();
//     join
//   endtask
// endclass

/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 

class pdm_downstream_monitor extends uvm_monitor;
  `uvm_component_utils(pdm_downstream_monitor)
  
  pdm_downstream_agent_cfg cfg;
  virtual pdm_downstream_if vif;
  
  uvm_analysis_port #(downstream_seq_item) req_ap;
  uvm_analysis_port #(downstream_seq_item) downstream_txn_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap = new("req_ap", this);
    downstream_txn_ap = new("downstream_txn_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("DNCFG", "downstream cfg missing")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("DNVIF", "virtual interface missing")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      wait (vif.rst_b === 1'b1);
      
      fork
        observe_bus();
        begin
          // Asynchronous reset watcher
          @(negedge vif.rst_b);
          cfg.reset_count++;
          if (cfg.sqr_h != null) cfg.sqr_h.mon_req_fifo.flush();
        end
      join_any
      
      // Automatically kills observe_bus and clears execution state upon reset
      disable fork; 
    end
  endtask

  task observe_bus();
    downstream_seq_item item;
    logic [7:0] bytes[$];  // Changed from bit [7:0] to logic [7:0]
    int expected;
    int wait_cycles;

    forever begin
      @(vif.cb_mon);

      // 1. Wait for Notification (NEWDATA_LEN > 0)
      if (vif.cb_mon.newdata_len !== 5'd0) begin
        expected = vif.cb_mon.newdata_len;

        if (!(expected inside {4, 8, 12, 16})) begin
          `uvm_error("BAD_NDL", $sformatf("Port %0d invalid NEWDATA_LEN %0d", cfg.port_id, expected))
        end else begin
          item = downstream_seq_item::type_id::create("notification_req");
          item.kind = downstream_seq_item::REQ;
          item.port_id = cfg.port_id;
          item.newdata_len = expected;
          item.reset_count = cfg.reset_count;
          req_ap.write(item);
        end

        // 2. Wait for PROCEED pulse (Strictly 1 to 4 cycles delay)
        wait_cycles = 0;
        while (vif.cb_mon.proceed !== 1'b1) begin
          @(vif.cb_mon);
          wait_cycles++;

          // Protocol Violation: NEWDATA_LEN pulse lasted >1 cycle
          if (wait_cycles == 1 && vif.cb_mon.newdata_len !== 5'd0)
            `uvm_error("NDPULSE", $sformatf("Port %0d NEWDATA_LEN lasted >1 cycle", cfg.port_id))

          // Protocol Violation: Overlapping packet requested before PROCEED
          if (wait_cycles > 1 && vif.cb_mon.newdata_len !== 5'd0)
            `uvm_error("OVERLAP", $sformatf("Port %0d got overlapping packet", cfg.port_id))

          // Timeout: PROCEED did not assert within 4 cycles
          if (wait_cycles == 5) begin
            `uvm_error("NO_READY", $sformatf("Port %0d: ready missing after 4 cycles", cfg.port_id))
            break;
          end
        end

        // Abort packet collection if timeout occurred
        if (wait_cycles == 5) continue; 

        // 3. PROCEED detected. Stream Payload Bytes
        bytes.delete();
        for (int i = 0; i < expected; i++) begin
          @(vif.cb_mon);

          // Protocol Violation: PROCEED pulse lasted >1 cycle
          if (i == 0 && vif.cb_mon.proceed === 1'b1)
            `uvm_error("PROCPULSE", $sformatf("Port %0d PROCEED lasted >1 cycle", cfg.port_id))

          // Protocol Violation: Overlapping packet requested during payload stream
          if (vif.cb_mon.newdata_len !== 5'd0)
            `uvm_error("OVERLAP", $sformatf("Port %0d got overlapping packet", cfg.port_id))

          bytes.push_back(vif.cb_mon.data_out);
        end

        // 4. Publish Completed Packet
        item = downstream_seq_item::type_id::create("completed_packet");
        item.kind = downstream_seq_item::RSP;
        item.port_id = cfg.port_id;
        item.newdata_len = expected;
        item.reset_count = cfg.reset_count;
        item.data = bytes; // Direct queue-to-dynamic array assignment

        downstream_txn_ap.write(item);

      end else if (vif.cb_mon.proceed === 1'b1) begin
        // Unexpected PROCEED when no transaction is pending
        `uvm_error("UNEXP_READY", $sformatf("Port %0d unexpected PROCEED", cfg.port_id))
      end
    end
  endtask
endclass
