/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
class upstream_seq_item extends uvm_sequence_item; //extend

  // defines some most likely test cases
  typedef enum {
  DATA_TRANSFER, // Normal
  RESET,  // Reset during no sending
  MID_TRANSFER_RESET // middle of transfer reset
  } operation_e;
 
  rand operation_e operation; // random scenarios of normal operation and midsend reset
  rand bit [7:0] destination; //which output port we are sending to
  rand bit [7:0] data[]; // The the 8 bit byte marked data
  rand int unsigned data_len; // total number of bytes
  
  // Number of data bytes that need to be sent before asserting a reset.
  rand int unsigned reset_after_bytes; 
  rand int unsigned reset_cycles;


  constraint normal_packet_constraint {
    destination inside {[8'h01:8'h04]}; // constrains the possible destiations to only the 4 places in byte form
    data_len inside {4,8,12,16}; // allows only the supported variable packet lengths
    data.size() == data_len; // set the size of data based on the random generated value
  }

  constraint reset_constraint {
    // Reset duration not specified by the VerDoc.
    reset_cycles inside {[2:4]};   //but I have it set to 2 to 4 clock cycles 
    if (operation == MID_TRANSFER_RESET)
      reset_after_bytes inside {[1:data_len-1]}; // Reset only after atleast one byte has come through and its not the last one
    else reset_after_bytes == 0; // for regular operation
  }

  `uvm_object_utils_begin(upstream_seq_item) // Factory registration and Enable all
    `uvm_field_enum(operation_e, operation, UVM_ALL_ON)
    `uvm_field_int(destination, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
    `uvm_field_int(data_len, UVM_ALL_ON)
    `uvm_field_int(reset_after_bytes, UVM_ALL_ON)
    `uvm_field_int(reset_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new(string name="upstream_seq_item");
    super.new(name);
  endfunction
endclass
