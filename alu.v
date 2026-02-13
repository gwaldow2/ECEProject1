`default_nettype none

// The arithmetic logic unit (ALU) is responsible for performing the core
// calculations of the processor. It takes two 32-bit operands and outputs
// a 32 bit result based on the selection operation - addition, comparison,
// shift, or logical operation. This ALU is a purely combinational block, so
// you should not attempt to add any registers or pipeline it.
module alu (
    // NOTE: Both 3'b010 and 3'b011 are used for set less than operations and
    // your implementation should output the same result for both codes. The
    // reason for this will become clear in project 3.
    //
    // Major operation selection.
    // 3'b000: addition/subtraction if `i_sub` asserted
    // 3'b001: shift left logical
    // 3'b010,
    // 3'b011: set less than/unsigned if `i_unsigned` asserted
    // 3'b100: exclusive or
    // 3'b101: shift right logical/arithmetic if `i_arith` asserted
    // 3'b110: or
    // 3'b111: and
    input  wire [ 2:0] i_opsel,
    // When asserted, addition operations should subtract instead.
    // This is only used for `i_opsel == 3'b000` (addition/subtraction).
    input  wire        i_sub,
    // When asserted, comparison operations should be treated as unsigned.
    // This is used for branch comparisons and set less than unsigned. For
    // b ranch operations, the ALU result is not used, only the comparison
    // results.
    input  wire        i_unsigned,
    // When asserted, right shifts should be treated as arithmetic instead of
    // logical. This is only used for `i_opsel == 3'b101` (shift right).
    input  wire        i_arith,
    // First 32-bit input operand.
    input  wire [31:0] i_op1,
    // Second 32-bit input operand.
    input  wire [31:0] i_op2,
    // 32-bit output result. Any carry out should be ignored.
    output wire [31:0] o_result,
    // Equality result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_eq,
    // Set less than result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_slt
);
    // TODO: Fill in your implementation here.
	// Major operation selection.
wire x, a, s, sll, slt, slx, sltu, exor, srx, srl, sra, orw, andw;
	
assign x = !i_opsel[2] && !i_opsel[1] && !i_opsel[0];    // 3'b000: addition/subtraction if `i_sub` asserted
assign a = x && !i_sub;
assign s = x && i_sub;

assign sll = !i_opsel[2] && !i_opsel[1] && i_opsel[0];    // 3'b001: shift left logical
			    								// 3'b010,
assign slx = (!i_opsel[2] && i_opsel[1] && !i_opsel[0] ) || (!i_opsel[2] && i_opsel[1] && i_opsel[0] );  // 3'b011: set less than/unsigned if `i_unsigned` asserted
assign slt = slx && !i_unsigned;
assign sltu = slx && i_unsigned;
assign exor = i_opsel[2] && !i_opsel[1] && !i_opsel[0];
assign srx = i_opsel[2] && !i_opsel[1] && i_opsel[0];    // 3'b101: shift right logical/arithmetic if `i_arith` asserted
assign srl = srx && !i_arith;
assign sra = srx && i_arith;
assign orw = i_opsel[2] && i_opsel[1] && !i_opsel[0];    // 3'b110: or
assign andw = i_opsel[2] && i_opsel[1] && i_opsel[0];   // 3'b111: and
	
assign o_eq = (i_op1 == i_op2);
assign o_slt = sltu ? (i_op1 < i_op2) : slt? ($signed(i_op1) < $signed(i_op2)) : 1'b0;

assign o_result = ( {32{a}} & (i_op1 + i_op2))
                | ( {32{s}} & (i_op1 - i_op2))
                | ( {32{sll}} & (i_op1 << i_op2[4:0]))
                | ( {32{slx}} & {31'b0, o_slt})
                | ( {32{exor}} & (i_op1 ^ i_op2))
                | ( {32{srl}} & (i_op1 >> i_op2[4:0]))
                | ( {32{sra}}& $signed($signed(i_op1) >>> i_op2[4:0]) )  // bruh                  
		| ( {32{orw}} & (i_op1 | i_op2))
                | ( {32{andw}} & (i_op1 & i_op2));
endmodule

`default_nettype wire

