`timescale 1ns / 1ps

module dreg_tb;

    parameter int CLK_PERIOD = 10;
    logic clk = 1'b0;
    logic reset = 1'b0;
    logic [7:0] D = 8'h0;
    logic [7:0] Q;        // Output (no initial value needed)
    logic enable = 1'b0;

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Explicit port mapping
    Dreg u_Dreg(
        .clk(clk),
        .reset(reset),
        .D(D),
        .Q(Q),
        .enable(enable) 
    );

    initial begin
        $dumpfile("dump_dreg.vcd");
        $dumpvars(0, dreg_tb);
        
        $display("--- Starting dreg Simulation ---");
        
        // 1. Reset Phase
        reset = 1'b1;
        repeat(5) @(posedge clk);
        #1; // Offset from edge
        reset = 1'b0;
        $display("Reset released at time %0t", $time);
        
        // 2. Stimulate Values
        // Enable register, set D to 8'hAA
        @(posedge clk);
        #1; // Drive inputs after the clock edge
        enable = 1'b1;
        D = 8'hAA;
        
        // Change D to 8'h55
        @(posedge clk);
        #1; 
        D = 8'h55;
        
        // Disable register (Q should hold the previous value)
        @(posedge clk);
        #1; 
        enable = 1'b0;
        D = 8'hFF;
        
        @(posedge clk);
        #1;
        
        $display("Stimulus complete at time %0t", $time);
        $finish;
    end

endmodule
