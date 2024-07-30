`timescale 1ns / 1ps
`define VCD_FILE "./vcds/decode_tb.vcd"

module decode_tb ();

  integer totals = 0;
  integer errors = 0;

  localparam PC_RESET = 0;

  localparam TEST_INSTRUCTION = 32'h09600113;

  parameter MEMORY_HEX = "";
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
    writeback_change_pc        <= 0;
    writeback_next_pc          <= 0;
    execute_change_pc          <= 0;
    execute_next_pc            <= 0;
    main_memory_inst.memory[0] <= 'h002081b3;  // addi x3, x1, x2      [RTYPE]
    main_memory_inst.memory[1] <= 'h09600113;  // addi x2, x0, 150     [ITYPE]
    main_memory_inst.memory[2] <= 'h00008103;  // lb   x2,  0(x1)      [LOAD]
    main_memory_inst.memory[3] <= 'hfe311e23;  // sh   x3, -4(x2)      [STORE]
    main_memory_inst.memory[4] <= 'h00115463;  // bge  x2, x1, 8       [BRANCH]
    main_memory_inst.memory[5] <= 'h010000ef;  // jal  x1, 16          [JAL]
    main_memory_inst.memory[6] <= 'h018081e7;  // jalr x3, 24(x1)      [JALR]
    main_memory_inst.memory[7] <= 'habcde097;  // auipc x1, -344866    [AUIPC]
    main_memory_inst.memory[8] <= 'h30556473;  // csrrsi x8, mtvec, 10 [SYSTEM]
    main_memory_inst.memory[9] <= 'h0ff0000f;  // fence iorw, iorw     [FENCE]
    for (integer i = 10; i < MEMORY_DEPTH; i = i + 1) begin
      main_memory_inst.memory[i] <= 0;
    end
  end

  initial begin
    // Reset
    reset(1);
    // Test fetch, decode and change pc
    test_decode();
    $finish;
  end

  task automatic test_decode;
    begin
      instruction_decode(11);
      test_execute_change_pc('h18);
      instruction_decode(11);
      test_writeback_change_pc('h10);
      instruction_decode(11);
    end
  endtask  //automatic

  task automatic instruction_decode;
    input integer number_of_test;
    string opcode_type;
    reg [31:0] previous_fetch_instr;
    begin
      repeat (number_of_test) begin
        // Fetch
        instruction_fetch(1, previous_fetch_instr);
`ifdef DETAILS
        $write(  //
            "[%sDECODE\033[00m] decode_pc = %4d, decode_instr = \033[96m%8h\033[00m",  //
            (|decode_opcode_type) ? "\033[92m" : "\033[91m",  //
            decode_pc, previous_fetch_instr  //
        );
        $write(  //
            "%s >>> [Info] stall_bit = %1b, decode_clk_en = %1b, execute_clk_en = %1b, stall_decode = %1b, decode_stall = %1b, flush_decode = %1b, decode_flush = %1b\033[00m\n",  //
            ((!decode_inst.stall_bit) && decode_clk_en && execute_clk_en && (!stall_decode) && (!decode_stall) && (!flush_decode) && (!decode_flush)) ? "\033[00m" : "\033[95m",  //
            decode_inst.stall_bit, decode_clk_en, execute_clk_en, stall_decode, decode_stall, flush_decode, decode_flush,//
        );
        // .clk_en     (decode_clk_en),
        // .next_clk_en(execute_clk_en),
        // .stall      (stall_decode),
        // .next_stall (decode_stall),
        // .flush      (flush_decode),
        // .next_flush (decode_flush)
        $write(">>>");
        $write("%s RTYPE\033[00m", decode_opcode_type[`RTYPE] ? "\033[92m" : "\033[00m");
        $write("%s ITYPE\033[00m", decode_opcode_type[`ITYPE] ? "\033[92m" : "\033[00m");
        $write("%s LOAD\033[00m", decode_opcode_type[`LOAD] ? "\033[92m" : "\033[00m");
        $write("%s STORE\033[00m", decode_opcode_type[`STORE] ? "\033[92m" : "\033[00m");
        $write("%s BRANCH\033[00m", decode_opcode_type[`BRANCH] ? "\033[92m" : "\033[00m");
        $write("%s JAL\033[00m", decode_opcode_type[`JAL] ? "\033[92m" : "\033[00m");
        $write("%s JALR\033[00m", decode_opcode_type[`JALR] ? "\033[92m" : "\033[00m");
        $write("%s LUI\033[00m", decode_opcode_type[`LUI] ? "\033[92m" : "\033[00m");
        $write("%s AUIPC\033[00m", decode_opcode_type[`AUIPC] ? "\033[92m" : "\033[00m");
        $write("%s SYSTEM\033[00m", decode_opcode_type[`SYSTEM] ? "\033[92m" : "\033[00m");
        $write("%s FENCE\033[00m", decode_opcode_type[`FENCE] ? "\033[92m" : "\033[00m");
`endif
        $display("\n");
      end
    end
  endtask  //automatic

  task automatic instruction_fetch;
    input integer number_of_instructions;
    output [31:0] previous_fetch_instr;
    reg match;
    reg [31:0] instr_in_mem;
    begin
      @(negedge clk);
      repeat (number_of_instructions) begin
        previous_fetch_instr = fetch_instr;
        @(posedge clk);
        #1;  // Wait for signals to change
        instr_in_mem = main_memory_inst.memory[fetch_pc>>2];
        match = (fetch_instr == instr_in_mem);
`ifdef DETAILS
        $write(  //
            "[%-6s] fetch_pc  = %4d, instr_fetch  = \033[96m%8h\033[00m",  //
            (match) ? "\033[92mFETCH \033[00m" : "\033[91mFETCH \033[00m",  //
            fetch_pc, fetch_instr  //
        );
        $write(  //
            "%s >>> [Info] stall_bit = %1b, stall_fetch = %1b, decode_flush = %1b, decode_clk_en = %1b\033[00m\n",  //
            ((!fetch_inst.stall_bit) && (!stall_fetch) && (!decode_flush) && decode_clk_en) ? "\033[00m" : "\033[95m",  //
            fetch_inst.stall_bit, stall_fetch, decode_flush, decode_clk_en  //
        );
`endif
      end
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
`ifdef DETAILS
      $display(  //
          "\033[94m>>> fetch_pc changed to %1d due to Execute\033[00m",  //
          next_pc  //
      );
`endif
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
`ifdef DETAILS
      $display(  //
          "\033[94m>>> fetch_pc changed to %1d due to Writeback\033[00m",  //
          next_pc  //
      );
`endif
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
`ifdef DETAILS
      $display("\033[94m>>> Reset released...\033[00m");
`endif
    end
  endtask  //automatic

  reg                         clk;
  reg                         rst;

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
  wire                        stall_decode = 0;
  wire                        decode_stall;
  wire                        flush_decode = 0;
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
      .stall      (stall_decode),
      .next_stall (decode_stall),
      .flush      (flush_decode),
      .next_flush (decode_flush)
  );

  wire [31:0] main_memory_instr_addr;
  wire [31:0] main_memory_instr;
  wire        main_memory_instr_req;
  wire        main_memory_instr_ack;

  wire [31:0] fetch_instr;

  wire [31:0] fetch_pc;

  reg         writeback_change_pc;
  reg  [31:0] writeback_next_pc;

  reg         execute_change_pc;
  reg  [31:0] execute_next_pc;

  wire        stall_fetch = decode_stall;
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

      .stall      (stall_fetch),
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
