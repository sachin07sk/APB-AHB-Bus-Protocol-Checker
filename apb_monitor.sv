// ============================================
// APB Monitor
// Watches all APB signals every cycle
// Reports transfer details and violations
// Author: Saravana Kumar T J A
// ============================================
`include "uvm_macros.svh"
import uvm_pkg::*;

module apb_monitor (
    input logic        PCLK,
    input logic        PRESETn,
    input logic [31:0] PADDR,
    input logic        PSEL,
    input logic        PENABLE,
    input logic        PWRITE,
    input logic [31:0] PWDATA,
    input logic [31:0] PRDATA,
    input logic        PREADY,
    input logic        PSLVERR
);

    // Transaction counter
    int unsigned wr_count = 0;
    int unsigned rd_count = 0;
    int unsigned err_count = 0;

    // Watch every clock edge
    always @(posedge PCLK) begin
        if (PRESETn) begin

            // Detect transfer completion
            if (PENABLE && PREADY) begin
                if (PSLVERR) begin
                    err_count++;
                    $display("[APB MON] t=%0t | ERROR  | ADDR=0x%08h PSLVERR=1",
                             $time, PADDR);
                end
                else if (PWRITE) begin
                    wr_count++;
                    $display("[APB MON] t=%0t | WRITE  | ADDR=0x%08h DATA=0x%08h",
                             $time, PADDR, PWDATA);
                end
                else begin
                    rd_count++;
                    $display("[APB MON] t=%0t | READ   | ADDR=0x%08h DATA=0x%08h",
                             $time, PADDR, PRDATA);
                end
            end

            // Detect setup phase
            if (PSEL && !PENABLE)
                $display("[APB MON] t=%0t | SETUP  | ADDR=0x%08h %s",
                    $time, PADDR, PWRITE ? "WRITE" : "READ");

        end
    end

    // Final summary
    final begin
        $display("");
        $display("=========================================");
        $display(" APB MONITOR SUMMARY");
        $display(" Writes  : %0d", wr_count);
        $display(" Reads   : %0d", rd_count);
        $display(" Errors  : %0d", err_count);
        $display("=========================================");
    end

endmodule
