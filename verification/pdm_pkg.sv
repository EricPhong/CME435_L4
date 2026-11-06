/* Eric Phong, rfp479, CME435, 11344905, Lab4 */

package pdm_pkg;
    timeunit 1ns;
    timeprecision 1ps;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Transaction Items
    `include "upstream_seq_item.sv"
    `include "downstream_seq_item.sv"

    // Sequencers & Configurations
    `include "pdm_upstream_sequencer.sv"
    `include "pdm_downstream_sequencer.sv"
    `include "pdm_upstream_agent_cfg.sv"
    `include "pdm_downstream_agent_cfg.sv"
    `include "pdm_env_cfg.sv"

    // Transactors & Agents
    `include "pdm_upstream_driver.sv"
    `include "pdm_upstream_monitor.sv"
    `include "pdm_downstream_driver.sv"
    `include "pdm_downstream_monitor.sv"
    `include "pdm_upstream_agent.sv"
    `include "pdm_downstream_agent.sv"
    `include "pdm_env.sv"

    // Sequences
    `include "pdm_upstream_packet_seq.sv"
    `include "pdm_upstream_reset_seq.sv"
    `include "pdm_downstream_reactive_seq.sv"
    `include "pdm_sanity_seq.sv"
    `include "pdm_pkt_len_seq.sv"
    `include "pdm_saturation_seq.sv"
    `include "pdm_reset_traffic_seq.sv"
    `include "pdm_random_traffic_seq.sv"

    // Test Suite
    `include "pdm_test_base.sv"
    `include "pdm_sanity_test.sv"
    `include "pdm_packet_len_test.sv"
    `include "pdm_proceed_delay_test.sv"
    `include "pdm_saturation_test.sv"
    `include "pdm_reset_test.sv"
    `include "pdm_random_test.sv"

endpackage : pdm_pkg