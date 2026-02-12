`timescale 1ns/1ps
`default_nettype none

module tb_imm;

    // Testbench signals
    logic [31:0] i_inst;
    logic [ 5:0] i_format;
    wire  [31:0] o_immediate;

    // Instantiate the immediate generator
    imm dut (
        .i_inst(i_inst),
        .i_format(i_format),
        .o_immediate(o_immediate)
    );

    // Helper task to check results
    task check_imm(input string name, input logic [31:0] expected);
        #1; // Wait a moment for combinational logic to settle
        if (o_immediate === expected) begin
            $display("[PASS] %s -> Expected: %h, Got: %h", name, expected, o_immediate);
        end else begin
            $error("[FAIL] %s -> Expected: %h, Got: %h", name, expected, o_immediate);
        end
    endtask

    initial begin
        $display("Starting Immediate Generator Tests...\n");

        // 1. I-Type Test: addi x1, x0, -1 (0xfff00093)
        // Format one-hot [1] -> 6'b000010
        i_inst   = 32'hfff00093; 
        i_format = 6'b000010;
        check_imm("I-Type (addi -1)", 32'hffffffff);

        // 2. S-Type Test: sw x1, 4(x2) (0x00112223)
        // Format one-hot [2] -> 6'b000100
        i_inst   = 32'h00112223;
        i_format = 6'b000100;
        check_imm("S-Type (sw 4)", 32'h00000004);

        // 3. B-Type Test: beq x1, x2, -4 (0xfe208ee3)
        // Format one-hot [3] -> 6'b001000
        i_inst   = 32'hfe208ee3;
        i_format = 6'b001000;
        check_imm("B-Type (beq -4)", 32'hfffffffc);

        // 4. U-Type Test: lui x1, 0x12345 (0x123450b7)
        // Format one-hot [4] -> 6'b010000
        i_inst   = 32'h123450b7;
        i_format = 6'b010000;
        check_imm("U-Type (lui 0x12345)", 32'h12345000);

        // 5. J-Type Test: jal x1, -4 (0xffdff0ef)
        // Format one-hot [5] -> 6'b100000
        i_inst   = 32'hffdff0ef;
        i_format = 6'b100000;
        check_imm("J-Type (jal -4)", 32'hfffffffc);

        $display("\nTests Completed.");
        $finish;
    end

endmodule
`default_nettype wire
