module D_FF_unpack_mul(
    input sign_A,
    input sign_B,
    input [7:0] exp_A,    //exponent
    input [7:0] exp_B,
    input [23:0] mant_A,  //mantissa
    input [23:0] mant_B,
    input clk,
    output reg sign_A_out,
    output reg sign_B_out,
    output reg [7:0] exp_A_out,    //exponent
    output reg [7:0] exp_B_out,
    output reg [23:0] mant_A_out,  //mantissa
    output reg [23:0] mant_B_out
);

    always @( posedge clk) begin
        sign_A_out <= sign_A;
        sign_B_out <= sign_B;
        mant_A_out <= mant_A;
        mant_B_out <= mant_B;
        exp_A_out <= exp_A;
        exp_B_out <= exp_B;
    end

endmodule

module D_FF_multi(
    input [47:0] mant_result,
    input [7:0] exp_result,
    input sign_result,
    input clk,
    output reg [47:0] mant_result_out,
    output reg [7:0] exp_result_out,
    output reg sign_result_out
);

    always @( posedge clk ) begin
        mant_result_out <= mant_result;
        sign_result_out <= sign_result;
        exp_result_out <= exp_result;
    end

endmodule

module mul_stage3(
    input [47:0] mant_conv,
    input [7:0] exp_result,
    input sign_result,
    output [31:0] result
);
    wire [22:0] mant_norm;
    wire round_bit, sign_norm, sticky_bit, gaurd_bit;
    wire [7:0] exp_norm;
    //wire round_bit, sign_norm, sticky_bit, gaurd_bit;
    wire [22:0] mant_rounded;
    mul_normalization normAB(
        .mant_conv(mant_conv), .exp_result(exp_result), 
        .mant_norm(mant_norm), .exp_norm(exp_norm),.gaurd_bit(gaurd_bit), .round_bit(round_bit),.sticky_bit(sticky_bit)
    );

    
    //assign round_bit = mant_result[0];

    mul_rounding roundAB(
        .mant_norm(mant_norm),.round_bit(round_bit),.sticky_bit(sticky_bit),.gaurd_bit(gaurd_bit), .mant_rounded(mant_rounded)
    );

    mul_packing packAB(
        .sign_result(sign_result), .exp_norm(exp_norm), .mant_rounded(mant_rounded), .result(result)
    );

endmodule


module FLP_multiplier_4(
    input [31:0] A,
    input [31:0] B,
    input rst,
    input clk,
    output [31:0] result
);

    wire sign_A, sign_B, sign_result, sign_result_out, sign_result_out2;
    wire [7:0] exp_A, exp_B, exp_result, exp_norm, exp_A_out, exp_B_out, exp_result_out, exp_result_out2;
    wire [47:0] mant_result, mant_conv, mant_result_out, mant_result_out2;
    wire [23:0] mant_A, mant_B;
    wire [23:0] mant_A_out, mant_B_out;
    wire [24:0] mant_sum;
    wire [22:0] mant_rounded;
    wire round_bit, sign_norm, sticky_bit, gaurd_bit;

    wire sign_A_out, sign_B_out;
    



    mul_unpack unpackAB(
        .A(A), .B(B), .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B)
    );

    D_FF_unpack_mul pipe1(
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B), .clk(clk),
        .sign_A_out(sign_A_out), .sign_B_out(sign_B_out), .exp_A_out(exp_A_out), .exp_B_out(exp_B_out), .mant_A_out(mant_A_out), .mant_B_out(mant_B_out)        
    );

    sign_multiplication mulAB(
        .sign_A(sign_A_out), .sign_B(sign_B_out), .exp_A(exp_A_out), .exp_B(exp_B_out), .mant_A(mant_A_out), .mant_B(mant_B_out),
        .mant_result(mant_result), .exp_result(exp_result), .sign_result(sign_result)
    );

    D_FF_multi pipe2(
        .mant_result(mant_result), .exp_result(exp_result), .sign_result(sign_result), .clk(clk),
        .mant_result_out(mant_result_out2), .exp_result_out(exp_result_out2), .sign_result_out(sign_result_out2)
    );

    D_FF_multi pipe3(
        .mant_result(mant_result_out2), .exp_result(exp_result_out2), .sign_result(sign_result_out2), .clk(clk),
        .mant_result_out(mant_result_out), .exp_result_out(exp_result_out), .sign_result_out(sign_result_out)
    );
    wire [22:0] mant_norm;
    /*
    mul_normalization normAB(
        .mant_conv(mant_result_out), .exp_result(exp_result_out), 
        .mant_norm(mant_norm), .exp_norm(exp_norm),.gaurd_bit(gaurd_bit), .round_bit(round_bit),.sticky_bit(sticky_bit)
    );

    wire [23:0] mant_result = mant_norm;
    wire [7:0] exp_result = exp_norm;
    
    //assign round_bit = mant_result[0];

    mul_rounding roundAB(
        .mant_norm(mant_norm),.round_bit(round_bit),.sticky_bit(sticky_bit),.gaurd_bit(gaurd_bit), .mant_rounded(mant_rounded)
    );

    mul_packing packAB(
        .sign_result(sign_result_out), .exp_norm(exp_norm), .mant_rounded(mant_rounded), .result(result)
    );*/
    mul_stage3 mul_stage3(
        .mant_conv(mant_result_out), .exp_result(exp_result_out), .sign_result(sign_result_out),.result(result)
    );

endmodule