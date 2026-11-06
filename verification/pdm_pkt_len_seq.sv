`ifndef PDM_PKT_LEN_SEQ_SV
`define PDM_PKT_LEN_SEQ_SV

class pdm_pkt_len_seq extends uvm_sequence #(upstream_seq_item);
  `uvm_object_utils(pdm_pkt_len_seq)

  typedef enum { SWEEP_ALL, CORNER_MIN_MAX, RANDOM_DIST } len_test_mode_e;

  rand len_test_mode_e mode;
  rand int unsigned    num_packets;
  rand bit [7:0]       target_dest;

  constraint default_seq_c {
    soft mode        == SWEEP_ALL;
    soft num_packets == 16;
    soft target_dest inside {[8'h01 : 8'h04]};
  }

  function new(string name = "pdm_pkt_len_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    upstream_seq_item pkt;
    int valid_lengths[4] = '{4, 8, 12, 16};

    `uvm_info(get_type_name(), $sformatf("Starting packet length test sequence in mode %s", mode.name()), UVM_LOW)

    case (mode)
      SWEEP_ALL: begin
        // Sequentially test every payload length on each of the 4 ports
        for (int p = 1; p <= 4; p++) begin
          foreach (valid_lengths[l]) begin
            pkt = upstream_seq_item::type_id::create($sformatf("len_sweep_p%0d_l%0d", p, valid_lengths[l]));
            start_item(pkt);
            if (!pkt.randomize() with {
              operation   == upstream_seq_item::DATA_TRANSFER;
              destination == p;
              data_len    == valid_lengths[l];
            }) `uvm_fatal("SEQRAND", "Failed to randomize sweep transaction")
            finish_item(pkt);
          end
        end
      end

      CORNER_MIN_MAX: begin
        // Focus strictly on min (4-byte) and max (16-byte) boundary lengths
        for (int i = 0; i < num_packets; i++) begin
          pkt = upstream_seq_item::type_id::create($sformatf("corner_pkt_%0d", i));
          start_item(pkt);
          if (!pkt.randomize() with {
            operation == upstream_seq_item::DATA_TRANSFER;
            data_len dist { 4 := 50, 16 := 50 }; // 50/50 corner-case distribution
          }) `uvm_fatal("SEQRAND", "Failed to randomize corner-case length transaction")
          finish_item(pkt);
        end
      end

      RANDOM_DIST: begin
        // Uniform random distribution across all supported sizes
        for (int i = 0; i < num_packets; i++) begin
          pkt = upstream_seq_item::type_id::create($sformatf("rand_len_pkt_%0d", i));
          start_item(pkt);
          if (!pkt.randomize() with {
            operation == upstream_seq_item::DATA_TRANSFER;
            data_len dist { 4 :/ 25, 8 :/ 25, 12 :/ 25, 16 :/ 25 };
          }) `uvm_fatal("SEQRAND", "Failed to randomize random length transaction")
          finish_item(pkt);
        end
      end
    endcase
  endtask : body

endclass : pdm_pkt_len_seq

`endif // PDM_PKT_LEN_SEQ_SV