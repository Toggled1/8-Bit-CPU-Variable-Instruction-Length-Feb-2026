module datapath(

    input logic [7:0] mem_din,
    output logic [7:0] mem_dout,
    input logic clk, reset,

    input logic reg_we,
    input logic [2:0] reg_read_sel,
    input logic [2:0] reg_write_sel,
    
    input logic pc_we, pc_src_sel,

    input logic [7:0] pc_target,
    output logic [7:0] pc_out,

    input logic ir_we,
    output logic [7:0] ir_out,
    
    input logic ir1_we,
    output logic [7:0] ir1_out,

    input logic [7:0] alu_result,
    input logic wb_sel,

    input logic [7:0] sr_in,
    output logic [7:0] sr_out,
    input logic sr_we
    
);

logic [7:0] int_pc_out, int_pc_next, int_ir_out, int_ir_next, int_ir1_out, int_ir1_next, pc_plus_1, gp_reg_din, gp_reg_dout;

assign pc_plus_1 = int_pc_out +1;
assign int_pc_next = (pc_src_sel == 1'b0) ? pc_plus_1  : pc_target;
assign pc_out = int_pc_out;

assign ir_out = int_ir_out;
assign ir1_out = int_ir1_out;
assign int_ir_next = mem_din;
assign int_ir1_next = mem_din;

assign mem_dout = gp_reg_dout;

assign gp_reg_din = (wb_sel == 1'b0) ? alu_result :
                    (wb_sel == 1'b1) ? mem_din : '0;


Dreg_8x gp_regs(

    .din (gp_reg_din),
    .dout (gp_reg_dout),
    .write_enable (reg_we),
    .write_select (reg_write_sel),
    .read_select (reg_read_sel),
    .*

);

Dreg pc(

        .D (int_pc_next),
        .Q (int_pc_out),
        .enable (pc_we), 
        .*
    );

Dreg ir(

        .D (int_ir_next),
        .Q (int_ir_out),
        .enable (ir_we), 
        .*
    );

Dreg ir1(

        .D (int_ir1_next),
        .Q (int_ir1_out),
        .enable (ir1_we), 
        .*
    );

Dreg sr(

        .D (sr_in),                                                                                                                                                                                                                             
        .Q (sr_out),
        .enable (sr_we), 
        .*
    );
endmodule


