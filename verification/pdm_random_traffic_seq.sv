`ifndef PDM_RANDOM_TRAFFIC_SEQ_SV
`define PDM_RANDOM_TRAFFIC_SEQ_SV

class pdm_random_traffic_seq extends uvm_sequence #(upstream_seq_item);
  `uvm_object_utils(pdm_random_traffic_seq)

  rand int unsigned count;

  constraint count_c {
    soft count inside {[15 : 25]};
  }

  function new(string name = "pdm_random_traffic_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    upstream_seq_item pkt;

    `uvm_info(get_type_name(), $sformatf("Generating %0d constrained-random packets", count), UVM_LOW)

    repeat (count) begin
      pkt = upstream_seq_item::type_id::create("rand_pkt");
      start_item(pkt);
      if (!pkt.randomize() with {
        operation == upstream_seq_item::DATA_TRANSFER;
      }) `uvm_fatal("SEQRAND", "Randomization failed for random traffic item")
      finish_item(pkt);
    end
  endtask : body

endclass : pdm_random_traffic_seq

`endif // PDM_RANDOM_TRAFFIC_SEQ_SV