// /* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
// class pdm_downstream_driver extends uvm_driver #(downstream_seq_item);
//   `uvm_component_utils(pdm_downstream_driver)
//   pdm_downstream_agent_cfg cfg;
//   virtual pdm_downstream_if vif;
//   downstream_seq_item active;
//   int unsigned ticks_left;
//   bit pulse_active;

//   function new(string name,uvm_component parent);
//     super.new(name,parent);
//   endfunction
//   function void build_phase(uvm_phase phase);
//     super.build_phase(phase);
//     if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this,"","cfg",cfg))
//       `uvm_fatal("DNCFG","downstream cfg missing")
//     vif=cfg.vif;
//     if (vif==null) `uvm_fatal("DNVIF","virtual interface missing")
//   endfunction

//   task run_phase(uvm_phase phase);
//     vif.proceed=0;
//     forever begin
//       // Wake immediately on an asynchronous reset or on the drive edge.
//       @(negedge vif.clk or negedge vif.rst_b);
//       if (vif.rst_b !== 1'b1) begin
//         // Raw write is required for immediate asynchronous deassertion.
//         vif.proceed=0;
//         if (active != null) begin
//           seq_item_port.item_done();
//           active=null;
//         end
//         pulse_active=0;
//         ticks_left=0;
//         continue;
//       end
//       if (pulse_active) begin
//         vif.cb_drv.proceed <= 0;
//         pulse_active=0;
//         seq_item_port.item_done();
//         active=null;
//         continue;
//       end
//       if (active == null) begin
//         seq_item_port.try_next_item(active);
//         if (active != null) begin
//           if (active.kind != downstream_seq_item::READY ||
//               active.reset_count != cfg.reset_count) begin
//             seq_item_port.item_done();
//             active=null;
//           end else begin
//             ticks_left=active.proceed_delay;
//           end
//         end
//       end
//       if (active != null) begin
//         if (ticks_left > 0) ticks_left--;
//         if (ticks_left==0) begin
//           vif.cb_drv.proceed <= 1;
//           pulse_active=1;
//         end else vif.cb_drv.proceed <= 0;
//       end else vif.cb_drv.proceed <= 0;
//     end
//   endtask
// endclass


/* Eric Phong, rfp479, CME435, 11344905, Lab4 */

class pdm_downstream_driver extends uvm_driver #(downstream_seq_item);
  `uvm_component_utils(pdm_downstream_driver)

  pdm_downstream_agent_cfg cfg;
  virtual pdm_downstream_if vif;
  downstream_seq_item active;

  function new(string name = "pdm_downstream_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("DNCFG", "downstream cfg missing")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("DNVIF", "virtual interface missing")
  endfunction

  task run_phase(uvm_phase phase);
    // Raw write to ensure clean initial bus state
    vif.proceed = 0;

    forever begin
      // 1. Wait for DUT to come out of active-low reset
      wait (vif.rst_b === 1'b1);

      // 2. Concurrently execute transaction driving and reset monitoring
      fork
        // Thread A: Linear transaction processing
        begin
          forever begin
            seq_item_port.get_next_item(active);

            // Discard stale transactions from previous reset epochs or non-READY items
            if (active.kind != downstream_seq_item::READY ||
                active.reset_count != cfg.reset_count) begin
              seq_item_port.item_done();
              active = null;
              continue;
            end

            // Apply backpressure delay
            repeat (active.proceed_delay) @(vif.cb_drv);

            // Single-cycle PROCEED pulse
            vif.cb_drv.proceed <= 1'b1;
            @(vif.cb_drv);
            vif.cb_drv.proceed <= 1'b0;

            // Handshake completion
            seq_item_port.item_done();
            active = null;
          end
        end

        // Thread B: Asynchronous reset detector
        begin
          wait (vif.rst_b === 1'b0);
        end
      join_any

      // 3. Reset occurred: terminate active driving thread immediately
      disable fork;

      // Asynchronous deassertion and cleanup
      vif.proceed = 0;
      if (active != null) begin
        seq_item_port.item_done();
        active = null;
      end
    end
  endtask
endclass