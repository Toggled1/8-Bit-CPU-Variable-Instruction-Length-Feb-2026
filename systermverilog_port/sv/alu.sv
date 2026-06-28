module alu(

    input logic [7:0] op_A,
    input logic [7:0] op_B,
    input logic [3:0] ALU_op,

    output logic [7:0] ALU_result,

    output logic Z,C,N,V

);

    //internal arithmetic values for computation
    logic [8:0] extended_sum;
    logic [7:0] result_u;


    //flag temporaries
    logic zero_flag, carry_flag, negative_flag, overflow_flag;

    always_comb begin

        {result_u, extended_sum, zero_flag, carry_flag, negative_flag, overflow_flag, Z, C, N, V, ALU_result} = '0;



        

        case (ALU_op)

            //MOVE (passthrough)

            4'b0011:
                result_u = op_B; //just copy value B

            //OR
            4'b0111:
                result_u = (op_A | op_B);

            //XOR
            4'b1000:
                result_u = (op_A ^ op_B);

            //AND
            4'b1001:
                result_u = (op_A & op_B);

            //NOT
            4'b1010:
                result_u = (~op_A);

            //ADD
            4'b1011: begin
                extended_sum = {1'b0, op_A} + {1'b0, op_B};
                result_u = extended_sum[7:0]; //the output of ALU gets this value!!!
                carry_flag = extended_sum[8];

                //flag calculations
                if ((op_A[7] == op_B[7]) && (result_u[7] != op_A[7]))
                    overflow_flag = 1'b1;
            end

            //SUB
            4'b1100: begin
                extended_sum = {1'b0, op_A} - {1'b0, op_B};
                result_u = extended_sum[7:0];

                //C flag 
                carry_flag = extended_sum[8];

                //V flag
                if ((op_A[7] != op_B[7]) && (result_u[7] != op_A[7]))
                    overflow_flag = 1'b1;
            end

            //INC
            4'b1101: begin
                extended_sum ={1'b0, op_A} + 1;
                result_u = extended_sum[7:0];

                //C flag
                carry_flag = extended_sum[8];

                //V flag

                if ((op_A[7] == 1'b0) && (result_u[7] == 1'b1))
                    overflow_flag = 1'b1;
                

            end

            //DEC
            4'b1110: begin
                extended_sum = {1'b0, op_A} - 1;
                result_u     = extended_sum[7:0];
                carry_flag   = extended_sum[8]; //C flag


                //V flag
                if ((op_A[7] == 1'b1) && (result_u[7] == 1'b0))
                overflow_flag = 1'b1;
                
            end

            //non-ALU opcodes
            default: ;
            endcase 

            //common flags
            if (result_u == '0)
                zero_flag = 1'b1;
            
            negative_flag = result_u[7];

            //drive outputs
            ALU_result = result_u;
            Z = zero_flag;
            C = carry_flag;
            N = negative_flag;
            V = overflow_flag;
    end



    
endmodule

