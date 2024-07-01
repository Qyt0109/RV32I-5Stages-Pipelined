module memory (
    input clk,
    input rst,

    input [31:0] execute_rs2_data,  // Data to be stored to memory is always rs2 data
    input [31:0] execute_result,    // Result from execute (load/store address)

    input      [2:0] execute_funct3,  // funct3 from previous stage [STAGE 3 EXECUTE]
    output reg [2:0] memory_funct3,   // funct3 (byte, halfword, word store/load operation)

    input      [`OPCODE_WIDTH-1:0] execute_opcode_type,  // opcode type from prev [STAGE 3 EXECUTE]
    output reg [`OPCODE_WIDTH-1:0] memory_opcode_type,   // opcode type

    // region Base Registers control
    input             execute_rd_wr_en,    // enable write rd from previous stage [STAGE 3 EXECUTE]
    output reg        memory_rd_wr_en,     // write rd to the base reg if enabled
    input      [ 4:0] execute_rd,          // rd write address from previous stage [STAGE 3 EXECUTE]
    output reg [ 4:0] memory_rd,           // address for destination register
    input      [31:0] execute_rd_wr_data,  // rd write data from previous stage [STAGE 3 EXECUTE]
    output reg [31:0] memory_rd_wr_data,   // data to be written back to destination register
    // endregion Base Registers control


    // region Pipeline control
    input      stall_from_execute,  // Execute tell to prepare to stall for load/store instruction
    input      clk_en,              // control by previous stage [STAGE 3 EXECUTE]
    output reg next_clk_en,         // clk enable for pipeline stalling
    input      stall,               // stall this stage
    output reg next_stall,          // stalls the pipeline
    input      flush,               // flush this stage
    output reg next_flush           // flushes previous stages
    // endregion Pipeline control
);




endmodule
