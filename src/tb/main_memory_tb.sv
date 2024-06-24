`timescale 1ns / 1ps
`define VCD_FILE "./vcds/main_memory_tb.vcd"

module main_memory_tb ();
  `define MEMORY_HEX "./hexs/add.hex"
  `define MEMORY_DEPTH 1024

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;
  end

  initial begin
    clk = 0;
    instr_addr = 0;
    instr_stb = 0;
    wb_cyc = 0;
    wb_stb = 0;
    wb_wr_en = 0;
    wb_addr = 0;
    wb_wr_data = 0;
    wb_sel = 0;
  end

  initial begin
    #(CLK_PERIOD * 10);
    $finish;
  end

  parameter CLK_PERIOD = 10;  // 100 MHz clk
  parameter CLK_PERIOD_HALF = CLK_PERIOD / 2;
  always #(CLK_PERIOD_HALF) clk = !clk;

  reg         clk;

  reg  [31:0] instr_addr;
  wire [31:0] instr;
  reg         instr_stb;
  wire        instr_ack;

  reg         wb_cyc;
  reg         wb_stb;
  reg         wb_wr_en;
  reg  [31:0] wb_addr;
  reg  [31:0] wb_wr_data;
  reg  [ 3:0] wb_sel;
  wire        wb_ack;
  wire        wb_stall;
  wire [31:0] wb_rd_data;

  main_memory #(
      .MEMORY_HEX  (`MEMORY_HEX),
      .MEMORY_DEPTH(`MEMORY_DEPTH)
  ) main_memory_inst (
      .clk(clk),

      .instr_addr(instr_addr),
      .instr(instr),
      .instr_stb(instr_stb),
      .instr_ack(instr_ack),

      .wb_cyc(wb_cyc),
      .wb_stb(wb_stb),
      .wb_wr_en(wb_wr_en),
      .wb_addr(wb_addr),
      .wb_wr_data(wb_wr_data),
      .wb_sel(wb_sel),
      .wb_ack(wb_ack),
      .wb_stall(wb_stall),
      .wb_rd_data(wb_rd_data)
  );
endmodule
