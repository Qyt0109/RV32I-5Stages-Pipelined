module memory (
    input clk,
    input rst,

    input [31:0] execute_rs2_data,  // Data to be stored to memory is always rs2 data
    input [31:0] execute_result,    // Result from execute (load/store address)

    input      [2:0] execute_funct3,  // funct3 from previous stage [STAGE 3 EXECUTE]
    output reg [2:0] memory_funct3,   // funct3 (byte, halfword, word store/load operation)

    input      [`OPCODE_WIDTH-1:0] execute_opcode_type,  // opcode type from prev [STAGE 3 EXECUTE]
    output reg [`OPCODE_WIDTH-1:0] memory_opcode_type,   // opcode type

    input      [31:0] execute_pc,
    output reg [31:0] memory_pc,

    // region Base Registers control
    input             execute_rd_wr_en,    // enable write rd from previous stage [STAGE 3 EXECUTE]
    output reg        memory_rd_wr_en,     // write rd to the base reg if enabled
    input      [ 4:0] execute_rd,          // rd write address from previous stage [STAGE 3 EXECUTE]
    output reg [ 4:0] memory_rd,           // address for destination register
    input      [31:0] execute_rd_wr_data,  // rd write data from previous stage [STAGE 3 EXECUTE]
    output reg [31:0] memory_rd_wr_data,   // data to be written back to destination register
    // endregion Base Registers control

    // region Data Memory control
    output reg        main_memory_wb_cyc,      // bus cycle active (1 = normal operation,
                                               // 0 = all ongoing transaction are to be cancelled)
    output reg        main_memory_wb_stb,      // request for read/write access to data memory
    output reg        main_memory_wb_wr_en,    // write-enable (1 = write, 0 = read)
    output reg [31:0] main_memory_wb_addr,     // data memory address
    output reg [31:0] main_memory_wb_wr_data,  // data to be stored to memory
    output reg [ 3:0] main_memory_wb_wr_sel,   // byte select for write {byte3, byte2, byte1, byte0}
    input             main_memory_wb_ack,      // ack by data memory (high when data to be read is
                                               // ready or when write data is already written)
    input             main_memory_wb_stall,    // stall by data memory (1 = data memory is busy)
    input      [31:0] main_memory_wb_rd_data,  // data retrieve from data memory
    // endregion Data Memory control

    output reg [31:0] memory_data_load,  // data to be loaded to base reg (z-or-s extended)

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

  reg  [31:0] wb_wr_data;  // data to be stored to memory
  reg  [31:0] data_load;  // data to be loaded to basereg
  reg  [ 3:0] wb_wr_sel;  // byte mask
  reg         pend_req;  // is there still a pending request (not yet ack req)
  wire [ 1:0] addr_last2b = execute_result[1:0];  // last 2 bits of data memory address

  wire        stall_bit = (stall || next_stall);

  // region registered the outputs
  always @(posedge clk, posedge rst) begin
    if (rst) begin

    end else begin
      // wishbone cycle will only be high if this stage is enabled
      main_memory_wb_cyc <= clk_en;

      // pending request completed after ack
      if (main_memory_wb_ack) pend_req <= 0;

      // update registers only if this stage is enabled and not stalled (after load/store operation)
      if (clk_en && (!stall_bit)) begin
        memory_funct3      <= execute_funct3;
        memory_opcode_type <= execute_opcode_type;
        memory_pc          <= execute_pc;

        memory_rd_wr_en    <= execute_rd_wr_en;
        memory_rd          <= execute_rd;
        memory_rd_wr_data  <= execute_rd_wr_data;

        memory_data_load   <= data_load;
      end

      // update request to memory only if this stage is enabled and no pending request yet
      if (clk_en && (!pend_req)) begin
        main_memory_wb_stb     <= (execute_opcode_type[`LOAD] || execute_opcode_type[`STORE]);
        main_memory_wb_wr_sel  <= wb_wr_sel;
        main_memory_wb_wr_en   <= execute_opcode_type[`STORE];
        pend_req               <= (execute_opcode_type[`LOAD] || execute_opcode_type[`STORE]);
        main_memory_wb_addr    <= execute_result;
        main_memory_wb_wr_data <= wb_wr_data;
      end

      // if there is pending request but no stall from memory: idle the stb line
      if (pend_req && (!main_memory_wb_stall)) main_memory_wb_stb <= 0;

      // if this stage is disabled, idle the stb line
      if (!clk_en) main_memory_wb_stb <= 0;
    end
  end
  // endregion registered the outputs




endmodule
