// ============================================
// AHB Interface — All signals in one bundle
// Author: Saravana Kumar T J A
// ============================================
interface ahb_if (input logic HCLK, input logic HRESETn);

    logic [31:0] HADDR;
    logic [1:0]  HTRANS;
    logic        HWRITE;
    logic [2:0]  HSIZE;
    logic [2:0]  HBURST;
    logic        HSEL;
    logic [31:0] HWDATA;
    logic [31:0] HRDATA;
    logic        HREADY;
    logic [1:0]  HRESP;

    clocking monitor_cb @(posedge HCLK);
        default input #1;
        input HADDR, HTRANS, HWRITE, HSIZE, HBURST;
        input HSEL, HWDATA, HRDATA, HREADY, HRESP;
    endclocking

    modport MASTER (
        output HADDR, HTRANS, HWRITE, HSIZE, HBURST, HSEL, HWDATA,
        input  HRDATA, HREADY, HRESP,
        input  HCLK, HRESETn
    );

    modport SLAVE (
        input  HADDR, HTRANS, HWRITE, HSIZE, HBURST, HSEL, HWDATA,
        output HRDATA, HREADY, HRESP,
        input  HCLK, HRESETn
    );

    modport MONITOR (clocking monitor_cb, input HCLK, HRESETn);

endinterface
