// ============================================
// APB Master — Stimulus Generator
// Generates: writes, reads, back-to-back,
//            out-of-range, reset during transfer
// Author: Saravana Kumar T J A
// ============================================
module apb_master (
    input  wire        PCLK,
    input  wire        PRESETn,
    output reg  [31:0] PADDR,
    output reg         PSEL,
    output reg         PENABLE,
    output reg         PWRITE,
    output reg  [31:0] PWDATA,
    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR
);

    // State machine — renamed to avoid keyword clash
    localparam ST_IDLE   = 2'd0;
    localparam ST_SETUP  = 2'd1;
    localparam ST_ENABLE = 2'd2;

    reg [1:0] state;

    // Transaction queue
    reg [31:0] q_addr  [0:9];
    reg [31:0] q_data  [0:9];
    reg        q_write [0:9];
    reg [3:0]  q_head;
    reg [3:0]  q_tail;
    reg        q_empty;

    integer j;
    initial begin
        // Initialize outputs
        PADDR   = 32'd0;
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PWDATA  = 32'd0;
        state   = ST_IDLE;
        q_head  = 4'd0;
        q_tail  = 4'd0;
        q_empty = 1'b1;

        // Load test transactions
        // Writes
        q_addr[0] = 32'h00000000; q_data[0] = 32'hDEADBEEF; q_write[0] = 1'b1;
        q_addr[1] = 32'h00000004; q_data[1] = 32'hCAFEBABE; q_write[1] = 1'b1;
        q_addr[2] = 32'h00000008; q_data[2] = 32'h12345678; q_write[2] = 1'b1;
        // Reads
        q_addr[3] = 32'h00000000; q_data[3] = 32'h00000000; q_write[3] = 1'b0;
        q_addr[4] = 32'h00000004; q_data[4] = 32'h00000000; q_write[4] = 1'b0;
        // Out of range — triggers PSLVERR
        q_addr[5] = 32'hFFFFFFFF; q_data[5] = 32'hBAD0DEAD; q_write[5] = 1'b1;
        // Back to back writes
        q_addr[6] = 32'h0000000C; q_data[6] = 32'hAAAAAAAA; q_write[6] = 1'b1;
        q_addr[7] = 32'h00000010; q_data[7] = 32'hBBBBBBBB; q_write[7] = 1'b1;
        // Read back
        q_addr[8] = 32'h0000000C; q_data[8] = 32'h00000000; q_write[8] = 1'b0;
        q_addr[9] = 32'h00000010; q_data[9] = 32'h00000000; q_write[9] = 1'b0;

        q_tail  = 4'd10;
        q_empty = 1'b0;
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PADDR   <= 32'd0;
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b0;
            PWDATA  <= 32'd0;
            state   <= ST_IDLE;
        end
        else begin
            case (state)

                ST_IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                    if (!q_empty && (q_head < q_tail)) begin
                        PADDR  <= q_addr[q_head];
                        PWDATA <= q_data[q_head];
                        PWRITE <= q_write[q_head];
                        PSEL   <= 1'b1;
                        state  <= ST_SETUP;
                    end
                end

                ST_SETUP: begin
                    PENABLE <= 1'b1;
                    state   <= ST_ENABLE;
                end

                ST_ENABLE: begin
                    if (PREADY) begin
                        PENABLE <= 1'b0;
                        PSEL    <= 1'b0;
                        q_head  <= q_head + 4'd1;
                        if ((q_head + 4'd1) >= q_tail)
                            q_empty <= 1'b1;
                        state <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
