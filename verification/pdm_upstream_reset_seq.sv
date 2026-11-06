/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
 // base sequence for basic a resets and initial startup for DUT
class pdm_upstream_reset_seq extends uvm_sequence #(upstream_seq_item); // extend sequence item input a upstream seq item to format

  `uvm_object_utils(pdm_upstream_reset_seq) //factory registration

  bit inject_mid_packet=0;

  /// std constructor
  function new(string name="pdm_upstream_reset_seq");
    super.new(name);
  endfunction
  
  //input reset sequence into given empty sequence item
  task body();
    upstream_seq_item req;
    req=upstream_seq_item::type_id::create("reset_req");

    start_item(req);
    if (inject_mid_packet) begin
      if (!req.randomize() with { operation == MID_TRANSFER_RESET; })
        `uvm_fatal("RSTRAND","Cannot randomize mid-packet reset")
    end else begin
      if (!req.randomize() with { operation == RESET; })
        `uvm_fatal("RSTRAND","Cannot randomize standalone reset")
    end
    finish_item(req);
  endtask
endclass
