`timescale 1ns/1ps
`default_nettype none

module tb_alu;

    // 1. Inputs (Regs/Logic)
    logic [2:0]  opsel;
    logic        sub;
    logic        unsigned_op;
    logic        arith;
    logic [31:0] op1;
    logic [31:0] op2;

    // 2. Outputs (Wires)
    wire [31:0] result;
    wire        eq;
    wire        slt;

    // 3. Device Under Test (DUT) Instantiation
    alu dut (
        .i_opsel    (opsel),
        .i_sub      (sub),
        .i_unsigned (unsigned_op),
        .i_arith    (arith),
        .i_op1      (op1),
        .i_op2      (op2),
        .o_result   (result),
        .o_eq       (eq),
        .o_slt      (slt)
    );

    // 4. Helper Task for verifying results
    // This prints "PASS" or "FAIL" for each test case automatically.
    task check(input string name, input logic [31:0] expected_res);
        #1; // Wait for combinational logic to settle
        if (result === expected_res) begin
            $display("[PASS] %s: %h %s %h = %h", name, op1, name, op2, result);
        end else begin
            $error("[FAIL] %s: Expected %h, Got %h", name, expected_res, result);
        end
    endtask

    // 5. Helper Task for checking flags (EQ and SLT)
    task check_flags(input string name, input logic exp_eq, input logic exp_slt);
        #1;
        if (eq === exp_eq && slt === exp_slt) begin
            $display("[PASS] %s Flags: EQ=%b, SLT=%b", name, eq, slt);
        end else begin
            $error("[FAIL] %s Flags: Expected EQ=%b SLT=%b, Got EQ=%b SLT=%b", name, exp_eq, exp_slt, eq, slt);
        end
    endtask

    initial begin
        $display("Starting ALU Tests using Masking Logic...\n");
        $dumpfile("alu.vcd"); // For waveform viewing
        $dumpvars(0, tb_alu);

        // Initialize defaults
        opsel = 0; sub = 0; unsigned_op = 0; arith = 0; op1 = 0; op2 = 0;

        // ----------------------------------------------------------------
        // TEST 1: ADDITION (3'b000)
        // ----------------------------------------------------------------
        opsel = 3'b000; sub = 0;
        op1 = 32'd15; op2 = 32'd20;
        check("ADD", 32'd35); // 15 + 20 = 35

        // ----------------------------------------------------------------
        // TEST 2: SUBTRACTION (3'b000 + i_sub)
        // ----------------------------------------------------------------
        opsel = 3'b000; sub = 1;
        op1 = 32'd50; op2 = 32'd20;
        check("SUB", 32'd30); // 50 - 20 = 30

        // ----------------------------------------------------------------
        // TEST 3: AND (3'b111)
        // ----------------------------------------------------------------
        opsel = 3'b111; sub = 0;
        op1 = 32'hF0F0F0F0; op2 = 32'h0F0F0F0F;
        check("AND", 32'h00000000);

        // ----------------------------------------------------------------
        // TEST 4: OR (3'b110)
        // ----------------------------------------------------------------
        opsel = 3'b110;
        op1 = 32'hF0F0F0F0; op2 = 32'h0F0F0F0F;
        check("OR ", 32'hFFFFFFFF);

        // ----------------------------------------------------------------
        // TEST 5: XOR (3'b100)
        // ----------------------------------------------------------------
        opsel = 3'b100;
        op1 = 32'hAAAA5555; op2 = 32'hFFFF0000;
        check("XOR", 32'h55555555);

        // ----------------------------------------------------------------
        // TEST 6: SHIFT LEFT LOGICAL (3'b001)
        // ----------------------------------------------------------------
        opsel = 3'b001;
        op1 = 32'h00000001; op2 = 32'd4;
        check("SLL", 32'h00000010); // 1 << 4 = 16

        // ----------------------------------------------------------------
        // TEST 7: SHIFT RIGHT LOGICAL (3'b101)
        // ----------------------------------------------------------------
        opsel = 3'b101; arith = 0;
        // Shift -1 (all 1s) right by 4. Logical shift inserts 0s.
        op1 = 32'hFFFFFFFF; op2 = 32'd4;
        check("SRL", 32'h0FFFFFFF); 

        // ----------------------------------------------------------------
        // TEST 8: SHIFT RIGHT ARITHMETIC (3'b101 + i_arith)
        // ----------------------------------------------------------------
        opsel = 3'b101; arith = 1;
        // Shift -4 (111...100) right by 1. Arithmetic shift preserves sign (1s).
        op1 = 32'hFFFFFFFC; op2 = 32'd1;
        check("SRA", 32'hFFFFFFFE); // Should result in -2

        // ----------------------------------------------------------------
        // TEST 9: SET LESS THAN SIGNED (3'b010)
        // ----------------------------------------------------------------
        opsel = 3'b010; unsigned_op = 0;
        op1 = 32'd10; op2 = 32'd20; // 10 < 20 is TRUE
        check("SLT (10 < 20)", 32'd1);
        check_flags("SLT_TRUE", 0, 1); // EQ=0, SLT=1

        op1 = 32'd20; op2 = 32'd10; // 20 < 10 is FALSE
        check("SLT (20 < 10)", 32'd0);
        check_flags("SLT_FALSE", 0, 0); // EQ=0, SLT=0

        // Negative number test: -10 < 10 is TRUE
        // -10 = 0xFFFFFFF6
        op1 = 32'hFFFFFFF6; op2 = 32'd10; 
        check("SLT (-10 < 10)", 32'd1);

        // ----------------------------------------------------------------
        // TEST 10: SET LESS THAN UNSIGNED (3'b010 + i_unsigned)
        // ----------------------------------------------------------------
        opsel = 3'b010; unsigned_op = 1;
        // In unsigned, -1 (0xFFFFFFFF) is a huge number, so -1 < 10 is FALSE
        op1 = 32'hFFFFFFFF; op2 = 32'd10;
        check("SLTU (MaxUint < 10)", 32'd0);

        $display("\nAll checks complete.");
        $finish;
    end

endmodule
`default_nettype wire
