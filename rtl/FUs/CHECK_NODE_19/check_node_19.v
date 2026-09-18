module cn_proc 
#(
    parameter GROUP = 19,
    parameter WIDTH = 32
)
(
    input signed [GROUP*WIDTH-1:0] in_llr,
    output reg signed [GROUP*WIDTH-1:0] out_llr 
);
    
    integer i;
    integer idx;

    reg [WIDTH-1:0] abs_val [0:GROUP-1];
    always @(*) begin : calculate_abs_qij
        for (i = 0; i < GROUP; i = i + 1) begin
            if (in_llr[(i + 1)*WIDTH - 1] == 1'b1)
                abs_val[i] = -in_llr[i*WIDTH +: WIDTH];
            else
                abs_val[i] = in_llr[i*WIDTH +: WIDTH];
        end
    end

    reg [WIDTH-1:0] min [0:GROUP-1];
    always @(*) begin : find_min_qij
        for (idx = 0; idx < GROUP; idx = idx + 1) begin
            min[idx] = {1'b0, {(WIDTH-1){1'b1}}}; // avoids latches; maximum positive flaot
            for (i = 0; i < GROUP; i = i + 1) begin
                if ((i != idx) && (abs_val[i] < min[idx]))
                    min[idx] = abs_val[i];
            end
    end
    
    reg [0:GROUP-1] prod_sgn_llr;
    always @(*) begin: find_prod_sgn_llr
        for (idx = 0; idx < GROUP; idx = idx + 1) begin
            prod_sgn_llr[idx] = 1'b0; // avoids latches
            for (i = 0; i < GROUP; i = i + 1) begin
                if (i != idx)
                    prod_sgn_llr[idx] = prod_sgn_llr[idx] ^ in_llr[(i + 1)*WIDTH - 1]; // MSB = sign 
            end
        end
    end
    
    always @(*) begin: assign_output_llr  
        for (idx = 0; idx < GROUP; idx = idx + 1) begin
            if (prod_sgn_llr[idx])
                out_llr[idx*WIDTH +: WIDTH] = -min[idx];
            else
                out_llr[idx*WIDTH +: WIDTH] = min[idx];
        end
    end
    
endmodule
