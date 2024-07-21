`timescale 1ns / 1ps
`define VCD_FILE "./vcds/execute_tb.vcd"

// `define MEMORY "./hexs/add.hex"
// `define MEMORY "./hexs/addi.hex"
// `define MEMORY "./hexs/and.hex"
// `define MEMORY "./hexs/andi.hex"
// `define MEMORY "./hexs/auipc.hex"
// `define MEMORY "./hexs/beq.hex"
// `define MEMORY "./hexs/bge.hex"
// `define MEMORY "./hexs/bgeu.hex"
// `define MEMORY "./hexs/blt.hex"
// `define MEMORY "./hexs/bltu.hex"
// `define MEMORY "./hexs/bne.hex"
// `define MEMORY "./hexs/branch_hazard.hex"
// `define MEMORY "./hexs/data_hazard.hex"
// `define MEMORY "./hexs/jal.hex"
`define MEMORY "./hexs/jalr.hex"
// `define MEMORY "./hexs/lb.hex"
// `define MEMORY "./hexs/lbu.hex"
// `define MEMORY "./hexs/lh.hex"
// `define MEMORY "./hexs/lhu.hex"
// `define MEMORY "./hexs/lui.hex"
// `define MEMORY "./hexs/lw.hex"
// `define MEMORY "./hexs/no_hazard.hex"
// `define MEMORY "./hexs/or.hex"
// `define MEMORY "./hexs/ori.hex"
// `define MEMORY "./hexs/sb.hex"
// `define MEMORY "./hexs/sh.hex"
// `define MEMORY "./hexs/sw.hex"
// `define MEMORY "./hexs/sll.hex"
// `define MEMORY "./hexs/slli.hex"
// `define MEMORY "./hexs/slt.hex"
// `define MEMORY "./hexs/slti.hex"
// `define MEMORY "./hexs/sltiu.hex"
// `define MEMORY "./hexs/sltu.hex"
// `define MEMORY "./hexs/sra.hex"
// `define MEMORY "./hexs/srai.hex"
// `define MEMORY "./hexs/srl.hex"
// `define MEMORY "./hexs/srli.hex"
// `define MEMORY "./hexs/sub.hex"
// `define MEMORY "./hexs/xor.hex"
// `define MEMORY "./hexs/xori.hex"

module execute_tb ();


  localparam PC_RESET = 0;

  parameter MEMORY_HEX = `MEMORY;
  parameter MEMORY_BYTES = 1024 * 4;
  localparam ADDR_WIDTH = $clog2(MEMORY_BYTES);
  localparam MEMORY_DEPTH = MEMORY_BYTES / 4;

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;
  end

  parameter CLK_PERIOD = 10;  // 100 MHz clk
  parameter CLK_PERIOD_HALF = CLK_PERIOD / 2;
  parameter CLK_PERIOD_QUAR = CLK_PERIOD / 4;
  always #(CLK_PERIOD_HALF) clk = !clk;

  initial begin
    clk                        <= 0;
    rst                        <= 0;
  end

  initial begin
    reset(1);
    instruction_fetch(10);
    $finish;
  end

  task automatic instruction_fetch;
    input integer number_of_instructions;
    begin
      @(negedge clk);
      repeat (number_of_instructions) @(posedge clk);
    end
  endtask  //automatic

  task automatic reset;
    input integer clk_period;
    begin
      @(negedge clk);
      rst <= 1;
      repeat (clk_period) @(posedge clk);
      @(negedge clk);
      rst <= 0;
    end
  endtask  //automatic


  reg                         clk;
  reg                         rst;

//   wire [      `ALU_WIDTH-1:0] decode_alu_type;
//   wire [                 4:0] decode_r_rs1;
  wire [                 4:0] execute_rs1;
  wire [                31:0] forward_rs1_data = 'h1234;
  wire [                31:0] execute_rs1_data;
  wire [                31:0] forward_rs2_data = 'h1234;
  wire [                31:0] execute_rs2_data;
//   wire [                 4:0] decode_r_rd;
  wire [                 4:0] execute_rd;
//   wire [                31:0] decode_imm;
  wire [                11:0] execute_imm;
//   wire [                31:0] decode_funct3;
  wire [                31:0] execute_funct3;
