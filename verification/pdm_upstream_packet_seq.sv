/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_packet_seq extends uvm_sequence #(upstream_seq_item); // extend and input empty sequence

  `uvm_object_utils(pdm_upstream_packet_seq) // factory registration
  int unsigned num_packets=5;
  
  //std constructor
  function new(string name="pdm_upstream_packet_seq");
    super.new(name);
  endfunction
  
  
  task body();
    upstream_seq_item pkt; // repeat create number of empty packets needed
  
    repeat (num_packets) // repeat the below based on the need number of packets
    begin
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
