// ============================================
// AHB Protocol Checker
// Procedural burst and state checks
// Author: Saravana Kumar T J A
// ============================================
module ahb_checker (
    input logic        HCLK,
    input logic        HRESETn,
    input logic [31:0] HADDR,
    input logic [1:0]  HTRANS,
    input logic        HWRITE,
    input logic [2:0]  HBURST,
    input logic        HSEL,
    input logic [31:0] HWDATA,
    input logic        HREADY,
    input logic [1:0]  HRESP
);

    localparam IDLE   = 2'b00;
    localparam NONSEQ = 2'b10;
    localparam SEQ    = 2'b11;

    reg [1:0]  prev_htrans;
    reg [31:0] prev_haddr;
    reg [2:0]  burst_count;
    reg        in_burst;

    int pass_count = 0;
    int fail_count = 0;

    task check(input logic cond, input string msg);
        if (cond) pass_count++;
        else begin
            fail_count++;
            $display("[AHB CHK] FAIL t=%0t | %s", $time, msg);
        end
    endtask

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            prev_htrans <= IDLE;
            prev_haddr  <= 32'd0;
            burst_count <= 3'd0;
            in_burst    <= 1'b0;
        end
        else if (HREADY) begin
            prev_htrans <= HTRANS;
            prev_haddr  <= HADDR;

            // Burst tracking
            if (HTRANS == NONSEQ && HBURST != 3'b000) begin
                in_burst    <= 1'b1;
                burst_count <= 3'd1;
            end
            else if (HTRANS == SEQ) begin
                burst_count <= burst_count + 1;
            end
            else if (HTRANS == IDLE) begin
                in_burst    <= 1'b0;
                burst_count <= 3'd0;
            end
        end
    end

    always @(posedge HCLK) begin
        if (HRESETn) begin

            // Rule: SEQ must follow NONSEQ or SEQ
            if (HTRANS == SEQ)
                check((prev_htrans == NONSEQ || prev_htrans == SEQ),
                      "R01: SEQ without prior NONSEQ/SEQ");

            // Rule: HSEL must be high during active transfer
            if (HTRANS == NONSEQ || HTRANS == SEQ)
                check(HSEL, "R08: HSEL=0 during active transfer");

            // Rule: HADDR increments in INCR4 burst
            if (HTRANS == SEQ && HREADY && HBURST == 3'b011)
                check((HADDR == prev_haddr + 32'd4),
                      "R09: HADDR not incrementing in INCR4");

            // Rule: Reset should clear HTRANS
            if (!HRESETn)
                check((HTRANS == IDLE),
                      "R07: HTRANS not IDLE during reset");
        end
    end

    final begin
        $display("");
        $display("=========================================");
        $display(" AHB CHECKER RESULTS");
        $display(" PASSED : %0d", pass_count);
        $display(" FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS : ALL AHB CHECKS PASSED ✓");
        else
            $display(" STATUS : %0d VIOLATIONS FOUND ✗", fail_count);
        $display("=========================================");
    end

endmodule
