/* Eric Phong, rfp479, CME435, 11344905, Lab4 */

class pdm_upstream_monitor extends uvm_monitor;

  `uvm_component_utils(pdm_upstream_monitor) // Factory registartion
 
  pdm_upstream_agent_cfg cfg; // get handles ready to import from config 
  virtual pdm_upstream_if vif; 
  uvm_analysis_port #(upstream_seq_item) upstream_txn_ap; 
  uvm_event reset_event;

  // standard constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    upstream_txn_ap = new("upstream_txn_ap", this); //instantiates the upstream transaction analysis port
  endfunction

//------------------------------------------------------------------------------
// Function: build_phase
//
// At zero time, procedurally build, gets config info from upstream agent, 
// gets the virtual interface handle connect global reset event 
//
// Parameters:
//   phase - The standard UVM phase handle for the build phase.
//------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_upstream_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("UPCFG", "upstream cfg missing")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("UPVIF", "virtual interface missing")
    reset_event = uvm_event_pool::get_global("pdm_reset_event");
  endfunction

//------------------------------------------------------------------------------
// Task: run_phase
//
// Waits till end of reset, observes logic along side ansync reset. if there is a reset
// trigger reset event, log it, kill the observing threads before waiting until reset is done
//
// Parameters:
//   phase - The standard UVM run phase handle used for phasing control.
//------------------------------------------------------------------------------
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

//------------------------------------------------------------------------------
// Task: observe_bus
// 
// Passive monitoring of interfaces, enforce timing protocols, handshakes and 
// broadcasts completed packets
//
// The task operates in a persistent loop executing the following protocol steps:
//
// 1. Start-of-Packet Detection - Waits for an asserted boundary pulse (bnd_plse)
//    coincident with Byte 0, instantiates an upstream_seq_item, samples the 
//    target destination port, and validates that it falls in the range [1:4].
//
// 2. Send the packet as long as we are within the allowed 4, 8, 12, or 16 bytes 
// (and flagging packets exceeding 16 bytes).
// 
// 3. ACK check within the 1 to 4 clock cycles following the ending packet pulse.
// 
// 4. TLM Broadcast - send the packet out on upstream_txn_ap analysis port.
//
// Additionally flags protocol errors if an unexpected ACK is sampled without 
// an active packet transfer.
//------------------------------------------------------------------------------
  task observe_bus();
    upstream_seq_item item;
    bit [7:0] bytes[$]; // [$] makes a unbounded queue
    int ack_late;

    forever begin
      @(vif.cb_mon);

      // 1. Wait for Start-of-Packet BND_plse at the same time as start of pactket
      if (vif.cb_mon.bnd_plse === 1'b1) 
      begin
        bytes.delete(); // make sure no left overs from last byte sent
        item = upstream_seq_item::type_id::create("observed_packet"); 
        item.operation   = upstream_seq_item::DATA_TRANSFER;
        item.destination = vif.cb_mon.data_in;

        if (!(item.destination inside {[1:4]}))
          `uvm_error("BAD_DEST", $sformatf("Invalid destination %0d", item.destination)) // destination port is not within the allowed range

        // 2. Keep getting Payload Bytes until end of packet BND_PLSE
        forever begin
          @(vif.cb_mon);// move time forward

          bytes.push_back(vif.cb_mon.data_in);

          if (vif.cb_mon.bnd_plse === 1'b1) break;

          if (bytes.size() > 16) begin
            `uvm_error("PACKET_LONG", "No ending BND_PLSE within 16 data bytes")
            break;
          end
        end

        // Payload length allowed?
        if (!(bytes.size() inside {4, 8, 12, 16}))
          `uvm_error("BAD_LEN", $sformatf("Payload length %0d not permitted", bytes.size()))

        item.data_len = bytes.size();
        item.data     = bytes; // Direct queue-to-dynamic array assignment

        // 3. Check for ACK (1 to 4 clock cycles)
        ack_late = 0;
        while (vif.cb_mon.ack !== 1'b1) begin
          @(vif.cb_mon);
          ack_late++;
          if (ack_late > 4) begin
            `uvm_error("ACKTIME", "No ACK within four cycles after final BND_PLSE")
            break;
          end
        end
        
        // broadcast that packet is done
        upstream_txn_ap.write(item);
      end 
      
      else if (vif.cb_mon.ack === 1'b1) // ack to early
      begin
        `uvm_error("ACKEXTRA", "Unexpected ACK without a completed packet")
      end
    end

  endtask
endclass