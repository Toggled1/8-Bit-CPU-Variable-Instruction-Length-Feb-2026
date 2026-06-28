`timescale 1ns / 1ps

module cpu_tb;

    // Use 'logic' for variables driven in procedural blocks
    parameter int CLK_PERIOD = 10ns;
    logic clk = 1'b0;
    logic reset = 1'b0;
    
    // Keep 'wire' for outputs coming from the module
    wire [7:0] ram_debug [256]; 

    // SystemVerilog clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Use .* for implicit port mapping (matches names automatically)
    control u_control (
        .*
    );

    initial begin

        $dumpfile("dump_cpu.vcd");
        $dumpvars(0, cpu_tb);
        $display("--- Starting CPU Simulation ---");
        
        reset = 1'b1;
        repeat(10) @(posedge clk);
        reset = 1'b0;
        
        $display("Reset released at time %0t", $time);
        
        // Simulation control
        #(5000ns);
        $display("Simulation limit reached.");
        $finish;
    end


endmodule
