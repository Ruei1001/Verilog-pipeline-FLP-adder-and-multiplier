module D_FF_unpack(
    input sign_A,         //sign bit
    input sign_B,
    input [7:0] exp_A,    //exponent
    input [7:0] exp_B,
    input [23:0] mant_A,  //mantissa
    input [23:0] mant_B,
    input clk,
    output reg sign_A_out,         //sign bit
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

module D_FF_align(
    input sign_A,         //sign bit
    input sign_B,
    input [7:0] exp_common,    //exponent
    input [24:0] mant_A_align,  //mantissa
    input [24:0] mant_B_align,
    input clk,
    output reg sign_A_out,         //sign bit
    output reg sign_B_out,
    output reg [7:0] exp_common_out,    //exponent
    output reg [24:0] mant_A_align_out,  //mantissa
    output reg [24:0] mant_B_align_out
);

    always @( posedge clk ) begin
        sign_A_out <= sign_A;
        sign_B_out <= sign_B;
        exp_common_out <= exp_common;
        mant_A_align_out <= mant_A_align;
        mant_B_align_out <= mant_B_align;
    end

endmodule

module D_FF_add(
    input sign_A,         //sign bit
    input sign_B,
    input [7:0] exp_common,    //exponent
    input [24:0] mant_sum,  //mantissa
    input clk,
    output reg sign_A_out,         //sign bit
    output reg sign_B_out,
    output reg [7:0] exp_common_out,    //exponent
    output reg [24:0] mant_sum_out
);

    always @( posedge clk ) begin
        sign_A_out <= sign_A;
        sign_B_out <= sign_B;
        exp_common_out <= exp_common;
        mant_sum_out <= mant_sum;
    end

endmodule

module D_FF_conv (
    input sign_norm,
    input [23:0] mant_conv,
    input [7:0] exp_common,
    input clk,
    output reg sign_norm_out,
    output reg [23:0] mant_conv_out,
    output reg [7:0] exp_common_out
);
    always @( posedge clk ) begin
        sign_norm_out <= sign_norm;
        exp_common_out <= exp_common;
        mant_conv_out <= mant_conv;
    end
    
endmodule

module D_FF_norm(
    input [23:0] mant_norm,
    input [7:0] exp_norm,
    input sign_norm,
    input clk,
    output reg [23:0] mant_norm_out,
    output reg [7:0] exp_norm_out,
    output reg sign_norm_out
);
    always @( posedge clk ) begin
        mant_norm_out <= mant_norm;
        sign_norm_out <= sign_norm;
        exp_norm_out <= exp_norm;
    end

endmodule

module D_FF_rounding(
    input [23:0] mant_rounded,
    input [7:0] exp_norm,
    input sign_norm,
    input clk,
    output reg [23:0] mant_rounded_out,
    output reg [7:0] exp_norm_out,
    output reg sign_norm_out
);
    always @( posedge clk ) begin
        mant_rounded_out <= mant_rounded;
        sign_norm_out <= sign_norm;
        exp_norm_out <= exp_norm;
    end

endmodule

module FLP_adder_7(
    input [31:0] A,
    input [31:0] B,
    input rst,
    input clk,
    output [31:0] sum
);

    wire sign_A, sign_B;
    wire [7:0] exp_A, exp_B, exp_common, exp_norm, exp_A_out, exp_B_out;
    wire [23:0] mant_A, mant_B;
    wire [24:0] mant_A_align, mant_B_align;
    wire [24:0] mant_sum;
    wire [23:0] mant_conv, mant_rounded, mant_rounded_out;
    wire round_bit, sign_norm;

    wire sign_A_out, sign_B_out;
    wire [23:0] mant_A_out, mant_B_out;
    wire [7:0] exp_common_out, exp_norm_out, exp_common_out_2, exp_common_out_3, exp_norm_out_2;
    wire [24:0] mant_A_align_out, mant_B_align_out;
    wire [23:0] mant_conv_out, mant_norm_out;
    wire sign_norm_out, sign_norm_out_2, sign_norm_out_3;
    wire [24:0] mant_sum_out;
      
    unpack unpackAB(
        .A(A), .B(B), 
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B)
    );

    D_FF_unpack pipe1(.sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B),.clk(clk),
        .sign_A_out(sign_A_out), .sign_B_out(sign_B_out), .exp_A_out(exp_A_out), .exp_B_out(exp_B_out), .mant_A_out(mant_A_out), .mant_B_out(mant_B_out)
    );

    alignment alignAB(
        .sign_A(sign_A_out), .sign_B(sign_B_out), .exp_A(exp_A_out), .exp_B(exp_B_out), .mant_A(mant_A_out), .mant_B(mant_B_out),
        .mant_A_align(mant_A_align), .mant_B_align(mant_B_align), .exp_common(exp_common)
    );

    wire sign_A_out_2, sign_B_out_2;
    D_FF_align pipe2(
        .sign_A(sign_A_out), .sign_B(sign_B_out), .exp_common(exp_common), .mant_A_align(mant_A_align), .mant_B_align(mant_B_align),.clk(clk),
        .sign_A_out(sign_A_out_2), .sign_B_out(sign_B_out_2), .exp_common_out(exp_common_out), .mant_A_align_out(mant_A_align_out), .mant_B_align_out(mant_B_align_out)
    );

    addition addAB(
        .sign_A(sign_A_out_2), .sign_B(sign_B_out_2), .mant_A_align(mant_A_align_out), .mant_B_align(mant_B_align_out), 
        .mant_sum(mant_sum)
    );

    wire sign_A_out_3, sign_B_out_3;
    D_FF_add pipe3(
        .sign_A(sign_A_out_2), .sign_B(sign_B_out_2),.exp_common(exp_common_out),.mant_sum(mant_sum), .clk(clk),
        .sign_A_out(sign_A_out_3), .sign_B_out(sign_B_out_3), .exp_common_out(exp_common_out_2), .mant_sum_out(mant_sum_out)
    );



    conversion conv(
        .mant_sum(mant_sum_out), 
        .mant_conv(mant_conv), .sign_norm(sign_norm)
    );

    wire [23:0] mant_norm;

    D_FF_conv pipe4(
        .sign_norm(sign_norm), .mant_conv(mant_conv), .exp_common(exp_common_out_2), .clk(clk),
        .sign_norm_out(sign_norm_out), .mant_conv_out(mant_conv_out), .exp_common_out(exp_common_out_3)
    );


    normalization normAB(
        .mant_conv(mant_conv_out), .exp_common(exp_common_out_3), 
        .mant_norm(mant_norm), .exp_norm(exp_norm)
    );

    D_FF_norm pipe5(
        .mant_norm(mant_norm), .exp_norm(exp_norm), .sign_norm(sign_norm_out), .clk(clk),
        .mant_norm_out( mant_norm_out), .exp_norm_out(exp_norm_out), .sign_norm_out(sign_norm_out_2)
    );


    wire [23:0] mant_result = mant_norm_out;
    wire [7:0] exp_result = exp_norm_out;
    
    //assign round_bit = mant_result[0];

    rounding roundAB(
        .mant_norm(mant_result), 
        .mant_rounded(mant_rounded)
    );

    D_FF_rounding pipe6(
        .mant_rounded(mant_rounded), .exp_norm(exp_norm_out), .sign_norm(sign_norm_out_2), .clk(clk),
        .mant_rounded_out(mant_rounded_out), .exp_norm_out(exp_norm_out_2), .sign_norm_out(sign_norm_out_3)
    );

    packing packAB(
        .sign_norm(sign_norm_out_3), .exp_norm(exp_norm_out_2), .mant_rounded(mant_rounded_out), 
        .sum(sum)
    );

endmodule