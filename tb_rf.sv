`timescale 1ns/1ps
`default_nettype none

module tb_rf;

    // Clock and Reset
    logic clk;
    logic rst;

    // Stimulus signals (shared between both instances)
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rd_data;
    logic        rd_wen;

    // Outputs from No-Bypass instance
    wire [31:0] rs1_data_no_bp, rs2_data_no_bp;
    
    // Outputs from Bypass instance
    wire [31:0] rs1_data_bp, rs2_data_bp;

    // Instantiate Register File (Bypass Disabled - Project 3/4 mode)
    rf #(.BYPASS_EN(0)) dut_no_bypass (
        .i_clk(clk),
        .i_rst(rst),
        .i_rs1_raddr(rs1_addr), .o_rs1_rdata(rs1_data_no_bp),
        .i_rs2_raddr(rs2_addr), .o_rs2_rdata(rs2_data_no_bp),
        .i_rd_wen(rd_wen),      .i_rd_waddr(rd_addr),      .i_rd_wdata(rd_data)
    );

    // Instantiate Register File (Bypass Enabled - Project 5 mode)
    rf #(.BYPASS_EN(1)) dut_bypass (
        .i_clk(clk),
        .i_rst(rst),
        .i_rs1_raddr(rs1_addr), .o_rs1_rdata(rs1_data_bp),
        .i_rs2_raddr(rs2_addr), .o_rs2_rdata(rs2_data_bp),
        .i_rd_wen(rd_wen),      .i_rd_waddr(rd_addr),      .i_rd_wdata(rd_data)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0; rst = 1;
        rs1_addr = 0; rs2_addr = 0; rd_addr = 0;
        rd_data = 0; rd_wen = 0;

        $display("Starting Register File Tests...\n");

        // 1. Apply Reset
        #10 rst = 0;
        
        // 2. Standard Write & Read (x5 = 0xDEADBEEF)
        rd_wen = 1; rd_addr = 5; rd_data = 32'hDEADBEEF;
        #10; // Wait a clock cycle for write to complete
        rd_wen = 0; 
        rs1_addr = 5; 
        #1; // Wait for combinational read
        $display("[Test 1: Standard Read] x5 -> Expected: DEADBEEF, Got: %h", rs1_data_no_bp);

        // 3. Write to x0 Test (Attempt x0 = 0xFFFFFFFF)
        rd_wen = 1; rd_addr = 0; rd_data = 32'hFFFFFFFF;
        #10;
        rd_wen = 0;
        rs1_addr = 0;
        #1;
        $display("[Test 2: Write to x0] x0 -> Expected: 00000000, Got: %h", rs1_data_no_bp);

        // 4. Bypass Test: Read and Write in the same cycle (x10 = 0xCAFEBABE)
        rd_wen = 1; rd_addr = 10; rd_data = 32'hCAFEBABE;
        rs1_addr = 10; // Read from x10 while writing to it
        #1; // Wait combinational delay (BEFORE clock edge)
        
        $display("[Test 3: Bypass Check]");
        $display("    No-Bypass output -> Expected: 00000000 (Old value), Got: %h", rs1_data_no_bp);
        $display("    Bypass output    -> Expected: CAFEBABE (New value), Got: %h", rs1_data_bp);

        #10; // Finish the clock cycle
        $display("\nTests Completed.");
        $finish;
    end
endmodule
`default_nettype wire
