/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class pdm_upstream_reset_seq extends uvm_sequence #(upstream_seq_item);
  `uvm_object_utils(pdm_upstream_reset_seq)
  bit inject_mid_packet=0;
  function new(string name="pdm_upstream_reset_seq");
    super.new(name);
  endfunction
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
