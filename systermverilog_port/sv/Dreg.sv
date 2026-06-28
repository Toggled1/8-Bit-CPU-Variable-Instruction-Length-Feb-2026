module Dreg(

    input logic [7:0] D,
    output logic [7:0] Q,
    input logic enable,
    input logic reset,
    input logic clk

);

always_ff @(posedge clk) begin

    if (reset)
        Q <= 8'b0;
    else if (enable)
        Q <= D;

end

endmodule
