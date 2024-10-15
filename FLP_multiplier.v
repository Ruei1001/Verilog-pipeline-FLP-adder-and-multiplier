
module mul_unpack(
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

module sign_multiplication(
    input sign_A,
    input sign_B,
    input [7:0] exp_A,    //exponent
    input [7:0] exp_B,
    input [23:0] mant_A,  //mantissa
    input [23:0] mant_B,
    output [47:0] mant_result,
    output [7:0] exp_result,
    output sign_result
);
    wire [23:0] sign_mant_A, sign_mant_B;
    //assign sign_mant_A = (sign_A) ? mant_A : mant_A;
    //assign sign_mant_B = (sign_B) ? mant_B : mant_B;
    //wire [24:0] mant_A_extend = {sign_mant_A[23], sign_mant_A};
    //wire [24:0] mant_B_extend = {sign_mant_B[23], sign_mant_B};
    assign mant_result = mant_A * mant_B;
    assign exp_result = exp_A + exp_B - 8'd127;
    assign sign_result = sign_A ^ sign_B;
 
endmodule
/*
module mul_conversion(
    input [47:0] mant_result,
    input sign_result,
    output [47:0] mant_conv
);
    //wire [23:0] temp;
    // 1.11 * 1.11 = 11.0001
    // 1.01 * 1.01 = 01.1001
    // thus see the MSB if MSB is 1 exponent need to +1 and mantissa need right shift
    assign mant_conv = (sign_result) ? -mant_result : mant_result;
    
endmodule
*/
module mul_normalization(
    input [47:0] mant_conv,
    input [7:0] exp_result,
    output [22:0] mant_norm,
    output [7:0] exp_norm,
    output gaurd_bit,
    output round_bit,
    output sticky_bit
);
    // if 1X.XXXXXXX exp+1 1X.XXXXXX >> 1 -> 1.XXXXXXXX mantissa is XXXXXXXX and XXXXXXXX is [46:24]
    // if 01.XXXXXXX exp no change mantissa is XXXXXXXX and XXXXXXXX is [45:23]
    assign mant_norm = mant_conv[47] ? mant_conv[46:24] : mant_conv[45:23];
    assign exp_norm  = mant_conv[47] ? exp_result + 1'b1 : exp_result;
    assign gaurd_bit  = mant_conv[47] ? mant_conv[23] : mant_conv[22];
    assign round_bit  = mant_conv[47] ? mant_conv[22] : mant_conv[21];
    assign sticky_bit  = mant_conv[47] ? mant_conv[21] : mant_conv[20];
endmodule

module mul_rounding(
    input [22:0] mant_norm,
    input round_bit,
    input sticky_bit,
    input gaurd_bit,
    output [22:0] mant_rounded
);
    //assign mant_rounded = (mant_norm[0]) ? round_bit + mant_norm : mant_norm;
    
    wire [22:0] temp;
    wire sticky_temp;
    assign sticky_temp = (~mant_norm[0] && sticky_bit ) ? 23'b1 : 23'b0;
    assign mant_rounded = (gaurd_bit) ? 23'b1 + mant_norm : mant_norm;
    
endmodule

module mul_packing(
    input sign_result,
    input [7:0] exp_norm,
    input [22:0] mant_rounded,
    output [31:0] result
);
    assign result = {sign_result, exp_norm, mant_rounded[22:0]};
endmodule

module FLP_mul(
    input [31:0] A,
    input [31:0] B,
    output [31:0] result


);
    wire sign_A, sign_B, sign_result;
    wire [7:0] exp_A, exp_B, exp_result, exp_norm;
    wire [47:0] mant_result, mant_conv;
    wire [23:0] mant_A, mant_B;
    wire [24:0] mant_A_align, mant_B_align;
    wire [24:0] mant_sum;
    wire [22:0] mant_rounded;
    wire round_bit, sign_norm, sticky_bit, gaurd_bit;

    mul_unpack unpackAB(
        .A(A), .B(B), .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B)
    );

    sign_multiplication mulAB(
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B),
        .mant_result(mant_result), .exp_result(exp_result), .sign_result(sign_result)
    );
    /*
    mul_conversion conv(
        .mant_result(mant_result), .sign_result(sign_result), .mant_conv(mant_conv)
    );
    */
    wire [22:0] mant_norm;

    mul_normalization normAB(
        .mant_conv(mant_result), .exp_result(exp_result), 
        .mant_norm(mant_norm), .exp_norm(exp_norm),.gaurd_bit(gaurd_bit), .round_bit(round_bit),.sticky_bit(sticky_bit)
    );

    //wire [23:0] mant_result = mant_norm;
    //wire [7:0] exp_result = exp_norm;
    
    //assign round_bit = mant_result[0];

    mul_rounding roundAB(
        .mant_norm(mant_norm),.round_bit(round_bit),.sticky_bit(sticky_bit),.gaurd_bit(gaurd_bit), .mant_rounded(mant_rounded)
    );

    mul_packing packAB(
        .sign_result(sign_result), .exp_norm(exp_norm), .mant_rounded(mant_rounded), .result(result)
    );

endmodule

/*
module fp_multiplier (
    input  [31:0] A,    // 32-bit floating-point input A
    input  [31:0] B,    // 32-bit floating-point input B
    output [31:0] result // 32-bit floating-point multiplication result
);

    // Sign, exponent, and mantissa extraction
    wire signA, signB, signR;
    wire [7:0] expA, expB, expR;
    wire [23:0] mantA, mantB;
    wire [47:0] mantR;

    // Sign bit (XOR of input signs)
    assign signA = A[31];
    assign signB = B[31];
    assign signR = signA ^ signB;

    // Exponent extraction (biased)
    assign expA = A[30:23];
    assign expB = B[30:23];

    // Mantissa extraction (adding implicit leading 1 for normalized numbers)
    assign mantA = {1'b1, A[22:0]};  // 1.mantA
    assign mantB = {1'b1, B[22:0]};  // 1.mantB

    // Multiply mantissas (24x24 = 48 bits result)
    assign mantR = mantA * mantB;

    // Add exponents (subtract the bias (127))
    assign expR = expA + expB - 8'd127;

    // Normalize the mantissa
    wire [22:0] mantR_norm;
    wire [7:0] expR_norm;
    wire overflow;
    
    // If the 47th bit is 1, shift right by 1 and increase the exponent
    assign mantR_norm = mantR[47] ? mantR[46:24] : mantR[45:23];
    assign expR_norm  = mantR[47] ? expR + 1'b1 : expR;

    // Check for overflow in exponent (if it exceeds 255, return Inf)
    assign overflow = (expR_norm >= 8'hFF);

    // If overflow occurs, set result to Inf, otherwise, normal result
    assign result = (overflow) ? {signR, 8'hFF, 23'b0} : {signR, expR_norm, mantR_norm};

endmodule

*/