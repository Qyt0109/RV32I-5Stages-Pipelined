`timescale 1ns / 1ns
`default_nettype none

`define DISPLAY
//`define HALT_ON_ILLEGAL_INSTRUCTION // stop core when instruction is illegal
 //`define HALT_ON_EBREAK // halt core on ebreak
// `define HALT_ON_ECALL // halt core on ecall

`include "rv32i_header.vh"

`define ICARUS
`define VCD_FILE "./vcds/soc_tb.vcd"

// `define MEMORY "../add.hex" // TRAP
// `define MEMORY "./hexs/test.hex" // TEST

// `define MEMORY "./hexs/csr_op.hex"       // CSR Operations
// `define MEMORY "./hexs/exceptions.hex"   // Test Exceptions >>> FAILED!!!
// `define MEMORY "./hexs/interrupts.hex"   // Test Interrupt  >>> FAILED!!!

`define MEMORY "./hexs/add.hex"             // [17 instructions in 23 clk cycles]
// `define MEMORY "./hexs/addi.hex"    // [14 instructions in 20 clk cycles]
// `define MEMORY "./hexs/and.hex" // [10 instructions in 16 clk cycles]
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
// `define MEMORY "./hexs/jalr.hex"
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

module soc_tb;
    /******************************* MODIFY ****************************************/
    localparam MEMORY_DEPTH = 81920, //number of memory bytes
               DATA_START_ADDR = 32'h1004; //starting address of data memory to be displayed
    /*******************************************************************************/
   
    reg clk,rst_n;
    reg temp;
    integer i,j;          
    
    
    soc #(
        .PC_RESET(32'h00_00_00_00),
        .MEMORY_HEX(`MEMORY),
        .MEMORY_BYTES(1024),
        .TRAP_ADDR(0)
        ) uut (
        .clk(clk),
        .rst(!rst_n)
        );
    
    always #5 clk=!clk; //100MHz clock
    
    initial begin //2nd reset to test resetting while core is executing instruction
        #200;
        rst_n = 0;
        #500;
        rst_n = 1;
    end  
        
    /*********************** initialize instruction memory and data memory **************************/
    initial begin 
        #1;
        // $readmemh(`MEMORY,uut.main_memory_inst.memory); //write instruction and data to memory
        //uut.main_memory_inst.memory[{32'h0000_1000>>2}] = 32'h12345678; //initial data memory 
    end
    /***********************************************************************************************/
    reg[1024:0] cause;
    
    initial begin
        `ifdef ICARUS
        $dumpfile(`VCD_FILE);
        $dumpvars(0,soc_tb);
        $dumpvars(0,uut.core_inst.regs_inst.x[1],uut.core_inst.regs_inst.x[2],uut.core_inst.regs_inst.x[3],uut.core_inst.regs_inst.x[4],uut.core_inst.regs_inst.x[5]);
        $dumpvars(0,uut.core_inst.regs_inst.x[6],uut.core_inst.regs_inst.x[7],uut.core_inst.regs_inst.x[8],uut.core_inst.regs_inst.x[9],uut.core_inst.regs_inst.x[10]);
        $dumpvars(0,uut.core_inst.regs_inst.x[11],uut.core_inst.regs_inst.x[12],uut.core_inst.regs_inst.x[13],uut.core_inst.regs_inst.x[14],uut.core_inst.regs_inst.x[15]);
        $dumpvars(0,uut.core_inst.regs_inst.x[16],uut.core_inst.regs_inst.x[17],uut.core_inst.regs_inst.x[18],uut.core_inst.regs_inst.x[19],uut.core_inst.regs_inst.x[20]);
        $dumpvars(0,uut.core_inst.regs_inst.x[21],uut.core_inst.regs_inst.x[22],uut.core_inst.regs_inst.x[23],uut.core_inst.regs_inst.x[24],uut.core_inst.regs_inst.x[25]);
        $dumpvars(0,uut.core_inst.regs_inst.x[26],uut.core_inst.regs_inst.x[27],uut.core_inst.regs_inst.x[28],uut.core_inst.regs_inst.x[29],uut.core_inst.regs_inst.x[30]);
        $dumpvars(0,uut.core_inst.regs_inst.x[31]);
        `endif
		
        rst_n = 1;
        #50;
        clk=0;
        rst_n=0;
        #50;
        
        rst_n=1; //release reset
        
        $display("\nStart executing instructions......\n");
        $display("Monitor All Writes to Base Register and Data Memory");
        
        /**************************************************************************************************************************/
		
        while(  `ifdef HALT_ON_ILLEGAL_INSTRUCTION
                    uut.iaddr < MEMORY_DEPTH-4 && !(uut.core_inst.csr_inst.i_is_inst_illegal && uut.core_inst.csr_inst.i_ce) //exception testing (halt core only when instruction is illegal)
                `elsif HALT_ON_EBREAK
                    !uut.core_inst.execute_exception[`EBREAK] //ebreak test (halt core on ebreak)
                `elsif HALT_ON_ECALL
                    !uut.core_inst.execute_exception[`ECALL] //ecall test (halt core on ecall)
                `else
                    !uut.core_inst.execute_exception[`ECALL] && !uut.core_inst.execute_exception[`EBREAK] //normal test (halt core on ebreak/ecall)
                `endif
             ) begin
             
            
            @(negedge clk);
            `ifdef DISPLAY
            if(!uut.core_inst.memory_stall && uut.core_inst.csr_inst.csr_enable) begin //csr is written
                $display("\nPC: %h    %h [%s]\n  [CSR] address:0x%0h   value:0x%h ",uut.core_inst.csr_inst.execute_pc, uut.main_memory_inst.memory[{uut.core_inst.csr_inst.execute_pc}>>2],"SYSTEM",uut.core_inst.csr_inst.execute_imm,uut.core_inst.csr_inst.csr_in); //display address of csr changed and its new value
            end
            
            if(uut.core_inst.writeback_clk_en && !uut.core_inst.writeback_stall) begin
                    $display("time = %0t", $time);
                    if(uut.core_inst.memory_opcode_type[`RTYPE]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"RTYPE"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`ITYPE]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"ITYPE"); //Display PC and instruction      
                    else if(uut.core_inst.memory_opcode_type[`LOAD]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"LOAD"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`STORE]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"STORE"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`BRANCH]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"BRANCH"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`JAL]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"JAL"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`JALR]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"JALR"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`LUI]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"LUI"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`AUIPC]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"AUIPC"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`SYSTEM]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"SYSTEM"); //Display PC and instruction 
                    else if(uut.core_inst.memory_opcode_type[`FENCE]) $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"FENCE"); //Display PC and instruction 
                    else $display("\nPC: %h    %h [%s]", uut.core_inst.writeback_inst.memory_pc, uut.main_memory_inst.memory[{uut.core_inst.writeback_inst.memory_pc}>>2],"UNKNOWN INSTRUCTION"); //Display PC and instruction 
                    
                #1;
                if(uut.core_inst.go_to_trap) begin //exception or interrupt detected
                    case({uut.core_inst.csr_inst.mcause_intbit,uut.core_inst.csr_inst.mcause_code})
                        {1'b1,4'd3}: $display("  GO TO TRAP: %s","SOFTWARE INTERRUPT");
                        {1'b1,4'd7}: $display("  GO TO TRAP: %s","TIMER INTERRUPT");
                    {1'b1,4'd11}: $display("  GO TO TRAP: %s","EXTERNAL INTERRUPT"); 
                        {1'b0,4'd0}: $display("  GO TO TRAP: %s","INSTRUCTION ADDRESS MISALIGNED");
                        {1'b0,4'd2}: $display("  GO TO TRAP: %s","ILLEGAL INSTRUCTION");
                        {1'b0,4'd3}: $display("  GO TO TRAP: %s","EBREAK"); 
                        {1'b0,4'd4}: $display("  GO TO TRAP: %s","LOAD ADDRESS MISALIGNED"); 
                        {1'b0,4'd6}: $display("  GO TO TRAP: %s","STORE ADDRESS MISALIGNED"); 
                    {1'b0,4'd11}: $display("  GO TO TRAP: %s","ECALL");
                            default: $display("  GO TO TRAP: %s","UNKNOWN TRAP");
                    endcase
                end
                 if(uut.main_memory_inst.wb_wr_en) begin //data memory is written
                    $display("  [MEMORY] address:0x%h   value:0x%h [MASK:%b]",uut.main_memory_inst.wb_addr,uut.main_memory_inst.wb_wr_data,uut.main_memory_inst.wb_wr_sel); //display address of memory changed and its new value
                end
                
                if(uut.core_inst.writeback_inst.writeback_rd_wr_en && uut.core_inst.writeback_inst.writeback_rd!=0) begin //base register is written
                    $display("  [BASEREG] address:0x%0d   value:0x%h",uut.core_inst.writeback_inst.writeback_rd,uut.core_inst.writeback_inst.writeback_rd_wr_data); //display address of base reg changed and its new value
                end
                
                if(uut.core_inst.return_from_trap) begin
                    $display("  RETURN FROM TRAP"); //go back from trap via mret
                end
                
            end
            #1; 
            `endif
        
        end

        
        @(negedge clk);
        $display("\nAll instructions executed......");
        
        /************* Dump Base Register and Memory Values *******************/
        $display("\nFinal Register State:");
        
        for(i=0; i<8; i=i+1) begin
            for(j=0; j<4 ; j=j+1) begin
                $write("0x%02d: 0x%h\t",4*i+j,uut.core_inst.regs_inst.x[4*i+j]);
            end
            $write("\n");
        end
        $display("\n\nFinal Memory State:");
        for(i=DATA_START_ADDR; i<(DATA_START_ADDR+10*4) ; i=i+4) begin
            $display("0x%0h: 0x%h",i,uut.main_memory_inst.memory[i>>2]);
        end
       
        /***********************************************************************/
        // if(ZICSR_EXTENSION != 0) begin
            if(uut.core_inst.regs_inst.x[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
                if(uut.core_inst.regs_inst.x[10] == 0)
                    $display("\n\033[92mPASS\033[00m: exit code = 0x%h \n[%0d instructions in %0d clk cycles]\n",uut.core_inst.regs_inst.x[10]>>1,uut.core_inst.csr_inst.minstret,uut.core_inst.csr_inst.mcycle);
                else begin
                    $display("\n\033[91mFAIL\033[00m: exit code = 0x%h \n[%0d instructions in %0d clk cycles]\n",uut.core_inst.regs_inst.x[10]>>1,uut.core_inst.csr_inst.minstret,uut.core_inst.csr_inst.mcycle);
                end
            end
            else $display("\nUNKNOWN: basereg[17] = 0x%h (must be 0x0000005d)",uut.core_inst.regs_inst.x[17]);
        // end
        // else begin
        //     if(uut.core_inst.regs_inst.x[17] == 32'h5d) begin //Exit test using RISC-V International's riscv-tests pass/fail criteria
        //         if(uut.core_inst.regs_inst.x[10] == 0)
        //             $display("\n\033[92mPASS\033[00m: exit code = 0x%h\n",uut.core_inst.regs_inst.x[10]>>1);
        //         else begin
        //             $display("\n\033[91mFAIL\033[00m: exit code = 0x%h\n",uut.core_inst.regs_inst.x[10]>>1);
        //         end
        //     end
        //     else $display("\nUNKNOWN: basereg[17] = 0x%h (must be 0x0000005d)",uut.core_inst.regs_inst.x[17]);
        // end
        $finish;
        
        /**************************************************************************************************************************/
        
    end
	initial begin
		#100_000; //simulation time limit
		`ifdef LONGER_SIM_LIMIT
		#25_000_000;
		`endif
		$finish;
	end
endmodule