//   wire [   `OPCODE_WIDTH-1:0] decode_opcode_type;
  wire [   `OPCODE_WIDTH-1:0] execute_opcode_type;
//   wire [`EXCEPTION_WIDTH-1:0] decode_exception;
  wire [`EXCEPTION_WIDTH-1:0] execute_exception;
  wire [                31:0] execute_result;
//   wire [                31:0] decode_pc;
  wire [                31:0] execute_pc;
  wire [                31:0] execute_next_pc;
  wire [                31:0] execute_change_pc;
  wire                        execute_rd_wr_en;
  wire [                31:0] execute_rd_wr_data;
  wire                        execute_rd_valid;
  wire                        stall_from_execute;
//   wire                        clk_en;
  wire                        memory_clk_en;
  wire                        stall_execute;
  wire                        force_stall = 0;
  wire                        execute_stall = 0;
  wire                        memory_flush = 0;
  wire                        execute_flush;


  execute execute_inst (
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
      .clk_en            (execute_clk_en),
      .next_clk_en       (memory_clk_en),
      .stall             (execute_stall),
      .force_stall       (force_stall),
      .next_stall        (stall_execute),
      .flush             (memory_flush),
      .next_flush        (execute_flush)
  );

  wire [                31:0] decode_pc;
  wire [                 4:0] decode_rs1;
  wire [                 4:0] decode_r_rs1;
  wire [                 4:0] decode_rs2;
  wire [                 4:0] decode_r_rs2;
  wire [                 4:0] decode_r_rd;
  wire [                31:0] decode_imm;
  wire [                 2:0] decode_funct3;
  wire [      `ALU_WIDTH-1:0] decode_alu_type;
  wire [   `OPCODE_WIDTH-1:0] decode_opcode_type;
  wire [`EXCEPTION_WIDTH-1:0] decode_exception;

  wire                        execute_clk_en;
  wire                        stall_decode;
  wire                        decode_stall = (stall_execute);
  wire                        flush_decode;
  wire                        decode_flush;


  decode decode_inst (
      .clk(clk),
      .rst(rst),

      .fetch_instr(fetch_instr),
      .fetch_pc(fetch_pc),

      .decode_pc   (decode_pc),
      .decode_rs1  (decode_rs1),
      .decode_r_rs1(decode_r_rs1),
      .decode_rs2  (decode_rs2),
      .decode_r_rs2(decode_r_rs2),
      .decode_r_rd (decode_r_rd),
      .decode_imm  (decode_imm),

      .decode_funct3     (decode_funct3),
      .decode_alu_type   (decode_alu_type),
      .decode_opcode_type(decode_opcode_type),
      .decode_exception  (decode_exception),

      .clk_en     (decode_clk_en),
      .next_clk_en(execute_clk_en),
      .stall      (decode_stall),
      .next_stall (stall_decode),
      .flush      (execute_flush),
      .next_flush (decode_flush)
  );

  wire [31:0] main_memory_instr_addr;
  wire [31:0] main_memory_instr;
  wire        main_memory_instr_req;
  wire        main_memory_instr_ack;

  wire [31:0] fetch_instr;

  wire [31:0] fetch_pc;

  reg         writeback_change_pc = 0;
  reg  [31:0] writeback_next_pc = 0;

  wire        fetch_stall = (stall_decode || stall_execute);
  wire        decode_clk_en;


  fetch #(
      .PC_RESET(PC_RESET)
  ) fetch_inst (
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

      .stall      (fetch_stall),
      .flush      (decode_flush),
      .next_clk_en(decode_clk_en)
  );


  reg         wb_cyc = 0;
  reg         wb_stb = 0;
  reg         wb_wr_en = 0;
  reg  [31:0] wb_addr = 0;
  reg  [31:0] wb_wr_data = 0;
  reg  [ 3:0] wb_wr_sel = 0;
  wire        wb_ack;
  wire        wb_stall;
  wire [31:0] wb_rd_data;

  main_memory #(
      .MEMORY_HEX  (MEMORY_HEX),
      .MEMORY_BYTES(MEMORY_BYTES)
  ) main_memory_inst (
      .clk(clk),

      .instr_addr(main_memory_instr_addr),
      .instr     (main_memory_instr),
      .instr_stb (main_memory_instr_req),
      .instr_ack (main_memory_instr_ack),

      .wb_cyc    (wb_cyc),
      .wb_stb    (wb_stb),
      .wb_wr_en  (wb_wr_en),
      .wb_addr   (wb_addr),
      .wb_wr_data(wb_wr_data),
      .wb_wr_sel (wb_wr_sel),
      .wb_ack    (wb_ack),
      .wb_stall  (wb_stall),
      .wb_rd_data(wb_rd_data)
  );
endmodule
