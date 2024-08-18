`include "decode_header.vh"
`include "rv32i_header.vh"

module core #(
    parameter PC_RESET        = 0,
    parameter TRAP_ADDR       = 0,
    parameter ZICSR_EXTENSION = 1
) (
    input clk,  //! positive edge triggered system clock
    input rst,  //! asynchronous reset

    // region main_memory
    // Instruction Memory
    output [31:0] main_memory_instr_addr,  //! address for instruction
    input  [31:0] main_memory_instr,       //! instruction
    output        main_memory_instr_req,   //! request for read instruction
    input         main_memory_instr_ack,   //! ack

    // Data Memory
    output        wb_cyc,      //! bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    output        wb_stb,      //! request for read/write access to data memory
    output        wb_we,       //! write-enable (1 = write, 0 = read)
    output [31:0] wb_addr,     //! address of data memory for store/load
    output [31:0] wb_wr_data,  //! data to be stored to memory
    output [ 3:0] wb_sel,      //! byte strobe for write (1 = write the byte) {byte3,byte2,byte1,byte0}
    input         wb_ack,      //! ack by data memory (high when read data is ready or when write data is already written)
    input         wb_stall,    //! stall by data memory
    input  [31:0] wb_rd_data,  //! data retrieve from memory
    // endregion main_memory

    // region Interrupts
    input external_interrupt,  //! interrupt from external source
    input software_interrupt,  //! interrupt from software (inter-processor interrupt)
    input timer_interrupt      //! interrupt from timer
    // endregion Interrupts
);

  // region R regs
  // region control by [STAGE 2 DECODE]
  wire        rs_rd_en;  // source registers read enable
  wire [ 4:0] rs1;  // source register 1 address
  wire [ 4:0] rs2;  // source register 2 address
  // endregion control by [STAGE 2 DECODE]

  // region control by [STAGE 5 WRITEBACK]
  wire [ 4:0] rd;  // destination register address
  wire [31:0] rd_wr_data;  // data to be written to destination register
  wire        rd_wr_en;  // destination register write enable
  // endregion control by [STAGE 5 WRITEBACK]

  wire [31:0] rs1_rd_data;  // source register 1 value
  wire [31:0] rs2_rd_data;  // source register 2 value


  regs regs_dut (
      .clk(clk),
      .rst(rst),
      .rs_rd_en(rs_rd_en),
      .rs1(rs1),
      .rs2(rs2),
      .rd(rd),
      .rd_wr_data(rd_wr_data),
      .rd_wr_en(rd_wr_en),
      .rs1_rd_data(rs1_rd_data),
      .rs2_rd_data(rs2_rd_data)
  );
  // endregion R regs

  // region R fetch
  // region control Main Memory's Instruction Memory
  // Instruction Memory
  //   wire [31:0] main_memory_instr_addr;  // instruction memory address
  //   wire [31:0] main_memory_instr;  // instruction from memory
  //   wire        main_memory_instr_req;  // request for instruction
  //   wire        main_memory_instr_ack;  // ack
  // endregion control Main Memory's Instruction Memory

  wire [31:0] fetch_instr;  // fetched instruction sent to pipeline

  // region PC control
  wire [31:0] fetch_pc;  // PC value of current instruction

  // control from [STAGE 5 WRITEBACK]
  wire        writeback_change_pc;  // high when pc needs to change (trap/return from trap)
  wire [31:0] writeback_next_pc;  // next PC due to trap

  // control from [STAGE 3 EXECUTE]
  //   wire        execute_change_pc;  // high when pc needs to change (branch/jump)
  //   wire [31:0] execute_next_pc;  // next PC due to branch/jump
  // endregion PC control


  // region Pipeline control
  wire        stall_fetch;  //= (decode_stall || execute_stall);  // stall this stage
  //   wire        decode_flush;  // flush this stage
  wire        decode_clk_en;  // clk enable for pipeline stalling of next state ([STAGE 2 DECODE])
  // endregion Pipeline control

  fetch #(
      .PC_RESET(PC_RESET)
  ) fetch_dut (
      .clk(clk),
      .rst(rst),

      .main_memory_instr_addr(main_memory_instr_addr),
      .main_memory_instr     (main_memory_instr),
      .main_memory_instr_req (main_memory_instr_req),
      .main_memory_instr_ack (main_memory_instr_ack),

      .fetch_instr(fetch_instr),
      .pc(fetch_pc),

      .writeback_change_pc(writeback_change_pc),
      .writeback_next_pc  (writeback_next_pc),

      .execute_change_pc(execute_change_pc),
      .execute_next_pc  (execute_next_pc),

      .stall      (stall_fetch),
      .flush      (decode_flush),
      .next_clk_en(decode_clk_en)
  );
  // endregion R fetch

  // region R decode
  // region control from [STAGE 1 FETCH]
  //   wire [                31:0] fetch_instr;  // fetched instruction from [STAGE 1 FETCH]
  //   wire [                31:0] fetch_pc;  // pc from [STAGE 1 FETCH] (previous stage)
  // endregion control from [STAGE 1 FETCH]

  // region decoded signals
  wire [                31:0] decode_pc;  // pc from [STAGE 2 DECODE] (current stage)

  wire [                 4:0] decode_rs1;  // source register 1 address
  wire [                 4:0] decode_r_rs1;  // registed source register 1 address
  wire [                 4:0] decode_rs2;  // source register 2 address
  wire [                 4:0] decode_r_rs2;  // registed source register 2 address
  wire [                 4:0] decode_r_rd;  // registed destination register address
  wire [                31:0] decode_imm;  // extended value for immediate
  wire [                 2:0] decode_funct3;  // function type

  wire [      `ALU_WIDTH-1:0] decode_alu_type;  // alu operation type
  wire [   `OPCODE_WIDTH-1:0] decode_opcode_type;  // opcode type
  wire [`EXCEPTION_WIDTH-1:0] decode_exception;  // illegal instr, ecall, ebreak, mret
  // endregion decoded signals

  // region Pipeline control
  //   wire                        clk_en;  // control by previous stage ([STAGE 1 FETCH])
  wire                        execute_clk_en;  // clk enable for pipeline stalling of next state ([STAGE 3 EXECUTE])
  wire                        stall_decode;  // stall this stage
  wire                        decode_stall;  // stalls the pipeline
  wire                        execute_flush;  // flush this stage
  wire                        decode_flush;  // flushes previous stages
  // endregion Pipeline control
  decode decode_dut (
      .clk(clk),
      .rst(rst),

      .fetch_instr(fetch_instr),
      .fetch_pc   (fetch_pc),

      .decode_pc(decode_pc),

      .decode_rs1   (decode_rs1),
      .decode_r_rs1 (decode_r_rs1),
      .decode_rs2   (decode_rs2),
      .decode_r_rs2 (decode_r_rs2),
      .decode_r_rd  (decode_r_rd),
      .decode_imm   (decode_imm),
      .decode_funct3(decode_funct3),

      .decode_alu_type   (decode_alu_type),
      .decode_opcode_type(decode_opcode_type),
      .decode_exception  (decode_exception),

      .clk_en     (decode_clk_en),
      .next_clk_en(execute_clk_en),
      .stall      (stall_decode),
      .next_stall (decode_stall),
      .flush      (execute_flush),
      .next_flush (decode_flush)
  );
  // endregion R decode

  // region R execute
  //   wire [      `ALU_WIDTH-1:0] decode_alu_type;

  //   wire [                 4:0] decode_r_rs1;
  wire [                 4:0] execute_rs1;

  wire [                31:0] forward_rs1_data;
  wire [                31:0] execute_rs1_data;

  wire [                31:0] forward_rs2_data;
  wire [                31:0] execute_rs2_data;

  //   wire [                 4:0] decode_r_rd;
  wire [                 4:0] execute_rd;

  //   wire [                31:0] decode_imm;
  wire [                11:0] execute_imm;

  //   wire [                2:0] decode_funct3;
  wire [                 2:0] execute_funct3;

  //   wire [   `OPCODE_WIDTH-1:0] decode_opcode_type;
  wire [   `OPCODE_WIDTH-1:0] execute_opcode_type;

  //   wire [`EXCEPTION_WIDTH-1:0] decode_exception;
  wire [`EXCEPTION_WIDTH-1:0] execute_exception;

  wire [                31:0] execute_result;  // alu operation result

  // region PC control
  //   wire [                31:0] decode_pc;  // pc
  wire [                31:0] execute_pc;  // pc in pipeline
  wire [                31:0] execute_next_pc;  // new pc
  wire                        execute_change_pc;  // need to jump
  // endregion PC control

  // region base registers control
  wire                        execute_rd_wr_en;
  wire [                31:0] execute_rd_wr_data;
  wire                        execute_rd_valid;
  // endregion base registers control

  // region Pipeline control
  wire                        stall_from_execute;  // stall next stage ([STAGE 4 MEMORY] for load/store instructions)
  wire                        clk_en;  // control by previous stage ([STAGE 2 DECODE])
  wire                        next_clk_en;  // clk enable for pipeline stalling of next state ([STAGE 4 MEMORY])
  wire                        stall;  // stall this stage
  wire                        force_stall;  // force this stage to stall
  wire                        next_stall;  // stalls the pipeline
  wire                        flush;  // flush this stage
  wire                        next_flush;  // flushes previous stages
  // endregion Pipeline control

  execute execute_dut (
      .clk(clk),
      .rst(rst),

      .decode_alu_type(decode_alu_type),

      .decode_r_rs1(decode_r_rs1),
      .execute_rs1 (execute_rs1),

      .forward_rs1_data(forward_rs1_data),
      .execute_rs1_data(execute_rs1_data),

      .forward_rs2_data(forward_rs2_data),
      .execute_rs2_data(execute_rs2_data),

      .decode_r_rd(decode_r_rd),
      .execute_rd (execute_rd),

      .decode_imm (decode_imm),
      .execute_imm(execute_imm),

      .decode_funct3 (decode_funct3),
      .execute_funct3(execute_funct3),

      .decode_opcode_type (decode_opcode_type),
      .execute_opcode_type(execute_opcode_type),

      .decode_exception (decode_exception),
      .execute_exception(execute_exception),

      .execute_result(execute_result),

      .decode_pc        (decode_pc),
      .execute_pc       (execute_pc),
      .execute_next_pc  (execute_next_pc),
      .execute_change_pc(execute_change_pc),

      .execute_rd_wr_en  (execute_rd_wr_en),
      .execute_rd_wr_data(execute_rd_wr_data),
      .execute_rd_valid  (execute_rd_valid),

      .stall_from_execute(stall_from_execute),
      .clk_en            (clk_en),
      .next_clk_en       (next_clk_en),
      .stall             (stall),
      .force_stall       (force_stall),
      .next_stall        (next_stall),
      .flush             (flush),
      .next_flush        (next_flush)
  );
  // endregion R execute


endmodule
