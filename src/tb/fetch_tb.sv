`timescale 1ns / 1ps
`define VCD_FILE "./vcds/fetch_tb.vcd"

module fetch_tb ();


  localparam PC_RESET = 0;

  parameter MEMORY_HEX = "./hexs/add.hex";
  parameter MEMORY_BYTES = 1024;
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
    clk                 <= 0;
    rst                 <= 0;
    writeback_change_pc <= 0;
    writeback_next_pc   <= 0;
    execute_change_pc   <= 0;
    execute_next_pc     <= 0;
    stall               <= 0;
    flush               <= 0;
  end

  initial begin
    reset(1);
    instruction_fetch(10);
    test_execute_change_pc('h10);
    instruction_fetch(5);
    test_writeback_change_pc('h18);
    instruction_fetch(100);
    $finish;
  end

  task automatic instruction_fetch;
    input integer number_of_instructions;
    begin
      @(negedge clk);
      repeat (number_of_instructions) @(posedge clk);
    end
  endtask  //automatic

  task automatic test_execute_change_pc;
    input [31:0] next_pc;
    begin
      @(negedge clk);
      execute_change_pc <= 1;
      execute_next_pc   <= next_pc;
      @(posedge clk);
      #(CLK_PERIOD_QUAR);
      execute_change_pc <= 0;
    end
  endtask  //automatic

  task automatic test_writeback_change_pc;
    input [31:0] next_pc;
    begin
      @(negedge clk);
      writeback_change_pc <= 1;
      writeback_next_pc   <= next_pc;
      @(posedge clk);
      #(CLK_PERIOD_QUAR);
      writeback_change_pc <= 0;
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

  reg         clk;
  reg         rst;

  wire [31:0] main_memory_instr_addr;
  wire [31:0] main_memory_instr;
  wire        main_memory_instr_req;
  wire        main_memory_instr_ack;

  wire [31:0] fetch_instr;

  wire [31:0] pc;

  reg         writeback_change_pc;
  reg  [31:0] writeback_next_pc;

  reg         execute_change_pc;
  reg  [31:0] execute_next_pc;

  reg         stall;
  reg         flush;
  wire        next_clk_en;


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

      .pc(pc),

      .writeback_change_pc(writeback_change_pc),
      .writeback_next_pc  (writeback_next_pc),

      .execute_change_pc(execute_change_pc),
      .execute_next_pc  (execute_next_pc),

      .stall      (stall),
      .flush      (flush),
      .next_clk_en(next_clk_en)
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
