// ============================================
// APB Interface
// All APB signals in one bundle
// Author: Saravana Kumar T J A
// ============================================
interface apb_if (input logic PCLK, input logic PRESETn);

    logic [31:0] PADDR;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    // Clocking block for monitor
    clocking monitor_cb @(posedge PCLK);
        default input #1;
        input PADDR, PSEL, PENABLE, PWRITE;
        input PWDATA, PRDATA, PREADY, PSLVERR;
    endclocking

    modport MASTER (
        output PADDR, PSEL, PENABLE, PWRITE, PWDATA,
        input  PRDATA, PREADY, PSLVERR,
        input  PCLK, PRESETn
    );

    modport SLAVE (
        input  PADDR, PSEL, PENABLE, PWRITE, PWDATA,
        output PRDATA, PREADY, PSLVERR,
        input  PCLK, PRESETn
    );

    modport MONITOR (clocking monitor_cb, input PCLK, PRESETn);

endinterface
