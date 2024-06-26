module fetch #(
    parameter PC_RESET = 0
) (
    input clk,
    input rst,

    // region control Main Memory's Instruction Memory
    // Instruction Memory
    output reg [31:0] main_memory_instr_addr,  // instruction memory address
    input      [31:0] main_memory_instr,       // instruction from memory
    output            main_memory_instr_req,   // request for instruction
    input             main_memory_instr_ack,   // ack
    // endregion control Main Memory's Instruction Memory

    output reg [31:0] fetch_instr,  // fetched instruction sent to pipeline

    // region PC control
    output reg [31:0] pc,  // PC value of current instruction

    // control from [STAGE 5 WRITEBACK]
    input        writeback_change_pc,  // high when pc needs to change (trap/return from trap)
    input [31:0] writeback_next_pc,    // next PC due to trap

    // control from [STAGE 3 EXECUTE]
    input        execute_change_pc,  // high when pc needs to change (branch/jump)
    input [31:0] execute_next_pc,    // next PC due to branch/jump
    // endregion PC control


    // region Pipeline control
    input      stall,       // stall this stage
    input      flush,       // flush this stage
    output reg next_clk_en  // output clk enable for pipeline stalling of next state
    // endregion Pipeline control
);

  reg r_next_clk_en;
  reg r_next_clk_en_d;
  reg r_stall;

  /* Stall conditions
  stall this stage when:
  - stall this stage
  - memory instruction requested but no ack yet
  - no memory instruction request at all (no instruction to execute for this stage)
  */
  wire stall_bit = (
    stall ||
    (main_memory_instr_req && (!main_memory_instr_ack)) ||
    (!main_memory_instr_req)
  );

  reg [31:0] prev_pc;
  reg [31:0] stalled_instr;
  reg [31:0] stalled_pc;

endmodule
