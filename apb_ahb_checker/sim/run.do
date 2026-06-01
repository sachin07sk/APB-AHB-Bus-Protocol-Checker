# ============================================
# run.do — APB/AHB Protocol Checker
# QuestaSim 10.4e — Windows
# Hardcoded UVM path — no variable needed
# ============================================

vlib work

# ── Compile RTL (plain Verilog) ───────────
vlog ../rtl/apb_slave.v
vlog ../rtl/apb_master.v
vlog ../rtl/ahb_slave.v
vlog ../rtl/ahb_master.v

# ── Compile TB (SystemVerilog) ────────────
vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/apb_if.sv

vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/apb_assertions.sv

vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/apb_monitor.sv

vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/apb_checker.sv

vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/ahb_if.sv

vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/ahb_assertions.sv

vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/ahb_monitor.sv

vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../tb/ahb_checker.sv

# ── Compile top testbench ─────────────────
vlog -sv +incdir+C:/questasim64_10.4e/verilog_src/uvm-1.1d/src \
    ../sim/protocol_tb.sv

# ── Simulate ──────────────────────────────
vsim -novopt work.protocol_tb

# ── Waves ─────────────────────────────────
add wave -divider "APB SIGNALS"
add wave /protocol_tb/PCLK
add wave /protocol_tb/PRESETn
add wave /protocol_tb/PSEL
add wave /protocol_tb/PENABLE
add wave /protocol_tb/PWRITE
add wave -radix hex /protocol_tb/PADDR
add wave -radix hex /protocol_tb/PWDATA
add wave -radix hex /protocol_tb/PRDATA
add wave /protocol_tb/PREADY
add wave /protocol_tb/PSLVERR

add wave -divider "AHB SIGNALS"
add wave /protocol_tb/HCLK
add wave /protocol_tb/HRESETn
add wave -radix binary /protocol_tb/HTRANS
add wave -radix hex /protocol_tb/HADDR
add wave /protocol_tb/HWRITE
add wave -radix hex /protocol_tb/HWDATA
add wave -radix hex /protocol_tb/HRDATA
add wave /protocol_tb/HREADY
add wave -radix binary /protocol_tb/HRESP

# ── Run ───────────────────────────────────
run -all

echo "========================================"
echo " APB/AHB Simulation Complete"
echo "========================================"
