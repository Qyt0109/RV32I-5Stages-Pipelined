`timescale 1ns / 1ps
`define VCD_FILE "./vcds/main_memory_tb.vcd"

module main_memory_tb ();
  parameter MEMORY_HEX = "./hexs/add.hex";
  parameter MEMORY_BYTES = 1024;
  localparam ADDR_WIDTH = $clog2(MEMORY_BYTES);
  localparam MEMORY_DEPTH = MEMORY_BYTES / 4;

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

  task automatic instruction_read;
    input [31:0] read_from_address;
    output match;
    begin
      @(negedge clk);
      instr_stb  <= 1;
      instr_addr <= read_from_address;
      @(posedge clk);
      #(CLK_PERIOD_QUAR) match = (instr == hex_file_data[read_from_address[ADDR_WIDTH-1:2]]);
      $display(  //
          "[%s] Instruction %h at address %h, expected %h",  //
          (match) ? "  OK  " : "FAILED",  //
          instr,  //
          instr_addr,  //
          hex_file_data[read_from_address[ADDR_WIDTH-1:2]]  //
      );
      instr_stb <= 0;
    end
  endtask  //automatic

  task automatic data_read;
    input [31:0] read_from_address;
    begin
      @(negedge clk);
      wb_stb   <= 1;
      wb_cyc   <= 1;
      wb_wr_en <= 1;
      wb_addr  <= read_from_address;
      @(posedge clk);
      #(CLK_PERIOD_QUAR);
      $display("Data %h at address %h", wb_rd_data, wb_addr);
      wb_stb   <= 0;
      wb_cyc   <= 0;
      wb_wr_en <= 0;
    end
  endtask  //automatic

  task automatic data_write;
    input [31:0] write_to_address;
    input [31:0] write_data;
    input [3:0] write_select;
  endtask  //automatic

  reg [31:0] hex_file_data[0:MEMORY_DEPTH-1];
  initial $readmemh(MEMORY_HEX, hex_file_data);

  task automatic test_instruction_read;
    integer address;
    integer errors;
    reg match;
    begin
      errors = 0;
      for (address = 0; address < MEMORY_DEPTH; address = address + 1) begin
        instruction_read(address << 2, match);
        if (!match) errors = errors + 1;
      end
      $display(  //
          "[%s] Done test_instruction_read with %d\/%d errors",  //
          (errors == 0) ? "  OK  " : "FAILED",  //
          errors,  //
          MEMORY_DEPTH  //
      );
    end
  endtask  //automatic

  initial begin
    test_instruction_read();

    #(CLK_PERIOD * 10);
    $finish;
  end

  parameter CLK_PERIOD = 10;  // 100 MHz clk
  parameter CLK_PERIOD_HALF = CLK_PERIOD / 2;
  parameter CLK_PERIOD_QUAR = CLK_PERIOD / 4;
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
      .MEMORY_HEX  (MEMORY_HEX),
      .MEMORY_BYTES(MEMORY_BYTES)
  ) main_memory_inst (
      .clk(clk),

      .instr_addr(instr_addr),
      .instr     (instr),
      .instr_stb (instr_stb),
      .instr_ack (instr_ack),

      .wb_cyc    (wb_cyc),
      .wb_stb    (wb_stb),
      .wb_wr_en  (wb_wr_en),
      .wb_addr   (wb_addr),
      .wb_wr_data(wb_wr_data),
      .wb_sel    (wb_sel),
      .wb_ack    (wb_ack),
      .wb_stall  (wb_stall),
      .wb_rd_data(wb_rd_data)
  );
endmodule
