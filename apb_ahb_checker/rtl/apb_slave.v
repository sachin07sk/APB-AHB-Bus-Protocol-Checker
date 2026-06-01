// ============================================
// APB Slave — Device Under Test
// 256 x 32-bit word memory (1KB)
// Supports: read, write, wait states, PSLVERR
// Author: Saravana Kumar T J A
// ============================================
module apb_slave (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [31:0] PADDR,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output reg         PREADY,
    output reg         PSLVERR
);
    // 1KB memory
    reg [31:0] mem [0:255];

    // Wait state counter
    reg [1:0] wait_cnt;

    // Valid address range: 0x000 to 0x3FF
    wire addr_valid = (PADDR[31:10] == 22'd0);

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;
        PREADY  = 1'b0;
        PSLVERR = 1'b0;
        PRDATA  = 32'd0;
        wait_cnt = 2'd0;
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY   <= 1'b0;
            PSLVERR  <= 1'b0;
            PRDATA   <= 32'd0;
            wait_cnt <= 2'd0;
        end
        else begin
            PSLVERR <= 1'b0;
            PREADY  <= 1'b0;

            if (PSEL && PENABLE) begin
                if (wait_cnt < 2'd1) begin
                    // Insert 1 wait state
                    wait_cnt <= wait_cnt + 1;
                    PREADY   <= 1'b0;
                end
                else begin
                    // Transfer completes
                    wait_cnt <= 2'd0;
                    PREADY   <= 1'b1;

                    if (!addr_valid) begin
                        // Out of range — error response
                        PSLVERR <= 1'b1;
                    end
                    else if (PWRITE) begin
                        // Write to memory
                        mem[PADDR[9:2]] <= PWDATA;
                    end
                    else begin
                        // Read from memory
                        PRDATA <= mem[PADDR[9:2]];
                    end
                end
            end
        end
    end

endmodule
