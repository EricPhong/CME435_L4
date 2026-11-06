/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
// class upstream_seq_item extends uvm_sequence_item; //extend

//   // defines some most likely test cases
//   typedef enum {
//   DATA_TRANSFER, // Normal
//   RESET,  // Reset during no sending
//   MID_TRANSFER_RESET // middle of transfer reset
//   } operation_e;
 
//   rand operation_e operation; // random scenarios of normal operation and midsend reset
//   rand bit [7:0] destination; //which output port we are sending to
//   rand bit [7:0] data[]; // The the 8 bit byte marked data
//   rand int unsigned data_len; // total number of bytes
  
//   // Number of data bytes that need to be sent before asserting a reset.
//   rand int unsigned reset_after_bytes; 
//   rand int unsigned reset_cycles;


//   constraint normal_packet_constraint {
//     destination inside {[8'h01:8'h04]}; // constrains the possible destiations to only the 4 places in byte form
//     data_len inside {4,8,12,16}; // allows only the supported variable packet lengths
//     data.size() == data_len; // set the size of data based on the random generated value
//   }

//   constraint reset_constraint {
//     // Reset duration not specified by the VerDoc.
//     reset_cycles inside {[2:4]};   //but I have it set to 2 to 4 clock cycles 
//     if (operation == MID_TRANSFER_RESET)
//       reset_after_bytes inside {[1:data_len-1]}; // Reset only after atleast one byte has come through and its not the last one
//     else reset_after_bytes == 0; // for regular operation
//   }

//   `uvm_object_utils_begin(upstream_seq_item) // Factory registration and Enable all
//     `uvm_field_enum(operation_e, operation, UVM_ALL_ON)
//     `uvm_field_int(destination, UVM_ALL_ON)
//     `uvm_field_array_int(data, UVM_ALL_ON)
//     `uvm_field_int(data_len, UVM_ALL_ON)
//     `uvm_field_int(reset_after_bytes, UVM_ALL_ON)
//     `uvm_field_int(reset_cycles, UVM_ALL_ON)
//   `uvm_object_utils_end

//   // Constructor
//   function new(string name="upstream_seq_item");
//     super.new(name);
//   endfunction
// endclass

`ifndef UPSTREAM_SEQ_ITEM_SV
`define UPSTREAM_SEQ_ITEM_SV

class upstream_seq_item extends uvm_sequence_item;

  typedef enum {
    DATA_TRANSFER,
    RESET,
    MID_TRANSFER_RESET
  } operation_e;

  // Operation mode and routing fields
  rand operation_e       operation;
  rand bit [7:0]         destination;
  rand int unsigned      data_len;
  rand bit [7:0]         data[];

  // Timing and reset control knobs
  rand int unsigned      inter_pkt_delay;     // Idle cycles before starting packet
  rand int unsigned      reset_after_bytes;   // In-flight byte offset for mid-packet reset
  rand int unsigned      reset_cycles;        // Duration in clock cycles to hold rst_b low

  // Hard constraints: Protocol invariants
  constraint legal_destination_c {
    destination inside {[8'h01 : 8'h04]};
  }

  constraint legal_data_len_c {
    data_len inside {4, 8, 12, 16};
  }

  constraint payload_size_c {
    data.size() == data_len;
  }

  // Soft constraints: Sensible operational defaults that sequences can override
  constraint default_operation_c {
    soft operation == DATA_TRANSFER;
  }

  constraint default_delay_c {
    soft inter_pkt_delay inside {[0 : 3]};
  }

  constraint default_reset_timing_c {
    soft reset_cycles inside {[2 : 4]};
    if (operation == MID_TRANSFER_RESET) {
      reset_after_bytes inside {[1 : data_len - 1]};
    } else {
      reset_after_bytes == 0;
    }
  }

  `uvm_object_utils_begin(upstream_seq_item)
    `uvm_field_enum(operation_e, operation,       UVM_ALL_ON)
    `uvm_field_int(destination,                   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(data_len,                      UVM_ALL_ON | UVM_DEC)
    `uvm_field_array_int(data,                    UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(inter_pkt_delay,               UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_int(reset_after_bytes,             UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
    `uvm_field_int(reset_cycles,                  UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "upstream_seq_item");
    super.new(name);
  endfunction : new

endclass : upstream_seq_item

`endif // UPSTREAM_SEQ_ITEM_SV