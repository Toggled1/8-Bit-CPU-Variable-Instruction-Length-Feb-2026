module Dreg_8x(

    input logic [7:0] din,
    output logic [7:0] dout,
    input logic clk, reset, write_enable,
    input logic [2:0] write_select, read_select
);

logic [7:0] reg_en;
logic [7:0] reg_outs [8];

always_comb begin

    reg_en = '0;
    if (write_enable)
        reg_en[write_select] = 1'b1;

end

assign dout = reg_outs[read_select];

genvar i;
generate
    for (i = 0; i < 8; i++) begin : gen_regs
        Dreg inst_reg (
            .D      (din),
            .Q      (reg_outs[i]), // Connect to specific element in the array
            .enable (reg_en[i]),   // Connect only the specific bit
            .clk    (clk),
            .reset  (reset)
        );
    end
endgenerate


  
endmodule
