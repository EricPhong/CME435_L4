`ifndef PDM_SATURATION_SEQ_SV
`define PDM_SATURATION_SEQ_SV

class pdm_saturation_seq extends uvm_sequence #(upstream_seq_item);
  `uvm_object_utils(pdm_saturation_seq)

  rand int unsigned burst_size;

  constraint burst_size_c {
    soft burst_size inside {[20 : 40]};
  }

  function new(string name = "pdm_saturation_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    upstream_seq_item pkt;

    `uvm_info(get_type_name(), $sformatf("Launching saturation burst of %0d back-to-back packets", burst_size), UVM_LOW)

    for (int i = 0; i < burst_size; i++) begin
      pkt = upstream_seq_item::type_id::create($sformatf("sat_pkt_%0d", i));
      start_item(pkt);

      // Force zero inter-packet idle delay and round-robin targeting across all ports
      if (!pkt.randomize() with {
        operation       == upstream_seq_item::DATA_TRANSFER;
        destination     == (i % 4) + 1; // Round-robin to distribute stress evenly across channels
        inter_pkt_delay == 0;          // Back-to-back injection immediately following ACK
      }) begin
        `uvm_fatal("SEQRAND", "Failed to randomize saturation transaction")
      end

      finish_item(pkt);
    end

    `uvm_info(get_type_name(), "Completed saturation burst generation", UVM_LOW)
  endtask : body

endclass : pdm_saturation_seq

`endif // PDM_SATURATION_SEQ_SV