/* Eric Phong, rfp479, CME435, 11344905, Lab4 */

class pdm_downstream_driver extends uvm_driver #(downstream_seq_item);//extend driver
  `uvm_component_utils(pdm_downstream_driver) //registration with factrory

  // define handles that will be passed to driver
  pdm_downstream_agent_cfg cfg; 
  virtual pdm_downstream_if vif;
  downstream_seq_item active;

  // standard constructor
  function new(string name = "pdm_downstream_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // build phase, try to get config and virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pdm_downstream_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("DNCFG", "downstream cfg missing")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal("DNVIF", "virtual interface missing")
  endfunction

//------------------------------------------------------------------------------
// Task: run_phase
//
// Executes the primary downstream driver run-time loop using an asynchronous
// reset-aware fork/join_any architecture.
//
// Initializes the physical proceed line low, then continuously executes across
// operational reset epochs:
// 1. Awaits DUT reset release (rst_b === 1'b1) before enabling stimulus.
// 2. Concurrently runs linear transaction processing alongside an asynchronous
//    reset monitor. The driving thread fetches sequence items, discards stale 
//    or mismatched transactions from prior reset epochs, injects randomized 
//    backpressure delays, and asserts a single-cycle proceed pulse.
// 3. Catches reset assertions (rst_b === 1'b0) immediately, terminating active 
//    driving threads via disable fork, forcing proceed to 0, and retiring any 
//    in-flight item with item_done() to prevent sequencer lockup.
//
// Parameters:
//   phase - The standard UVM run phase handle used for phasing control
//------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    // clean initial start
    vif.proceed = 0;

    forever begin
      // 1. Wait for the initial reset from the DUT to be done
      wait (vif.rst_b === 1'b1);

      // 2. Concurrently execute transaction driving and reset monitoring
      fork
        // Thread A: line by line transaction processing
        begin
          forever begin
            seq_item_port.get_next_item(active); // pull from sequencer I need to eat more

            // delete old transaction items
            if (active.kind != downstream_seq_item::READY ||
                active.reset_count != cfg.reset_count) 
                begin
                   // clean finish
              seq_item_port.item_done();
              active = null;
              continue;
            end

            // Apply proceed delay
            repeat (active.proceed_delay) @(vif.cb_drv);

            // 1cycle pROCEED pulse
            vif.cb_drv.proceed <= 1'b1;
            @(vif.cb_drv);
            vif.cb_drv.proceed <= 1'b0;

            // clean up
            seq_item_port.item_done();
            active = null;
          end
        end

        // Thread B: Asynchronous reset watcher
        begin
          wait (vif.rst_b === 1'b0);
        end
      join_any

      // 3. Reset happened kill everythign
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