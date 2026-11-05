/* Eric Phong, rfp479, CME435, 11344905, Lab4 */

class pdm_upstream_monitor extends uvm_monitor;
  `uvm_component_utils(pdm_upstream_monitor)

  pdm_upstream_agent_cfg cfg;
  virtual pdm_upstream_if vif;
  uvm_analysis_port #(upstream_seq_item) upstream_txn_ap;
  uvm_event reset_event;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    upstream_txn_ap = new("upstream_txn_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_upstream_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("UPCFG", "upstream cfg missing")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("UPVIF", "virtual interface missing")
    reset_event = uvm_event_pool::get_global("pdm_reset_event");
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      wait (vif.rst_b === 1'b1);
      fork
        observe_bus();
        begin
          @(negedge vif.rst_b);
          reset_event.trigger();
          `uvm_info("PDM_RST", "Asynchronous reset observed", UVM_MEDIUM)
        end
      join_any
      disable fork; // Automatically kills observe_bus and clears execution state
    end
  endtask

  task observe_bus();
    upstream_seq_item item;
    bit [7:0] bytes[$];
    int ack_latency;

    forever begin
      @(vif.cb_mon);

      // 1. Wait for Start-of-Packet (BND_PLSE coincident with Destination Byte)
      if (vif.cb_mon.bnd_plse === 1'b1) begin
        bytes.delete();
        item = upstream_seq_item::type_id::create("observed_packet");
        item.operation   = upstream_seq_item::DATA_TRANSFER;
        item.destination = vif.cb_mon.data_in;

        if (!(item.destination inside {[1:4]}))
          `uvm_error("BAD_DEST", $sformatf("Invalid destination %0d", item.destination))

        // 2. Stream Payload Bytes until terminating BND_PLSE
        forever begin
          @(vif.cb_mon);
          bytes.push_back(vif.cb_mon.data_in);

          if (vif.cb_mon.bnd_plse === 1'b1) break;

          if (bytes.size() > 16) begin
            `uvm_error("PACKET_LONG", "No terminating BND_PLSE within 16 data bytes")
            break;
          end
        end

        // Validate payload length
        if (!(bytes.size() inside {4, 8, 12, 16}))
          `uvm_error("BAD_LEN", $sformatf("Payload length %0d not permitted", bytes.size()))

        item.data_len = bytes.size();
        item.data     = bytes; // Direct queue-to-dynamic array assignment

        // 3. Validate ACK Window (1 to 4 clock cycles)
        ack_latency = 0;
        while (vif.cb_mon.ack !== 1'b1) begin
          @(vif.cb_mon);
          ack_latency++;
          if (ack_latency > 4) begin
            `uvm_error("ACKTIME", "No ACK within four cycles after final BND_PLSE")
            break;
          end
        end

        upstream_txn_ap.write(item);
      end else if (vif.cb_mon.ack === 1'b1) begin
        `uvm_error("ACKEXTRA", "Unexpected ACK without a completed packet")
      end
    end
  endtask
endclass