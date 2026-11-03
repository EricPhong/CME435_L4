/* Eric Phong, rfp479, CME435, 11344905, Lab4 */ 
 
`ifndef PDM_DOWNSTREAM_SEQUENCER_SV
`define PDM_DOWNSTREAM_SEQUENCER_SV

class pdm_downstream_sequencer extends uvm_sequencer#(downstream_seq_item);
    `uvm_component_utils(pdm_downstream_sequencer)

    // Analysis FIFO for receiving REQ transactions from the downstream monitor
    uvm_tlm_analysis_fifo #(downstream_seq_item) mon_req_fifo;

    function new(string name = "pdm_downstream_sequencer", uvm_component parent = null);
        super.new(name, parent);
        mon_req_fifo = new("mon_req_fifo", this);
    endfunction : new

endclass : pdm_downstream_sequencer

`endif // PDM_DOWNSTREAM_SEQUENCER_SV
