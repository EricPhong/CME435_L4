/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
`ifndef PDM_UPSTREAM_SEQUENCER_SV
`define PDM_UPSTREAM_SEQUENCER_SV

// If you do not need to extend the functionality of a sequencer, you can use
// a typedef instead to create a sequencer that handles your transaction type
typedef uvm_sequencer#(upstream_seq_item) pdm_upstream_sequencer;

`endif // PDM_UPSTREAM_SEQUENCER_SV
