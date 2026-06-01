// ============================================
// APB Protocol Checker
// Procedural checks (complement to SVA)
// Tracks state machine and reports violations
// Author: Saravana Kumar T J A
// ============================================
module apb_checker (
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

    // State tracking
    localparam S_IDLE   = 2'd0;
    localparam S_SETUP  = 2'd1;
    localparam S_ENABLE = 2'd2;

    reg [1:0]  apb_state;
    reg [31:0] captured_addr;
    reg        captured_write;
    reg [31:0] captured_data;

    // Statistics
    int pass_count = 0;
    int fail_count = 0;

    // State machine tracker
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            apb_state <= S_IDLE;
        end
        else begin
            case (apb_state)
                S_IDLE: begin
                    if (PSEL && !PENABLE) begin
                        apb_state      <= S_SETUP;
                        captured_addr  <= PADDR;
                        captured_write <= PWRITE;
                        captured_data  <= PWDATA;
                    end
                end
                S_SETUP: begin
                    apb_state <= S_ENABLE;
                end
                S_ENABLE: begin
                    if (PREADY)
                        apb_state <= PSEL ? S_SETUP : S_IDLE;
                end
            endcase
        end
    end

    // Checker task
    task check(input logic condition, input string msg);
        if (condition) begin
            pass_count++;
        end else begin
            fail_count++;
            $display("[APB CHK] FAIL t=%0t | %s", $time, msg);
        end
    endtask

    // Protocol checks every cycle
    always @(posedge PCLK) begin
        if (PRESETn) begin

            // Check PENABLE only after SETUP
            if (PENABLE)
                check(PSEL, "R01: PENABLE=1 but PSEL=0");

            // Check address stability during ENABLE
            if (apb_state == S_ENABLE)
                check((PADDR == captured_addr),
                      "R03: PADDR changed during ENABLE phase");

            // Check PWRITE stability
            if (apb_state == S_ENABLE)
                check((PWRITE == captured_write),
                      "R04: PWRITE changed during ENABLE phase");

            // Check PWDATA stability (write only)
            if (apb_state == S_ENABLE && PWRITE)
                check((PWDATA == captured_data),
                      "R05: PWDATA changed during ENABLE phase");

            // Check PSLVERR only with PREADY
            if (PSLVERR)
                check(PREADY,
                      "R08: PSLVERR=1 without PREADY=1");

            // Check no transfer during reset
            if (!PRESETn)
                check((!PSEL && !PENABLE),
                      "R09: Transfer active during reset");

            // Check word alignment
            if (PSEL)
                check((PADDR[1:0] == 2'b00),
                      "R10: PADDR not word-aligned");
        end
    end

    // Final report
    final begin
        $display("");
        $display("=========================================");
        $display(" APB CHECKER RESULTS");
        $display(" PASSED : %0d", pass_count);
        $display(" FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS : ALL APB CHECKS PASSED ✓");
        else
            $display(" STATUS : %0d VIOLATIONS FOUND ✗", fail_count);
        $display("=========================================");
    end

endmodule
