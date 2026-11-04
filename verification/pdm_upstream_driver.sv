/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_driver extends uvm_driver #(upstream_seq_item); // extend uvm driver

  `uvm_component_utils(pdm_upstream_driver) // Factory registration

  pdm_upstream_agent_cfg cfg;
  virtual pdm_upstream_if vif;

  typedef enum {IDLE, DEST, PAYLOAD, WAIT_ACK, RESET_HOLD} state_e;
  state_e state = IDLE;

  upstream_seq_item active;
  
  int unsigned byte_idx, ack_wait, hold_left;
  
  bit reset_started;

  // Constructor
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  // Builder
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_upstream_agent_cfg)::get(this,"","cfg",cfg)) // Config check
      `uvm_fatal("UPCFG","upstream cfg missing")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("UPVIF","upstream virtual interface missing") // Virtual interface check
  endfunction

  // Call only if a sequence item has actually been fetched.
  task finish_item();
    if (active != null) begin
      seq_item_port.item_done();
      active = null;
    end
    state = IDLE;
  endtask

  // Async reset
  task watch_async_reset();
    forever begin
      @(negedge vif.rst_b);
      // Do not abort a reset transaction intentionally initiated by this driver.
      if (state != RESET_HOLD && active != null) begin
        `uvm_warning("UP_ABORT", "Active upstream packet aborted by asynchronous reset")
        vif.bnd_plse = 0;
        vif.data_in = 0;
        finish_item();
      end
    end
  endtask


  // task drive_bus();
  //   // Single source for asynchronous, active-low reset.
  //   vif.rst_b = 0;
  //   vif.data_in = 0;
  //   vif.bnd_plse = 0;
  //   // Bring DUT out of initial reset even when no stimulus sequence is running.
  //   repeat (2) @(vif.cb_drv);
  //   vif.rst_b = 1;
  //   forever begin
  //     @(vif.cb_drv);
  //     if (state == IDLE) begin
  //       // Non-blocking polling: keeps the driver clock-sensitive.
  //       active = null;
  //       seq_item_port.try_next_item(active);
  //       if (active != null) begin
  //         if (active.operation == upstream_seq_item::RESET) begin
  //           state = RESET_HOLD;
  //           hold_left = active.reset_cycles;
  //           reset_started = 0;
  //         end else state = DEST;
  //       end
  //     end
  //     case (state)
  //       IDLE: begin
  //         vif.cb_drv.bnd_plse <= 0;
  //         vif.cb_drv.data_in  <= 0;
  //       end
  //       DEST: begin
  //         if (vif.rst_b !== 1'b1)
  //           `uvm_fatal("UPRESET","Send operation started before reset release")
  //         vif.cb_drv.bnd_plse <= 1;
  //         vif.cb_drv.data_in  <= active.destination;
  //         byte_idx = 0;
  //         state = PAYLOAD;
  //       end
  //       PAYLOAD: begin
  //         vif.cb_drv.data_in <= active.data[byte_idx];
  //         vif.cb_drv.bnd_plse <= (byte_idx == active.data_len-1);
  //         byte_idx++;
  //         if (active.operation == upstream_seq_item::MID_TRANSFER_RESET &&
  //             byte_idx == active.reset_after_bytes) begin
  //           state = RESET_HOLD;
  //           hold_left = active.reset_cycles;
  //           reset_started = 0;
  //         end else if (byte_idx == active.data_len) begin
  //           state = WAIT_ACK;
  //           ack_wait = 0;
  //         end
  //       end
  //       WAIT_ACK: begin
  //         vif.cb_drv.bnd_plse <= 0;
  //         vif.cb_drv.data_in <= 0;
  //         if (vif.ack === 1'b1) begin
  //           finish_item();
  //         end else begin
  //           ack_wait++;
  //           // Monitor performs the strict 1..4 cycle ACK timing check.
  //           if (ack_wait > 6) begin
  //             `uvm_error("NOACK","Timed out waiting for upstream ACK")
  //             finish_item();
  //           end
  //         end
  //       end
  //       RESET_HOLD: begin
  //         vif.cb_drv.bnd_plse <= 0;
  //         vif.cb_drv.data_in <= 0;
  //         if (!reset_started) begin
  //           vif.rst_b = 0;
  //           reset_started = 1;
  //         end else if (hold_left > 1) begin
  //           hold_left--;
  //         end else begin
  //           vif.rst_b = 1;
  //           finish_item();
  //         end
  //       end
  //     endcase
  //   end
  // endtask

  task drive_bus();
    // Initial hardware reset
    drive_reset(2);

    forever begin
      seq_item_port.get_next_item(active);

      case (active.operation)
        upstream_seq_item::RESET: begin
          drive_reset(active.reset_cycles);
        end

        upstream_seq_item::MID_TRANSFER_RESET,
        upstream_seq_item::DATA_TRANSFER: begin
          drive_packet(active);
        end
      endcase

      seq_item_port.item_done();
      active = null;
    end
  endtask

  task drive_packet(upstream_seq_item item);
    if (vif.rst_b !== 1'b1)
      `uvm_fatal("UPRESET", "Send operation started before reset release")

    // Byte 0: Destination
    vif.cb_drv.bnd_plse <= 1'b1;
    vif.cb_drv.data_in  <= item.destination;
    @(vif.cb_drv);

    // Payload Bytes
    for (int i = 0; i < item.data_len; i++) begin
      // Handle mid-transfer reset injection
      if (item.operation == upstream_seq_item::MID_TRANSFER_RESET &&
          i == item.reset_after_bytes) begin
        drive_reset(item.reset_cycles);
        return;
      end

      vif.cb_drv.data_in  <= item.data[i];
      vif.cb_drv.bnd_plse <= (i == item.data_len - 1);
      @(vif.cb_drv);
    end

    // Clear bus and wait for ACK (up to 6 cycles)
    vif.cb_drv.bnd_plse <= 1'b0;
    vif.cb_drv.data_in  <= '0;

    repeat (6) begin
      @(vif.cb_drv);
      if (vif.ack === 1'b1) return;
    end

    `uvm_error("NOACK", "Timed out waiting for upstream ACK")
  endtask

  task drive_reset(int unsigned cycles);
    vif.cb_drv.bnd_plse <= 1'b0;
    vif.cb_drv.data_in  <= '0;
    vif.rst_b = 1'b0;
    repeat (cycles) @(vif.cb_drv);
    vif.rst_b = 1'b1;
  endtask

  // Run our main stuff
  task run_phase(uvm_phase phase);
    fork
      watch_async_reset();
      drive_bus();
    join
  endtask

endclass
