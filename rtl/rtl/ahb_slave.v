// ============================================
// AHB Slave — Device Under Test
// 256 x 32-bit word memory (1KB)
// Supports: SINGLE, INCR4, INCR8 bursts
// Pipelined: address and data phases overlap
// Author: Saravana Kumar T J A
// ============================================
module ahb_slave (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [2:0]  HBURST,
    input  wire        HSEL,
    input  wire [31:0] HWDATA,
    output reg  [31:0] HRDATA,
    output reg         HREADY,
    output reg  [1:0]  HRESP
);

    // 1KB memory
    reg [31:0] mem [0:255];

    // HTRANS encoding
    localparam IDLE   = 2'b00;
    localparam BUSY   = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam SEQ    = 2'b11;

    // HRESP encoding
    localparam OKAY  = 2'b00;
    localparam ERROR = 2'b01;

    // Pipeline registers — capture address phase
    reg [31:0] haddr_r;
    reg        hwrite_r;
    reg        hsel_r;
    reg        htrans_active_r;

    // Valid address check
    wire addr_valid = (HADDR[31:10] == 22'd0);

    // Active transfer
    wire active = HSEL && (HTRANS == NONSEQ || HTRANS == SEQ);

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;
    end

    // ── Address phase pipeline register ───────
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            haddr_r        <= 32'd0;
            hwrite_r       <= 1'b0;
            hsel_r         <= 1'b0;
            htrans_active_r<= 1'b0;
        end
        else if (HREADY) begin
            haddr_r        <= HADDR;
            hwrite_r       <= HWRITE;
            hsel_r         <= HSEL;
            htrans_active_r<= active;
        end
    end

    // ── Data phase — read/write memory ────────
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA <= 32'd0;
            HREADY <= 1'b1;
            HRESP  <= OKAY;
        end
        else begin
            HREADY <= 1'b1;
            HRESP  <= OKAY;

            if (hsel_r && htrans_active_r) begin
                if (haddr_r[31:10] != 22'd0) begin
                    // Out-of-range — ERROR response
                    HRESP  <= ERROR;
                    HREADY <= 1'b0; // ERROR needs 2 cycles
                end
                else if (hwrite_r) begin
                    // Write data phase
                    mem[haddr_r[9:2]] <= HWDATA;
                end
                else begin
                    // Read data phase
                    HRDATA <= mem[haddr_r[9:2]];
                end
            end
        end
    end

endmodule
