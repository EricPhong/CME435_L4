/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class downstream_seq_item extends uvm_sequence_item;

  // RRequest notification from DUT; 
  // READY: driver acknowledgement
  //; RSP: completed packet.
  typedef enum {REQ, READY, RSP} kind_e;

  kind_e kind;
  int unsigned port_id;
  int unsigned reset_epoch;
  logic [4:0] newdata_len;
  logic [7:0] data[];
  rand int unsigned proceed_delay;

  constraint response_delay_c { proceed_delay inside {[1:4]}; }

  `uvm_object_utils_begin(downstream_seq_item)
    `uvm_field_enum(kind_e, kind, UVM_ALL_ON)
    `uvm_field_int(port_id, UVM_ALL_ON)
    `uvm_field_int(reset_epoch, UVM_ALL_ON)
    `uvm_field_int(newdata_len, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
    `uvm_field_int(proceed_delay, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="downstream_seq_item");
    super.new(name);
  endfunction
endclass
