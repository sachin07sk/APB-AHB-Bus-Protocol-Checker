// ============================================
// Protocol Testbench Top
// Instantiates: APB + AHB DUT, interfaces,
//               monitors, checkers, assertions
// Author: Saravana Kumar T J A
// ============================================
`timescale 1ns/1ps

module protocol_tb;

    // ── Clock and Reset ───────────────────────
    logic PCLK, PRESETn;
    logic HCLK, HRESETn;

    // 10ns clock = 100MHz
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    initial HCLK = 0;
    always #5 HCLK = ~HCLK;

    // Reset — active LOW, deassert after 5 cycles
    initial begin
        PRESETn = 0;
        HRESETn = 0;
        repeat(5) @(posedge PCLK);
        PRESETn = 1;
        HRESETn = 1;
        $display("[TB] Reset released at t=%0t", $time);
    end

    // ══════════════════════════════════════════
    // APB SIDE
    // ══════════════════════════════════════════

    // APB signals
    wire [31:0] PADDR;
    wire        PSEL, PENABLE, PWRITE;
    wire [31:0] PWDATA, PRDATA;
    wire        PREADY, PSLVERR;

    // APB Master (stimulus)
    apb_master u_apb_master (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );

    // APB Slave (DUT)
    apb_slave u_apb_slave (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );

    // APB Monitor
    apb_monitor u_apb_mon (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );

    // APB Checker
    apb_checker u_apb_chk (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );

    // APB SVA Assertions
    apb_assertions u_apb_sva (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR)
    );

    // ══════════════════════════════════════════
    // AHB SIDE
    // ══════════════════════════════════════════

    wire [31:0] HADDR;
    wire [1:0]  HTRANS;
    wire        HWRITE;
    wire [2:0]  HSIZE, HBURST;
    wire        HSEL;
    wire [31:0] HWDATA, HRDATA;
    wire        HREADY;
    wire [1:0]  HRESP;

    // AHB Master
    ahb_master u_ahb_master (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),
        .HADDR   (HADDR),
        .HTRANS  (HTRANS),
        .HWRITE  (HWRITE),
        .HSIZE   (HSIZE),
        .HBURST  (HBURST),
        .HSEL    (HSEL),
        .HWDATA  (HWDATA),
        .HRDATA  (HRDATA),
        .HREADY  (HREADY),
        .HRESP   (HRESP)
    );

    // AHB Slave
    ahb_slave u_ahb_slave (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),
        .HADDR   (HADDR),
        .HTRANS  (HTRANS),
        .HWRITE  (HWRITE),
        .HSIZE   (HSIZE),
        .HBURST  (HBURST),
        .HSEL    (HSEL),
        .HWDATA  (HWDATA),
        .HRDATA  (HRDATA),
        .HREADY  (HREADY),
        .HRESP   (HRESP)
    );

    // AHB Monitor
    ahb_monitor u_ahb_mon (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),
        .HADDR   (HADDR),
        .HTRANS  (HTRANS),
        .HWRITE  (HWRITE),
        .HBURST  (HBURST),
        .HSEL    (HSEL),
        .HWDATA  (HWDATA),
        .HRDATA  (HRDATA),
        .HREADY  (HREADY),
        .HRESP   (HRESP)
    );

    // AHB Checker
    ahb_checker u_ahb_chk (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),
        .HADDR   (HADDR),
        .HTRANS  (HTRANS),
        .HWRITE  (HWRITE),
        .HBURST  (HBURST),
        .HSEL    (HSEL),
        .HWDATA  (HWDATA),
        .HREADY  (HREADY),
        .HRESP   (HRESP)
    );

    // AHB SVA Assertions
    ahb_assertions u_ahb_sva (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),
        .HADDR   (HADDR),
        .HTRANS  (HTRANS),
        .HWRITE  (HWRITE),
        .HSIZE   (HSIZE),
        .HBURST  (HBURST),
        .HSEL    (HSEL),
        .HWDATA  (HWDATA),
        .HRDATA  (HRDATA),
        .HREADY  (HREADY),
        .HRESP   (HRESP)
    );

    // ══════════════════════════════════════════
    // Simulation Control
    // ══════════════════════════════════════════

    // Waveform dump
    initial begin
        $dumpfile("sim/protocol_waves.vcd");
        $dumpvars(0, protocol_tb);
    end

    // Run for enough time then stop
    initial begin
        $display("=========================================");
        $display(" APB/AHB Protocol Checker — Simulation");
        $display("=========================================");
        #5000;
        $display("[TB] Simulation complete at t=%0t", $time);
        $finish;
    end

    // Timeout watchdog
    initial begin
        #100_000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
