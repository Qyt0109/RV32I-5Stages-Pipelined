# Test hw behavior simulation

# regs
# compile_verilog rtl/regs.sv tb/regs_tb.sv -DDETAILS
# compile_verilog rtl/regs.sv tb/regs_tb.sv

# main_memory
# compile_verilog rtl/main_memory.sv tb/main_memory_tb.sv -DDETAILS
# compile_verilog rtl/main_memory.sv tb/main_memory_tb.sv

# fetch
# compile_verilog rtl/fetch.sv rtl/main_memory.sv tb/fetch_tb.sv -DDETAILS
# compile_verilog rtl/fetch.sv rtl/main_memory.sv tb/fetch_tb.sv

# decode
# compile_verilog rtl/decode.sv rtl/fetch.sv rtl/main_memory.sv tb/decode_tb.sv -DDETAILS
# compile_verilog rtl/decode.sv rtl/fetch.sv rtl/main_memory.sv tb/decode_tb.sv

# execute
compile_verilog rtl/decode.sv rtl/fetch.sv rtl/main_memory.sv rtl/regs.sv rtl/execute.sv tb/execute_tb.sv -DDETAILS
