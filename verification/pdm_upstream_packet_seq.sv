/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_packet_seq extends uvm_sequence #(upstream_seq_item);
  `uvm_object_utils(pdm_upstream_packet_seq)
  int unsigned num_packets=5;
  function new(string name="pdm_upstream_packet_seq");
    super.new(name);
  endfunction
  task body();
    upstream_seq_item pkt;
    repeat (num_packets) begin
      pkt=upstream_seq_item::type_id::create("pkt");
      start_item(pkt);
      if (!pkt.randomize() with { operation == DATA_TRANSFER; })
        `uvm_fatal("UPRAND","Cannot randomize upstream packet")
      finish_item(pkt);
      `uvm_info("PACKET",$sformatf("Sent packet dest=%0d length=%0d",
                                   pkt.destination,pkt.data_len),UVM_LOW)
    end
  endtask
endclass
