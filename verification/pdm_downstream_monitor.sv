/* Eric Phong, rfp479, CME435, 11344905, Lab4 */

class pdm_downstream_monitor extends uvm_monitor;
  `uvm_component_utils(pdm_downstream_monitor)
  
  pdm_downstream_agent_cfg cfg;
  virtual pdm_downstream_if vif;
  
  uvm_analysis_port #(downstream_seq_item) req_ap;
  uvm_analysis_port #(downstream_seq_item) downstream_txn_ap;


  // std constrcutor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap = new("req_ap", this);
    downstream_txn_ap = new("downstream_txn_ap", this);
  endfunction

  // get config and virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("DNCFG", "downstream cfg missing")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("DNVIF", "virtual interface missing")
  endfunction

  // running
  task run_phase(uvm_phase phase);
    forever begin
      wait (vif.rst_b === 1'b1); // wait till prev reset is done
      
      fork
        observe_bus();
        begin
          // asnyc reset watcher
          @(negedge vif.rst_b);
          cfg.reset_count++;
          if (cfg.sqr_h != null) cfg.sqr_h.mon_req_fifo.flush();
        end
      join_any
      
      // kill all on  reset
      disable fork; 
    end
  endtask

//------------------------------------------------------------------------------
// Task: observe_bus
//
// Continuously monitors the downstream interface bus to observe, validate, and
// reconstruct inbound data packets according to the handshake protocol.
//
// Operates as an ongoing loop synchronized to the monitor clocking block:
// 1. Awaits a new data notification via a non-zero NEWDATA_LEN signal, validates
//    that the length conforms to allowed packet sizes ({4, 8, 12, 16}), and
//    broadcasts an initial request item via req_ap.
// 2. Awaits the assertion of the PROCEED pulse within a strict 1 to 4 cycle
//    window while monitoring for protocol violations (such as multi-cycle
//    NEWDATA_LEN pulses or overlapping packet requests). Aborts capture upon
//    timeout.
// 3. Upon receiving PROCEED, samples the payload byte stream across consecutive
//    clock cycles, verifying single-cycle PROCEED pulse width and ensuring no
//    interleaved request assertions occur.
// 4. Assembles the collected byte queue into a response sequence item and publishes
//    the completed transaction via downstream_txn_ap.
// 5. Flags any spurious or unsolicited PROCEED assertions occurring outside an
//    active transaction window.
//------------------------------------------------------------------------------
  task observe_bus();
    downstream_seq_item item;
    logic [7:0] bytes[$];  // Changed from bit [7:0] to logic [7:0]
    int expected;
    int wait_cycles;

    forever begin
      @(vif.cb_mon); // clcok blccok sync

      // 1. Wait for Notification (NEWDATA_LEN > 0)
      if (vif.cb_mon.newdata_len !== 5'd0) begin
        expected = vif.cb_mon.newdata_len;

        // data length size check
        if (!(expected inside {4, 8, 12, 16})) begin
          `uvm_error("BAD_NDL", $sformatf("Port %0d invalid NEWDATA_LEN %0d", cfg.port_id, expected))
        end else begin
          // setup request item and configure
          item = downstream_seq_item::type_id::create("notification_req");
          item.kind = downstream_seq_item::REQ;
          item.port_id = cfg.port_id;
          item.newdata_len = expected;
          item.reset_count = cfg.reset_count;
          req_ap.write(item); //pull on sequencer
        end

        // 2. Wait for PROCEED pulse (Strictly 1 to 4 cycles delay)
        wait_cycles = 0;

        while (vif.cb_mon.proceed !== 1'b1) begin

          @(vif.cb_mon);
          wait_cycles++;

          // timing Protocol Violation: NEWDATA_LEN pulse lasted longer than 1 clk cycle
          if (wait_cycles == 1 && vif.cb_mon.newdata_len !== 5'd0)
            `uvm_error("NDPULSE", $sformatf("Port %0d NEWDATA_LEN lasted >1 cycle", cfg.port_id))

          // timing Protocol Violation: Overlapping packet requested before PROCEED
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
        bytes.delete( );// clear byte queue
        for (int i = 0; i < expected; i++) begin
          @(vif.cb_mon);

          // Protocol Violation: PROCEED pulse lasted >1 cycle
          if (i == 0 && vif.cb_mon.proceed === 1'b1)
            `uvm_error("PROCPULSE", $sformatf("Port %0d PROCEED lasted >1 cycle", cfg.port_id))

          // Protocol Violation: Overlapping packet requested during payload stream
          if (vif.cb_mon.newdata_len !== 5'd0)
            `uvm_error("OVERLAP", $sformatf("Port %0d got overlapping packet", cfg.port_id))

          bytes.push_back(vif.cb_mon.data_out);  // append the byte in queue
        end

        // 4. Broadcast out the Completed Packet
        item = downstream_seq_item::type_id::create("completed_packet");
        item.kind = downstream_seq_item::RSP;
        item.port_id = cfg.port_id;
        item.newdata_len = expected;
        item.reset_count = cfg.reset_count;
        item.data = bytes; // Direct queue-to-dynamic array assignment

        downstream_txn_ap.write(item); // broadcasting to this port

      end else if (vif.cb_mon.proceed === 1'b1) begin
        // Unexpected PROCEED when no transaction is pending
        `uvm_error("UNEXP_READY", $sformatf("Port %0d unexpected PROCEED", cfg.port_id))
      end
    end
  endtask
endclass
