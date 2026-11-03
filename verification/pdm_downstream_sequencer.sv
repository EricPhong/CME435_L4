/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
`ifndef PDM_DOWNSTREAM_SEQUENCER_SV // dupe prevention
`define PDM_DOWNSTREAM_SEQUENCER_SV

class pdm_downstream_sequencer extends uvm_sequencer#(downstream_seq_item); // sequence item extends

    `uvm_component_utils(pdm_downstream_sequencer) // factory registration

    uvm_tlm_analysis_fifo #(downstream_seq_item) mon_req_fifo; // unbounded TLM analysis FIFO from downstream monitor

    // Constructor
    function new(string name = "pdm_downstream_sequencer", uvm_component parent = null);
        super.new(name, parent);
        mon_req_fifo = new("mon_req_fifo", this);
    endfunction : new

endclass : pdm_downstream_sequencer

`endif // PDM_DOWNSTREAM_SEQUENCER_SV
