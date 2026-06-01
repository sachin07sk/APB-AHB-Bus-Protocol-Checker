// ============================================
// AHB Monitor
// Watches pipelined address and data phases
// Reports all transfers
// Author: Saravana Kumar T J A
// ============================================
module ahb_monitor (
    input logic        HCLK,
    input logic        HRESETn,
    input logic [31:0] HADDR,
    input logic [1:0]  HTRANS,
    input logic        HWRITE,
    input logic [2:0]  HBURST,
    input logic        HSEL,
    input logic [31:0] HWDATA,
    input logic [31:0] HRDATA,
    input logic        HREADY,
    input logic [1:0]  HRESP
);

    localparam NONSEQ = 2'b10;
    localparam SEQ    = 2'b11;

    int unsigned wr_count  = 0;
    int unsigned rd_count  = 0;
    int unsigned err_count = 0;

    // Pipeline: capture address phase
    reg [31:0] addr_pipe;
    reg        write_pipe;
    reg        active_pipe;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_pipe  <= 32'd0;
            write_pipe <= 1'b0;
            active_pipe<= 1'b0;
        end
        else if (HREADY) begin
            addr_pipe   <= HADDR;
            write_pipe  <= HWRITE;
            active_pipe <= HSEL && (HTRANS == NONSEQ || HTRANS == SEQ);
        end
    end

    // Data phase monitoring
    always @(posedge HCLK) begin
        if (HRESETn && HREADY && active_pipe) begin
            if (HRESP == 2'b01) begin
                err_count++;
                $display("[AHB MON] t=%0t | ERROR  | ADDR=0x%08h",
                    $time, addr_pipe);
            end
            else if (write_pipe) begin
                wr_count++;
                $display("[AHB MON] t=%0t | WRITE  | ADDR=0x%08h DATA=0x%08h",
                    $time, addr_pipe, HWDATA);
            end
            else begin
                rd_count++;
                $display("[AHB MON] t=%0t | READ   | ADDR=0x%08h DATA=0x%08h",
                    $time, addr_pipe, HRDATA);
            end
        end
    end

    final begin
        $display("");
        $display("=========================================");
        $display(" AHB MONITOR SUMMARY");
        $display(" Writes  : %0d", wr_count);
        $display(" Reads   : %0d", rd_count);
        $display(" Errors  : %0d", err_count);
        $display("=========================================");
    end

endmodule
