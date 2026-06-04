// ============================================
// AHB Master — Stimulus Generator
// Generates: SINGLE, INCR4, INCR8 transfers
// Implements pipelined address/data phases
// Author: Saravana Kumar T J A
// ============================================
module ahb_master (
    input  wire        HCLK,
    input  wire        HRESETn,
    output reg  [31:0] HADDR,
    output reg  [1:0]  HTRANS,
    output reg         HWRITE,
    output reg  [2:0]  HSIZE,
    output reg  [2:0]  HBURST,
    output reg         HSEL,
    output reg  [31:0] HWDATA,
    input  wire [31:0] HRDATA,
    input  wire        HREADY,
    input  wire [1:0]  HRESP
);

    localparam IDLE   = 2'b00;
    localparam NONSEQ = 2'b10;
    localparam SEQ    = 2'b11;

    localparam SINGLE = 3'b000;
    localparam INCR4  = 3'b011;
    localparam INCR8  = 3'b101;

    // Test state machine
    localparam T_IDLE      = 4'd0;
    localparam T_SINGLE_WR = 4'd1;
    localparam T_SINGLE_RD = 4'd2;
    localparam T_INCR4_WR  = 4'd3;
    localparam T_INCR4_RD  = 4'd4;
    localparam T_INCR8_WR  = 4'd5;
    localparam T_DONE      = 4'd6;

    reg [3:0]  test_state;
    reg [3:0]  beat_count;
    reg [31:0] base_addr;
    reg [31:0] wr_data;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR      <= 32'd0;
            HTRANS     <= IDLE;
            HWRITE     <= 1'b0;
            HSIZE      <= 3'b010;
            HBURST     <= SINGLE;
            HSEL       <= 1'b0;
            HWDATA     <= 32'd0;
            test_state <= T_SINGLE_WR;
            beat_count <= 4'd0;
            base_addr  <= 32'h00000100;
            wr_data    <= 32'hA0000000;
        end
        else if (HREADY) begin
            case (test_state)

                // ── Test 1: Single Write ───────────
                T_SINGLE_WR: begin
                    HSEL    <= 1'b1;
                    HADDR   <= base_addr;
                    HTRANS  <= NONSEQ;
                    HWRITE  <= 1'b1;
                    HSIZE   <= 3'b010;
                    HBURST  <= SINGLE;
                    HWDATA  <= wr_data;
                    test_state <= T_SINGLE_RD;
                end

                // ── Test 2: Single Read ────────────
                T_SINGLE_RD: begin
                    HADDR   <= base_addr;
                    HTRANS  <= NONSEQ;
                    HWRITE  <= 1'b0;
                    HBURST  <= SINGLE;
                    HWDATA  <= 32'd0;
                    beat_count <= 4'd0;
                    test_state <= T_INCR4_WR;
                end

                // ── Test 3: INCR4 Write Burst ──────
                T_INCR4_WR: begin
                    if (beat_count == 4'd0) begin
                        HTRANS  <= NONSEQ;
                        HBURST  <= INCR4;
                        HWRITE  <= 1'b1;
                        HADDR   <= base_addr + 32'h10;
                    end
                    else begin
                        HTRANS <= SEQ;
                        HADDR  <= HADDR + 32'd4;
                    end
                    HWDATA     <= wr_data + {28'd0, beat_count};
                    beat_count <= beat_count + 1;

                    if (beat_count == 4'd3) begin
                        beat_count <= 4'd0;
                        test_state <= T_INCR4_RD;
                    end
                end

                // ── Test 4: INCR4 Read Burst ───────
                T_INCR4_RD: begin
                    if (beat_count == 4'd0) begin
                        HTRANS <= NONSEQ;
                        HBURST <= INCR4;
                        HWRITE <= 1'b0;
                        HADDR  <= base_addr + 32'h10;
                    end
                    else begin
                        HTRANS <= SEQ;
                        HADDR  <= HADDR + 32'd4;
                    end
                    beat_count <= beat_count + 1;

                    if (beat_count == 4'd3) begin
                        beat_count <= 4'd0;
                        test_state <= T_INCR8_WR;
                    end
                end

                // ── Test 5: INCR8 Write Burst ──────
                T_INCR8_WR: begin
                    if (beat_count == 4'd0) begin
                        HTRANS <= NONSEQ;
                        HBURST <= INCR8;
                        HWRITE <= 1'b1;
                        HADDR  <= base_addr + 32'h40;
                    end
                    else begin
                        HTRANS <= SEQ;
                        HADDR  <= HADDR + 32'd4;
                    end
                    HWDATA     <= wr_data + {28'd0, beat_count} + 32'h100;
                    beat_count <= beat_count + 1;

                    if (beat_count == 4'd7) begin
                        test_state <= T_DONE;
                    end
                end

                // ── All tests done ─────────────────
                T_DONE: begin
                    HTRANS <= IDLE;
                    HSEL   <= 1'b0;
                end

                default: test_state <= T_DONE;
            endcase
        end
    end

endmodule
