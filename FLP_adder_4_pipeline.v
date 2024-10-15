module D_FF_unpack_addition(
    input sign_A,
    input sign_B,
    input [24:0] mant_A_align,
    input [24:0] mant_B_align,
    input [7:0] exp_common,
    input clk,
    output reg sign_A_out,
    output reg sign_B_out,
    output reg [24:0] mant_A_align_out,
    output reg [24:0] mant_B_align_out,
    output reg [7:0] exp_common_out
);

    always @( posedge clk) begin
        sign_A_out <= sign_A;
        sign_B_out <= sign_B;
        mant_A_align_out <= mant_A_align;
        mant_B_align_out <= mant_B_align;
        exp_common_out <= exp_common;
    end

endmodule

module D_FF_addition_norm(
    input [23:0] mant_conv,
    input sign_norm,
    input [7:0] exp_common,
    input clk,
    output reg [23:0] mant_conv_out,
    output reg sign_norm_out,
    output reg [7:0] exp_common_out
);

    always @( posedge clk ) begin
        mant_conv_out <= mant_conv;
        sign_norm_out <= sign_norm;
        exp_common_out <= exp_common;
    end

endmodule

module D_FF_norm_pack(
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

module stage1(
    input [31:0] A,
    input [31:0] B,
    output [24:0] mant_A_align,
    output [24:0] mant_B_align,
    output [7:0] exp_common,
    output round_bit

);
    wire sign_A, sign_B;
    wire [7:0] exp_A, exp_B, exp_common, exp_norm;
    wire [23:0] mant_A, mant_B;

    unpack unpackAB(
        .A(A), .B(B), 
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B)
    );

    alignment alignAB(
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B),
        .mant_A_align(mant_A_align), .mant_B_align(mant_B_align), .exp_common(exp_common)
    );


endmodule

module stage2(
    input sign_A,
    input sign_B,
    input [24:0] mant_A_align,
    input [24:0] mant_B_align,
    output [23:0] mant_conv,
    output sign_norm
);
    wire [24:0] mant_sum;
    addition addAB(
        .sign_A(sign_A), .sign_B(sign_B), .mant_A_align(mant_A_align), .mant_B_align(mant_B_align), 
        .mant_sum(mant_sum)
    );

    conversion conv(
        .mant_sum(mant_sum), 
        .mant_conv(mant_conv), .sign_norm(sign_norm)
    );

endmodule

module stage4(
    input [23:0] mant_norm,
    input sign_norm,
    input [7:0] exp_result,
    output [31:0] sum
);
    wire [23:0] mant_rounded;
    rounding roundAB(
        .mant_norm(mant_norm), 
        .mant_rounded(mant_rounded)
    );

    packing packAB(
        .sign_norm(sign_norm), .exp_norm(exp_result), .mant_rounded(mant_rounded), 
        .sum(sum)
    );

endmodule

module FLP_adder_4(
    input [31:0] A,
    input [31:0] B,
    input rst,
    input clk,
    output [31:0] sum
);

    wire sign_A, sign_B;
    wire [7:0] exp_A, exp_B, exp_common, exp_norm;
    wire [23:0] mant_A, mant_B;
    wire [24:0] mant_A_align, mant_B_align;
    wire [24:0] mant_sum;
    wire [23:0] mant_conv, mant_rounded;
    wire round_bit, sign_norm;

    wire sign_A_out, sign_B_out;
    wire [7:0] exp_common_out, exp_norm_out, exp_common_out_2;
    wire [24:0] mant_A_align_out, mant_B_align_out;
    wire [23:0] mant_conv_out, mant_norm_out;
    wire sign_norm_out, sign_norm_out_2;
    /*
    unpack unpackAB(
        .A(A), .B(B), 
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B)
    );

    alignment alignAB(
        .sign_A(sign_A), .sign_B(sign_B), .exp_A(exp_A), .exp_B(exp_B), .mant_A(mant_A), .mant_B(mant_B),
        .mant_A_align(mant_A_align), .mant_B_align(mant_B_align), .exp_common(exp_common)
    );
    */
    stage1 stage1(
        .A(A), .B(B),
        .mant_A_align(mant_A_align), .mant_B_align(mant_B_align), .exp_common(exp_common)
    );

    D_FF_unpack_addition pipe1( .sign_A(sign_A), .sign_B(sign_B), .mant_A_align(mant_A_align), .mant_B_align(mant_B_align),
        .exp_common(exp_common), .clk(clk), 
        .sign_A_out(sign_A_out), .sign_B_out(sign_B_out), .mant_A_align_out(mant_A_align_out), .mant_B_align_out(mant_B_align_out),
        .exp_common_out(exp_common_out)
    );
    /*
    addition addAB(
        .sign_A(sign_A_out), .sign_B(sign_B_out), .mant_A_align(mant_A_align_out), .mant_B_align(mant_B_align_out), 
        .mant_sum(mant_sum)
    );

    conversion conv(
        .mant_sum(mant_sum), 
        .mant_conv(mant_conv), .sign_norm(sign_norm)
    );*/
    stage2 stage2(
        .sign_A(sign_A_out), .sign_B(sign_B_out), .mant_A_align(mant_A_align_out), .mant_B_align(mant_B_align_out), 
        .mant_conv(mant_conv), .sign_norm(sign_norm)
    );

    wire [23:0] mant_norm;

    D_FF_addition_norm pipe2(
        .mant_conv(mant_conv), .sign_norm(sign_norm), .exp_common(exp_common_out), .clk(clk),
        .mant_conv_out(mant_conv_out), .sign_norm_out(sign_norm_out), .exp_common_out(exp_common_out_2)
    );

    normalization stage3(
        .mant_conv(mant_conv_out), .exp_common(exp_common_out_2), 
        .mant_norm(mant_norm), .exp_norm(exp_norm)
    );

    D_FF_norm_pack pipe3(
        .mant_norm(mant_norm), .exp_norm(exp_norm), .sign_norm(sign_norm_out), .clk(clk),
        .mant_norm_out(mant_norm_out), .exp_norm_out(exp_norm_out), .sign_norm_out(sign_norm_out_2)
    );

    wire [23:0] mant_result = mant_norm_out;
    wire [7:0] exp_result = exp_norm_out;
    
    //assign round_bit = mant_result[0];
    /*
    rounding roundAB(
        .mant_norm(mant_result), 
        .mant_rounded(mant_rounded)
    );

    packing packAB(
        .sign_norm(sign_norm_out_2), .exp_norm(exp_result), .mant_rounded(mant_rounded), 
        .sum(sum)
    );
    */
    stage4 stage4(
        .mant_norm(mant_result), .sign_norm(sign_norm_out_2), .exp_result(exp_result),
        .sum(sum)
    );
endmodule