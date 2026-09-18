module cn_proc
#(
    parameter GROUP = 19,
    parameter WIDTH = 32
)
(
    input  [WIDTH-1:0] t1data,
    input  [WIDTH-1:0] t2data,
    input  [WIDTH-1:0] t3data,
    input  [WIDTH-1:0] t4data,
    input  [WIDTH-1:0] t5data,
    input  [WIDTH-1:0] t6data,
    input  [WIDTH-1:0] t7data,
    input  [WIDTH-1:0] t8data,
    input  [WIDTH-1:0] t9data,
    input  [WIDTH-1:0] t10data,
    input  [WIDTH-1:0] t11data,
    input  [WIDTH-1:0] t12data,
    input  [WIDTH-1:0] t13data,
    input  [WIDTH-1:0] t14data,
    input  [WIDTH-1:0] t15data,
    input  [WIDTH-1:0] t16data,
    input  [WIDTH-1:0] t17data,
    input  [WIDTH-1:0] t18data,
    input  [WIDTH-1:0] t19data,

    input  t1load,
    input  t2load,
    input  t3load,
    input  t4load,
    input  t5load,
    input  t6load,
    input  t7load,
    input  t8load,
    input  t9load,
    input  t10load,
    input  t11load,
    input  t12load,
    input  t13load,
    input  t14load,
    input  t15load,
    input  t16load,
    input  t17load,
    input  t18load,
    input  t19load,

    input  [0:0] t1opcode,

    output [WIDTH-1:0] r1data,
    output [WIDTH-1:0] r2data,
    output [WIDTH-1:0] r3data,
    output [WIDTH-1:0] r4data,
    output [WIDTH-1:0] r5data,
    output [WIDTH-1:0] r6data,
    output [WIDTH-1:0] r7data,
    output [WIDTH-1:0] r8data,
    output [WIDTH-1:0] r9data,
    output [WIDTH-1:0] r10data,
    output [WIDTH-1:0] r11data,
    output [WIDTH-1:0] r12data,
    output [WIDTH-1:0] r13data,
    output [WIDTH-1:0] r14data,
    output [WIDTH-1:0] r15data,
    output [WIDTH-1:0] r16data,
    output [WIDTH-1:0] r17data,
    output [WIDTH-1:0] r18data,
    output [WIDTH-1:0] r19data,

    input clk,
    input rstx,
    input glock
);

    /*
     * CHECK_NODE_19 is the only operation implemented by this FU.
     *
     * Since it is the only operation, its opcode is 0.
     */
    localparam [0:0] OPC_CHECK_NODE_19 = 1'b0;


    /*
     * Input registers.
     *
     * The values are IEEE-754 single-precision floating-point
     * bit patterns. They are deliberately treated as unsigned
     * vectors here; no Verilog integer arithmetic is performed
     * on the floating-point representation.
     */
    reg [WIDTH-1:0] in_reg [0:GROUP-1];


    /*
     * Output registers.
     */
    reg [WIDTH-1:0] out_reg [0:GROUP-1];


    /*
     * Temporary combinational values.
     */
    reg [WIDTH-1:0] abs_val [0:GROUP-1];

    reg [WIDTH-1:0] min_val;
    reg             parity;

    integer i;
    integer idx;


    /*
     * Input registers.
     *
     * Each architectural input port has an associated load
     * signal, following the OpenASIP FU interface convention.
     *
     * glock prevents the FU state from changing while the
     * processor is globally locked.
     */
    always @(posedge clk or negedge rstx) begin

        if (!rstx) begin

            for (i = 0; i < GROUP; i = i + 1)
                in_reg[i] <= {WIDTH{1'b0}};

        end
        else if (!glock) begin

            if (t1load)
                in_reg[0] <= t1data;

            if (t2load)
                in_reg[1] <= t2data;

            if (t3load)
                in_reg[2] <= t3data;

            if (t4load)
                in_reg[3] <= t4data;

            if (t5load)
                in_reg[4] <= t5data;

            if (t6load)
                in_reg[5] <= t6data;

            if (t7load)
                in_reg[6] <= t7data;

            if (t8load)
                in_reg[7] <= t8data;

            if (t9load)
                in_reg[8] <= t9data;

            if (t10load)
                in_reg[9] <= t10data;

            if (t11load)
                in_reg[10] <= t11data;

            if (t12load)
                in_reg[11] <= t12data;

            if (t13load)
                in_reg[12] <= t13data;

            if (t14load)
                in_reg[13] <= t14data;

            if (t15load)
                in_reg[14] <= t15data;

            if (t16load)
                in_reg[15] <= t16data;

            if (t17load)
                in_reg[16] <= t17data;

            if (t18load)
                in_reg[17] <= t18data;

            if (t19load)
                in_reg[18] <= t19data;

        end

    end


    /*
     * CHECK_NODE_19
     *
     * For output i:
     *
     *     out[i] =
     *         min(j != i) |in[j]|
     *         *
     *         product(j != i) sign(in[j])
     *
     * The implementation operates directly on the IEEE-754
     * representation.
     */
    always @(*) begin : check_node

        /*
         * Absolute value.
         *
         * IEEE-754 single precision:
         *
         *   bit 31      = sign
         *   bits 30:23  = exponent
         *   bits 22:0   = mantissa
         *
         * Clearing bit 31 gives the absolute-value bit pattern.
         */
        for (i = 0; i < GROUP; i = i + 1) begin

            abs_val[i] =
                in_reg[i] &
                {1'b0, {(WIDTH-1){1'b1}}};

        end


        /*
         * Generate one extrinsic check-node result for each
         * input message.
         */
        for (idx = 0; idx < GROUP; idx = idx + 1) begin

            /*
             * Equivalent to:
             *
             *     float min = FLT_MAX;
             *
             * in the C++ implementation.
             */
            min_val = 32'h7F7FFFFF;

            /*
             * XOR of signs implements the sign product.
             *
             * 0 -> positive
             * 1 -> negative
             */
            parity = 1'b0;


            /*
             * Exclude the input corresponding to this output.
             */
            for (i = 0; i < GROUP; i = i + 1) begin

                if (i != idx) begin

                    /*
                     * Since abs_val has sign bit 0, unsigned
                     * comparison gives the correct ordering
                     * for finite non-negative IEEE-754 values.
                     */
                    if (abs_val[i] < min_val)
                        min_val = abs_val[i];


                    /*
                     * Product of signs.
                     */
                    parity =
                        parity ^
                        in_reg[i][WIDTH-1];

                end

            end


            /*
             * Reconstruct IEEE-754 result.
             *
             * The magnitude is min_val[30:0].
             * Only the sign bit is replaced.
             */
            out_reg[idx] =
                {parity, min_val[WIDTH-2:0]};

        end

    end


    /*
     * Architecture output ports.
     */
    assign r1data  = out_reg[0];
    assign r2data  = out_reg[1];
    assign r3data  = out_reg[2];
    assign r4data  = out_reg[3];
    assign r5data  = out_reg[4];
    assign r6data  = out_reg[5];
    assign r7data  = out_reg[6];
    assign r8data  = out_reg[7];
    assign r9data  = out_reg[8];
    assign r10data = out_reg[9];
    assign r11data = out_reg[10];
    assign r12data = out_reg[11];
    assign r13data = out_reg[12];
    assign r14data = out_reg[13];
    assign r15data = out_reg[14];
    assign r16data = out_reg[15];
    assign r17data = out_reg[16];
    assign r18data = out_reg[17];
    assign r19data = out_reg[18];

endmodule
