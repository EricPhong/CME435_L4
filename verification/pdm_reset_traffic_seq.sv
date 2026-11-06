`ifndef PDM_RESET_TRAFFIC_SEQ_SV
`define PDM_RESET_TRAFFIC_SEQ_SV

class pdm_reset_traffic_seq extends uvm_sequence #(upstream_seq_item);
  `uvm_object_utils(pdm_reset_traffic_seq)

  rand int unsigned iterations;

  constraint iter_c {
    soft iterations inside {[3 : 6]};
  }

  function new(string name = "pdm_reset_traffic_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    upstream_seq_item req;

    `uvm_info(get_type_name(), "Starting asynchronous reset test sequence", UVM_LOW)

    for (int iter = 0; iter < iterations; iter++) begin
      // -----------------------------------------------------------------------
      // Scenario A: Asynchronous Reset BETWEEN Packets (Idle Reset)
      // -----------------------------------------------------------------------
      `uvm_info(get_type_name(), $sformatf("[Iter %0d] Step 1: Sending pre-reset packet", iter), UVM_MEDIUM)
      req = upstream_seq_item::type_id::create("pre_rst_pkt");
      start_item(req);
      if (!req.randomize() with { operation == upstream_seq_item::DATA_TRANSFER; })
        `uvm_fatal("SEQRAND", "Randomization failed for pre-reset packet")
      finish_item(req);

      `uvm_info(get_type_name(), $sformatf("[Iter %0d] Step 2: Injecting standalone reset between packets", iter), UVM_LOW)
      req = upstream_seq_item::type_id::create("standalone_reset");
      start_item(req);
      if (!req.randomize() with {
        operation    == upstream_seq_item::RESET;
        reset_cycles inside {[2 : 4]};
      }) `uvm_fatal("SEQRAND", "Randomization failed for standalone reset")
      finish_item(req);

      `uvm_info(get_type_name(), $sformatf("[Iter %0d] Step 3: Verifying recovery post-standalone reset", iter), UVM_MEDIUM)
      req = upstream_seq_item::type_id::create("post_rst_recovery_pkt");
      start_item(req);
      if (!req.randomize() with { operation == upstream_seq_item::DATA_TRANSFER; })
        `uvm_fatal("SEQRAND", "Randomization failed for recovery packet")
      finish_item(req);

      // -----------------------------------------------------------------------
      // Scenario B: Asynchronous Reset DURING a Packet (Mid-Transfer Abort)
      // -----------------------------------------------------------------------
      `uvm_info(get_type_name(), $sformatf("[Iter %0d] Step 4: Injecting mid-transfer reset", iter), UVM_LOW)
      req = upstream_seq_item::type_id::create("mid_transfer_rst_pkt");
      start_item(req);
      if (!req.randomize() with {
        operation         == upstream_seq_item::MID_TRANSFER_RESET;
        data_len          inside {8, 12, 16};
        reset_after_bytes inside {[2 : data_len - 2]}; // Abort strictly inside the payload body
        reset_cycles      inside {[2 : 4]};
      }) `uvm_fatal("SEQRAND", "Randomization failed for mid-transfer reset")
      finish_item(req);

      `uvm_info(get_type_name(), $sformatf("[Iter %0d] Step 5: Verifying clean recovery post-abort", iter), UVM_MEDIUM)
      req = upstream_seq_item::type_id::create("post_abort_recovery_pkt");
      start_item(req);
      if (!req.randomize() with {
        operation == upstream_seq_item::DATA_TRANSFER;
        data_len  == 4; // Short packet to confirm rapid datapath recovery
      }) `uvm_fatal("SEQRAND", "Randomization failed for post-abort recovery packet")
      finish_item(req);
    end

    `uvm_info(get_type_name(), "Completed asynchronous reset sequence", UVM_LOW)
  endtask : body

endclass : pdm_reset_traffic_seq

`endif // PDM_RESET_TRAFFIC_SEQ_SV