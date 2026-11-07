/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_driver extends uvm_driver #(upstream_seq_item); // extend uvm driver

  `uvm_component_utils(pdm_upstream_driver) // Factory registration

  pdm_upstream_agent_cfg cfg; // Agent config class
  virtual pdm_upstream_if vif; // Virtual interface class

  typedef enum {IDLE, DEST, PAYLOAD, WAIT_ACK, RESET_HOLD} state_e;
  state_e state = IDLE;

  upstream_seq_item active;
  
  int unsigned byte_idx, ack_wait, hold_left;
  
  bit reset_started;

  // Constructor
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
/*------------------------------------------------------------------------------
Function: build_phase
Description: Gets agent config from config database and gets the virtual 
interface handle

Parameter: phase - Current UVM phase context
------------------------------------------------------------------------------*/
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_upstream_agent_cfg)::get(this,"","cfg",cfg)) 
      `uvm_fatal("UPCFG","upstream cfg missing")
    vif = cfg.vif;
    if (vif == null) `uvm_fatal("UPVIF","upstream virtual interface missing") 
  endfunction

/*------------------------------------------------------------------------------
Function: finish_item
Description: On a active item tell the sequence the driver is done with this item
------------------------------------------------------------------------------*/
  task finish_item();
    if (active != null) begin
      seq_item_port.item_done();
      active = null;
    end
    state = IDLE;
  endtask

/*------------------------------------------------------------------------------
Function: watch_async_reset
Description: Looks out for when a active low async reset, set output pins to 
zero, call finish item

------------------------------------------------------------------------------*/  
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

/*------------------------------------------------------------------------------
Function: drive_bus
Description: initial reset, TLM pull from squencer constantly, if we get a sequence
  item we take a look at what operation it wants to do

------------------------------------------------------------------------------*/  
  // task drive_bus();
    
  //   drive_reset(2); // assert active low reset on rst_b for 2 clcok cycles for initial startup

  //   forever begin
  //     seq_item_port.get_next_item(active); // TLM pulling from sequencer

  //     case (active.operation) // check what operation is in the sequence item
  //       upstream_seq_item::RESET: // do a reset
  //       begin
  //         drive_reset(active.reset_cycles); // do the reset
  //       end

  //       upstream_seq_item::MID_TRANSFER_RESET, // do mid transfer reset or data transfer
  //       upstream_seq_item::DATA_TRANSFER: 
  //       begin
  //         drive_packet(active);  // send the packet
  //       end
  //     endcase

  //     seq_item_port.item_done(); // tell sequencer I'm done with the sent sequence item clean up time 
  //     active = null; // clean up active for next seq item
  //   end
  // endtask

task drive_bus();
    // Single source for asynchronous, active-low reset.
    vif.rst_b = 0;
    vif.data_in = 0;
    vif.bnd_plse = 0;

    // Bring DUT out of initial reset even when no stimulus sequence is running.
    repeat (2) @(vif.cb_drv);
    vif.rst_b = 1;

    forever begin
      @(vif.cb_drv);

      if (state == IDLE) begin
        active = null;
        seq_item_port.try_next_item(active);
        if (active != null) begin
          if (active.operation == upstream_seq_item::RESET) begin
            state = RESET_HOLD;
            hold_left = active.reset_cycles;
            reset_started = 0;
          end else begin
            state = DEST;
          end
          // Prevents the FSM from immediately dropping into 'case (state)'
          // during the same cycle the item was fetched.
          continue;
        end
      end

      case (state)
        IDLE: begin
          vif.cb_drv.bnd_plse <= 0;
          vif.cb_drv.data_in  <= 0;
        end

        DEST: begin
          if (vif.rst_b !== 1'b1) 
            `uvm_fatal("UPRESET", "Send operation started before reset release")
          vif.cb_drv.bnd_plse <= 1;
          vif.cb_drv.data_in  <= active.destination;
          byte_idx = 0;
          state = PAYLOAD;
        end

        PAYLOAD: begin
          vif.cb_drv.data_in  <= active.data[byte_idx];
          vif.cb_drv.bnd_plse <= (byte_idx == active.data_len - 1);
          byte_idx++;
          if (active.operation == upstream_seq_item::MID_TRANSFER_RESET && byte_idx == active.reset_after_bytes) begin
            state = RESET_HOLD;
            hold_left = active.reset_cycles;
            reset_started = 0;
          end else if (byte_idx == active.data_len) begin
            state = WAIT_ACK;
            ack_wait = 0;
          end
        end

        WAIT_ACK: begin
          vif.cb_drv.bnd_plse <= 0;
          vif.cb_drv.data_in  <= 0;
          if (vif.ack === 1'b1) begin
            finish_item();
          end else begin
            ack_wait++;
            if (ack_wait > 6) begin
              `uvm_error("NOACK", "Timed out waiting for upstream ACK")
              finish_item();
            end
          end
        end

        RESET_HOLD: begin
          vif.cb_drv.bnd_plse <= 0;
          vif.cb_drv.data_in  <= 0;
          if (!reset_started) begin
            vif.rst_b = 0;
            reset_started = 1;
          end else if (hold_left > 1) begin
            hold_left--;
          end else begin
            vif.rst_b = 1;
            finish_item();
          end
        end
      endcase
    end
  endtask

/**
 * @brief Drives an upstream packet or injects a mid-transfer reset.
 *
 * Checks reset status, transmits Byte 0 (destination) coincident with bnd_plse,
 * streams payload bytes with terminating bnd_plse framing, handles mid-transfer
 * reset aborts, and awaits DUT ACK (timing out after 6 cycles).
 *
 * @param item Upstream transaction item containing framing attributes, payload,
 *             and reset injection parameters.
 */
  task drive_packet(upstream_seq_item item); 

    if (vif.rst_b !== 1'b1) // is reset done?
      `uvm_fatal("UPRESET", "Send operation started before reset release")

    // Destination byte output ports (1,2,3,4)
    vif.cb_drv.bnd_plse <= 1'b1; // signal to dut that hey I'm starting to send a packet
    vif.cb_drv.data_in  <= item.destination;

    @(vif.cb_drv); // move forward one clock cycle

    // Payload Bytes
    for (int i = 0; i < item.data_len; i++) 
    begin
      // Handle mid-transfer reset injection
      if (item.operation == upstream_seq_item::MID_TRANSFER_RESET && i == item.reset_after_bytes) 
          begin
        drive_reset(item.reset_cycles); // do reset based on when it should happen mid transfer
        return;
      end

      // Do the transfer
      vif.cb_drv.data_in  <= item.data[i]; 
      // count down to signal when I'm about to send the final byte of my packet
      vif.cb_drv.bnd_plse <= (i == item.data_len - 1); 
      @(vif.cb_drv); // move foward 1 clock cycle
      
    end // for loop done

    // Clear bus and wait for ACK (up to 6 cycles +2 more for safety of margin)
    vif.cb_drv.bnd_plse <= 1'b0;
    vif.cb_drv.data_in  <= '0;

    repeat (6) begin
      @(vif.cb_drv);
      if (vif.ack === 1'b1) return;
    end
    // if we got here then the DUT has failed us
    `uvm_error("NOACK", "Timed out waiting 1for upstream ACK") 
  endtask

//  * @brief Drives an upstream packet or injects a mid-transfer reset.
//  *
//  * Checks reset status, transmits Byte 0 (destination) coincident with bnd_plse,
//  * streams payload bytes with terminating bnd_plse framing, handles mid-transfer
//  * reset aborts, and awaits DUT ACK (timing out after 6 cycles).
//  *
//  * @param item Upstream transaction item containing framing attributes, payload,
//  *             and reset injection parameters.
  task drive_reset(int unsigned cycles);
    // set all inputs to the dut to zero 
    vif.cb_drv.bnd_plse <= 1'b0;
    vif.cb_drv.data_in  <= '0;
    vif.rst_b = 1'b0; // sending in the active low async reset
    // telling the dut when to be done with the reset
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
