`timescale 1ns / 1ps
`define VCD_FILE "./vcds/regs_tb.vcd"

module regs_tb ();

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;
  end

  initial begin
    clk = 0;
    rst = 0;
    rs_rd_en = 0;
    rs1 = 0;
    rs2 = 0;
    rd = 0;
    rd_wr_data = 0;
    rd_wr_en = 0;
  end

  initial begin
    rst <= 1;
    #(CLK_PERIOD * 5);
    rst <= 0;
    print_x;
    write_rd(0, 'h1234);
    write_rd(1, 'h9876);
    read_rs(0, 1);
    print_x;

    #(CLK_PERIOD * 10);
    $finish;
  end

  task automatic print_x;
    integer i;
    begin
      for (i = 1; i < 32; i = i + 1) begin
        $display("x[%2d] = %h", i, regs_inst.x[i]);
      end
    end
  endtask  //automatic

  task automatic read_rs;
    input [4:0] rs1_addr;
    input [4:0] rs2_addr;
    reg [31:0] expected_rs1_data;
    reg [31:0] expected_rs2_data;
    reg match_rs1;
    reg match_rs2;
    begin
      @(negedge clk);
      rs_rd_en <= 1;
      rs1      <= rs1_addr;
      rs2      <= rs2_addr;
      @(posedge clk);
      #(CLK_PERIOD_QUAR);
      expected_rs1_data = (rs1_addr == 0) ? 0 : regs_inst.x[rs1_addr];
      match_rs1 = (rs1_rd_data == expected_rs1_data);
      $display(  //
          "[%-6s]Read %08h from rs1 = x[%2d], expected %08h",  //
          match_rs1 ? "OK" : "FAILED",  //
          rs1_rd_data,  //
          rs1_addr,  //
          expected_rs1_data  //
      );
      expected_rs2_data = (rs2_addr == 0) ? 0 : regs_inst.x[rs2_addr];
      match_rs2 = (rs2_rd_data == expected_rs2_data);
      $display(  //
          "[%-6s]Read %08h from rs2 = x[%2d], expected %08h",  //
          match_rs2 ? "OK" : "FAILED",  //
          rs2_rd_data,  //
          rs2_addr,  //
          expected_rs2_data  //
      );
      rs_rd_en <= 0;
    end
  endtask  //automatic

  task automatic write_rd;
    input [4:0] rd_addr;
    input [31:0] rd_write_data;
    begin
      @(negedge clk);
      rd_wr_en   <= 1;
      rd         <= rd_addr;
      rd_wr_data <= rd_write_data;
      @(posedge clk);
      #(CLK_PERIOD_QUAR);
      $display("Write %h to rd = x[%2d]", rd_write_data, rd_addr);
      rd_wr_en <= 0;
    end
  endtask  //automatic


  parameter CLK_PERIOD = 10;  // 100 MHz clk
  parameter CLK_PERIOD_HALF = CLK_PERIOD / 2;
  parameter CLK_PERIOD_QUAR = CLK_PERIOD / 4;
  always #(CLK_PERIOD_HALF) clk = !clk;

  reg         clk;
  reg         rst;

  reg         rs_rd_en;
  reg  [ 4:0] rs1;
  reg  [ 4:0] rs2;

  reg  [ 4:0] rd;
  reg  [31:0] rd_wr_data;
  reg         rd_wr_en;

  wire        rs1_rd_data;
  wire        rs2_rd_data;

  regs regs_inst (
      .clk(clk),
      .rst(rst),

      .rs_rd_en(rs_rd_en),
      .rs1     (rs1),
      .rs2     (rs2),

      .rd        (rd),
      .rd_wr_data(rd_wr_data),
      .rd_wr_en  (rd_wr_en),

      .rs1_rd_data(rs1_rd_data),
      .rs2_rd_data(rs2_rd_data)
  );

endmodule
