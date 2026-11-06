`ifndef PDM_SANITY_SEQ_SV
`define PDM_SANITY_SEQ_SV

class pdm_sanity_seq extends uvm_sequence #(upstream_seq_item);
    `uvm_object_utils(pdm_sanity_seq)

    function new(string name = "pdm_sanity_seq");
        super.new(name);
    endfunction : new

    virtual task body();
        upstream_seq_item txn;

        `uvm_info(get_type_name(), "Starting directed sanity sequence across Ports 1 to 4", UVM_LOW)

        // Sequentially send one directed packet to each output port (1 to 4)
        for (int port = 1; port <= 4; port++) begin
            txn = upstream_seq_item::type_id::create($sformatf("sanity_txn_p%0d", port));

            start_item(txn);
            if (!txn.randomize() with {
                destination    == port;
                data_len  == (port * 4); // Port 1: 4B, Port 2: 8B, Port 3: 12B, Port 4: 16B
            }) begin
                `uvm_fatal(get_type_name(), $sformatf("Randomization failed for sanity txn to port %0d", port))
            end

            // Populate deterministic test pattern for easy waveform debugging
            foreach (txn.data[idx]) begin
                txn.data[idx] = 8'hA0 + (port << 4) + idx;
            end

            `uvm_info(get_type_name(), 
                      $sformatf("Sending sanity packet to Port %0d (Length: %0d bytes)", 
                                txn.destination, txn.data_len), UVM_MEDIUM)
            finish_item(txn);
        end

        `uvm_info(get_type_name(), "Sanity sequence completed driving all 4 packets", UVM_LOW)
    endtask : body

endclass : pdm_sanity_seq

`endif // PDM_SANITY_SEQ_SV