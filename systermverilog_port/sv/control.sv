module control(

    input logic clk,
    input logic reset,
    output logic [7:0] ram_debug [0:255]
);


    //logic declarations are below

    logic Z, C, N, V;
    
    typedef enum logic [2:0]{
        FETCH0,
        FETCH1,
        FETCH0_BUF,
        FETCH1_BUF,
        LOADOPS,
        EXECUTE
        

    } cpu_state_t;

    
    cpu_state_t state, next_state;
    logic RAM_enable, RAM_w_enable;
    logic [7:0] CPU_address_bus, RAM_data_in, RAM_data_recieve;

    logic [7:0] ALU_result;
    //CPU means intended for CPU, DP means intended for DP, EX means external

        //TO/FROM: CPU
    logic [7:0] DP_data_recieve;
    logic DP_reg_we;
    logic [2:0] DP_reg_read_sel;
    logic [2:0] DP_reg_write_sel;


    logic DP_pc_we;
    logic DP_pc_src_sel;
    logic [7:0] DP_pc_target;
    logic [7:0] CPU_pc_value;


    logic DP_ir_we;
    logic [7:0] CPU_ir_value;
    logic DP_ir1_we;
    logic [7:0] CPU_ir1_value;

    
    logic DP_wb_sel;

    logic [7:0] sr_in;
    /* verilator lint_off UNUSEDSIGNAL */
    logic [7:0] sr_out;
    /* verilator lint_on UNUSEDSIGNAL */
    logic sr_we;

    //operand FF declaration + controls;
    logic [7:0] op_A_FF;
    logic [7:0] op_B_FF;
    logic op_A_FF_en;
    logic op_B_FF_en;

    alu alu (
        .op_A (op_A_FF),
        .op_B (op_B_FF),
        .ALU_op (CPU_ir_value[7:4]),
        .*
    );
 
    
    ram ram (
    
        .enable (RAM_enable),
        .w_enable (RAM_w_enable),
        .address_bus (CPU_address_bus),
        .data_in (RAM_data_in),
        .data_out (RAM_data_recieve),
        .*
    );

    datapath datapath (
        .mem_din       (RAM_data_recieve),
        .mem_dout      (DP_data_recieve),
        .reg_we        (DP_reg_we),
        .reg_read_sel  (DP_reg_read_sel),
        .reg_write_sel (DP_reg_write_sel),
        .pc_we         (DP_pc_we),
        .pc_src_sel    (DP_pc_src_sel),
        .pc_target     (DP_pc_target),
        .pc_out        (CPU_pc_value),
        .ir_we         (DP_ir_we),
        .ir_out        (CPU_ir_value),
        .ir1_we        (DP_ir1_we),
        .ir1_out       (CPU_ir1_value),
        .alu_result    (ALU_result),
        .wb_sel        (DP_wb_sel),
        .*
    );


    assign sr_in = {Z, C, N, V, 4'b0000}; //status register flag assignments




    always_ff @(posedge clk) begin

        if (reset == 1'b1)
            state <= FETCH0;
        else
            state <= next_state;
    end

    always_comb begin

    next_state = state;
    //defaults
    {RAM_enable, RAM_w_enable, DP_ir_we, DP_pc_we, sr_we, DP_wb_sel, 
    DP_pc_src_sel, DP_pc_target, op_A_FF_en, op_B_FF_en, CPU_address_bus, 
    DP_ir1_we, DP_reg_read_sel, DP_reg_write_sel, RAM_data_in, DP_reg_we} = '0;
    
//FSM for the Fetch, Decode, Execute cycle... Extra states "%_Buff and LOADOPS" to allow time for RAM synchronous read
    case (state)

        FETCH0: begin

            CPU_address_bus = CPU_pc_value;
            RAM_enable = 1'b1;
            next_state = FETCH0_BUF;
        end

        FETCH0_BUF: begin

            DP_ir_we = 1'b1;
            DP_reg_read_sel = RAM_data_recieve[2:0]; //take directly from RAM to avoid waiting for the ir!!!
            op_A_FF_en = 1'b1; //this can also now be moved from decode0

            case (RAM_data_recieve[7:4]) // indexes of opcode
    
                // LOAD, STORE, MOVE, BZ, BN, BRANCH, OR, XOR, AND, ADD, SUB
                4'b0001, 4'b0010, 4'b0011,
                4'b0100, 4'b0101, 4'b0110,
                4'b0111, 4'b1000, 4'b1001,
                4'b1011, 4'b1100: begin
                    DP_pc_we = 1'b1;
                    next_state = FETCH1;
                end

                default: begin
                    next_state = EXECUTE;
                end

            endcase
        end

        FETCH1: begin

            CPU_address_bus = CPU_pc_value;
            RAM_enable = 1'b1;

            next_state = FETCH1_BUF;
        end


        FETCH1_BUF: begin

            DP_ir1_we = 1'b1;
            op_B_FF_en = 1'b1;
            DP_reg_read_sel = RAM_data_recieve[7:5];

            //CPU_ir_value was already latched with Byte0 so can now use that here
            if ((CPU_ir_value[7:4] == 4'b0001) || (CPU_ir_value[7:4] == 4'b0010)) begin
                // LOAD and STORE instructions need extra state to wait for the sync RAM
                next_state = LOADOPS;
            end
            else begin
                next_state = EXECUTE;
            end
        end

        LOADOPS: begin

            CPU_address_bus = CPU_ir1_value;
            RAM_enable = 1'b1;

            RAM_data_in = op_A_FF;
            DP_reg_write_sel = CPU_ir_value[2:0]; //maintain

            if (CPU_ir_value[7:4] == 4'b0010) begin
                
                //for STORE:
                RAM_data_in = op_A_FF;
                RAM_w_enable = 1'b1;
                DP_pc_we = 1'b1; //increment pc before goes back to fetch state
                next_state = FETCH0;
            end
            else begin
                next_state = EXECUTE;
            end
        end

        EXECUTE: begin

            DP_pc_we = 1'b1; //just increment pc here
            DP_reg_write_sel = CPU_ir_value[2:0];
          
            //Below is the case statement for each operation. (some use ALU and some don't)
            case (CPU_ir_value[7:4])

            // 0000 CLEAR: R[A] <- 0 

            4'b0000: begin
                DP_reg_we = 1'b1;
                DP_wb_sel = 1'b0;     // ALU_result
                sr_we = 1'b1;
            end

            // 0001 LOAD: R[A] <- MEM[addr8]

            4'b0001: begin
                DP_reg_we = 1'b1;
                DP_wb_sel = 1'b1;   // memory mode
            end
            // 0011 MOVE: R[A] <- R[B]

            4'b0011: begin
                DP_reg_we = 1'b1;
                DP_wb_sel = 1'b0;     // ALU_result
            end

            //FOR ALL THESE: 0111 OR, 1000 XOR, 1001 AND, 1010 NOT, 1011 ADD, 1100 SUB, 1101 INC, 1110 DEC
            4'b0111, 4'b1000, 4'b1001, 4'b1010, 4'b1011, 4'b1100, 4'b1101, 4'b1110: begin
                DP_reg_we = 1'b1;
                DP_wb_sel = 1'b0;
                sr_we  = 1'b1;
            end


            // 0110 BRANCH
            
            4'b0110: begin
                DP_pc_src_sel = 1'b1;
                DP_pc_target = op_B_FF;
            end

            // 1111 NOP
            
            4'b1111: begin
                //d0 nothing
            end

            // 0100 BZ //flag order: sr_in <= Z & C & N & V & "0000";

            4'b0100: begin

                if (sr_out[7] == 1'b1) begin
                    DP_pc_src_sel = 1'b1;
                    DP_pc_target = op_B_FF;
                end
                else DP_pc_src_sel = 1'b0;

                
            end


            // 0101 BN //flag order: sr_in <= Z & C & N & V & "0000";
            
            4'b0101: begin
                if (sr_out[5] == 1'b1) begin
                    DP_pc_src_sel = 1'b1;
                    DP_pc_target = op_B_FF;
                end
                else
                    DP_pc_src_sel = 1'b0;
                
            end

            default:;
            
            endcase
        
            next_state = FETCH0;
        end

        default:
            next_state = FETCH0;
    endcase

end

    
            

//op_A_FF is the flip flop that holdes op_A (using FF to avoid implicit latching)
always_ff @(posedge clk) begin

    if (reset == 1'b1)
        op_A_FF <= '0;
    else if (op_A_FF_en == 1'b1)
        op_A_FF <= DP_data_recieve;
end


//op_B_FF is used for double length instructions.
//if immediate, then the entire byte1 gets put into op_B_FF
//otherwise, (7:5) is used as the register B select

always_ff @(posedge clk) begin

    if (reset == 1'b1)
        op_B_FF <= '0;
    else if (op_B_FF_en == 1'b1) begin
        
        case (CPU_ir_value[3])

        1'b0:
            op_B_FF <= DP_data_recieve;
        1'b1:
            op_B_FF <= RAM_data_recieve;
        default:
            op_B_FF <= '0;
        endcase
    end
end

endmodule
