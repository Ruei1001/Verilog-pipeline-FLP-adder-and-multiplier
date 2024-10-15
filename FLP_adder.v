
module unpack(
    input [31:0] A,
    input [31:0] B,
    output sign_A,         //sign bit
    output sign_B,
    output [7:0] exp_A,    //exponent
    output [7:0] exp_B,
    output [23:0] mant_A,  //mantissa
    output [23:0] mant_B
);
    assign sign_A = A[31];
    assign sign_B = B[31];

    assign exp_A = A[30:23];
    assign exp_B = B[30:23];

    assign mant_A = {1'b1, A[22:0]};
    assign mant_B = {1'b1, B[22:0]};

endmodule

module alignment(
    input sign_A,
    input sign_B,
    input [7:0] exp_A,    //exponent
    input [7:0] exp_B,
    input [23:0] mant_A,  //mantissa
    input [23:0] mant_B,
    output [24:0] mant_A_align,
    output [24:0] mant_B_align,
    output [7:0] exp_common,
    output round_bit
);
    wire [7:0] exp_diff = (exp_A > exp_B) ? (exp_A - exp_B) : (exp_B - exp_A);
    assign round_bit = (exp_A > exp_B) ? mant_B[exp_diff-1] : mant_A[exp_diff-1];
    wire [23:0] mant_A_shifted = (exp_A > exp_B) ? mant_A : (mant_A >> exp_diff);
    wire [23:0] mant_B_shifted = (exp_A > exp_B) ? (mant_B >> exp_diff) : mant_B;
    assign mant_A_align = (sign_A) ? -mant_A_shifted : mant_A_shifted; // Two's complement of A's mantissa [24:0]
    assign mant_B_align = (sign_B) ? -mant_B_shifted : mant_B_shifted;
    //assign mant_A_align = mant_A_shifted;
    //assign mant_B_align = mant_B_shifted;
    assign exp_common = (exp_A > exp_B) ? exp_A : exp_B;
    
 
endmodule

module addition(
    input sign_A,
    input sign_B,
    input [24:0] mant_A_align,
    input [24:0] mant_B_align,
    output [24:0] mant_sum
);
    //assign mant_sum = (sign_A == sign_B) ? (mant_A_shifted + mant_B_shifted) : (mant_A_shifted - mant_B_shifted);
    assign mant_sum = mant_A_align + mant_B_align;

endmodule


module conversion(
    input [24:0] mant_sum,
    output [23:0] mant_conv,
    output sign_norm
);
    //wire [23:0] temp;
    assign sign_norm = mant_sum[24];
    assign mant_conv = (mant_sum[24]) ? (-mant_sum[23:0]) : (mant_sum[23:0]);
    assign sign_norm = (mant_sum[24]) ? 1'b1 : 1'b0;
    
endmodule

module normalization(
    input [23:0] mant_conv,
    input [7:0] exp_common,
    output reg [23:0] mant_norm,
    output reg [7:0] exp_norm
);
    always @(*) begin
        if (mant_conv[23] == 1) begin
            mant_norm = mant_conv; // Already normalized
            exp_norm = exp_common;
        end else begin
            mant_norm = mant_conv << 1;
            exp_norm = exp_common - 1;
        end
    end

endmodule

module rounding(
    input [23:0] mant_norm,
    input round_bit,
    output [23:0] mant_rounded
);
    //wire gaurd_bit = mant_norm[0];
    assign mant_rounded = (round_bit === 1) ? mant_norm + 1 : mant_norm;

endmodule

module packing(
    input sign_norm,
    input [7:0] exp_norm,
    input [23:0] mant_rounded,
    output [31:0] sum
);
    assign sum = {sign_norm, exp_norm, mant_rounded[22:0]};
endmodule

module FLP_adder(
    input [31:0] A,
    input [31:0] B,
    output [31:0] sum


);
    wire sign_A, sign_B;
    wire [7:0] exp_A, exp_B, exp_common, exp_norm;
    wire [23:0] mant_A, mant_B;
    wire [24:0] mant_A_align, mant_B_align;
    wire [24:0] mant_sum;
    wire [23:0] mant_conv, mant_rounded;
    wire round_bit, sign_norm;

    unpack unpackAB(
        .A(A), .B(B), .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B)
    );

    alignment alignAB(
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B),
        .mant_A_align(mant_A_align), .mant_B_align(mant_B_align), .exp_common(exp_common), .round_bit(round_bit)
    );

    addition addAB(
        .sign_A(sign_A), .sign_B(sign_B), .mant_A_align(mant_A_align), .mant_B_align(mant_B_align), .mant_sum(mant_sum)
    );

    conversion conv(
        .mant_sum(mant_sum), .mant_conv(mant_conv), .sign_norm(sign_norm)
    );
    wire [23:0] mant_norm;

    normalization normAB(
        .mant_conv(mant_conv), .exp_common(exp_common), .mant_norm(mant_norm), .exp_norm(exp_norm)
    );

    wire [23:0] mant_result = mant_norm;
    wire [7:0] exp_result = exp_norm;
    
    //assign round_bit = mant_result[0];

    rounding roundAB(
        .mant_norm(mant_result), .round_bit(round_bit), .mant_rounded(mant_rounded)
    );

    packing packAB(
        .sign_norm(sign_norm), .exp_norm(exp_result), .mant_rounded(mant_rounded), .sum(sum)
    );

endmodule
