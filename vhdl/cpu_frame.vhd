library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_frame is


    generic(

        ADDR_W : integer := 8;
        Data_W : integer := 8
    );
    port (
        
        --General CPU ports

        CLK : in std_logic;
        reset : in std_logic
        
    );

end entity cpu_frame;

architecture behavioural of cpu_frame is



component ALU is
  port(
    op_A       : in  std_logic_vector(7 downto 0);
    op_B       : in  std_logic_vector(7 downto 0);
    ALU_op     : in  std_logic_vector(3 downto 0);

    ALU_result : out std_logic_vector(7 downto 0);

    Z : out std_logic;  -- Zero
    C : out std_logic;  -- Carry
    N : out std_logic;  -- Negative
    V : out std_logic   -- Overflow
  );

end component;


component datapath is

    generic(

        ADDR_W : integer := 8;
        Data_W : integer := 8
    );

    port(
        mem_din : in std_logic_vector(DATA_W-1 downto 0);
        mem_dout : out std_logic_vector(DATA_W-1 downto 0);
        CLK : in std_logic;
        reset : in std_logic;


        reg_we          : in std_logic;
        reg_read_sel   : in std_logic_vector(2 downto 0);
        reg_write_sel   : in std_logic_vector(2 downto 0);


        pc_we       : in std_logic;
        pc_src_sel : in std_logic;
        pc_target : in std_logic_vector(7 downto 0);
        pc_out : out std_logic_vector(7 downto 0);


        ir_we       : in std_logic;
        ir_out      : out std_logic_vector(7 downto 0);

        ir1_we       : in std_logic;
        ir1_out      : out std_logic_vector(7 downto 0);

        alu_result : in std_logic_vector(7 downto 0);
        imm8 : in std_logic_vector(7 downto 0); --not used
        wb_sel : in std_logic_vector(1 downto 0);

        sr_in : in std_logic_vector(7 downto 0);
        sr_out : out std_logic_vector(7 downto 0);
        sr_we : in std_logic
        
    );
    end component;


component ram_block is

    generic(
        address_bits : integer := ADDR_W;
        ram_word_width : integer := DATA_W

    );

    port(

        CLK : in std_logic;
        enable : in std_logic;
        w_enable : in std_logic;
        address_bus : in std_logic_vector(address_bits-1 downto 0); --the address we are indexing
        data_in: in std_logic_vector(ram_word_width-1 downto 0);
        data_out: out std_logic_vector(ram_word_width-1 downto 0)
    );
    end component;


    --signal declarations are below

    signal ALU_op     : std_logic_vector(3 downto 0);
    signal ALU_result : std_logic_vector(7 downto 0);

    signal Z : std_logic;  -- Zero
    signal C : std_logic;  -- Carry
    signal N : std_logic;  -- Negative
    signal V : std_logic;   -- Overflow
    


    type cpu_state_t is (FETCH0, FETCH1, FETCH0_BUF, DECODE0_BUF, DECODE1, DECODE1_BUF, FETCH1_BUF, LOADOPS, DECODE0, EXECUTE);
    signal state, next_state : cpu_state_t;
    signal RAM_enable : std_logic;
    signal RAM_w_enable : std_logic;
    signal CPU_address_bus : std_logic_vector(ADDR_W-1 downto 0); --the address we are indexing
    signal RAM_data_in: std_logic_vector(Data_W-1 downto 0);
    signal RAM_data_recieve: std_logic_vector(Data_W-1 downto 0);

    signal EX_imm8 : std_logic_vector(7 downto 0); --declared eventhough its not used


    --CPU means intended for CPU, DP means intended for DP, EX means external

        --TO/FROM: CPU
        signal DP_data_recieve : std_logic_vector(DATA_W-1 downto 0);
        
        signal DP_reg_we          : std_logic;
        signal DP_reg_read_sel   : std_logic_vector(2 downto 0);
        signal DP_reg_write_sel   : std_logic_vector(2 downto 0);


        signal DP_pc_we       : std_logic;
        signal DP_pc_src_sel : std_logic;
        signal DP_pc_target : std_logic_vector(7 downto 0);
        signal CPU_pc_value : std_logic_vector(7 downto 0);


        signal DP_ir_we       : std_logic;
        signal CPU_ir_value      : std_logic_vector(7 downto 0);
        signal DP_ir1_we       : std_logic;
        signal CPU_ir1_value      : std_logic_vector(7 downto 0);

        
        signal DP_wb_sel : std_logic_vector(1 downto 0);

        signal sr_in :std_logic_vector(7 downto 0);
        signal sr_out : std_logic_vector(7 downto 0);
        signal sr_we : std_logic;


        signal double_len : std_logic; --just an internal signal but doesn't do anything logically
        

        signal op_A_FF : std_logic_vector(7 downto 0);
        signal op_B_FF : std_logic_vector(7 downto 0);
        signal op_A_FF_en : std_logic;
        signal op_B_FF_en : std_logic;

begin


    ALU_cpu : ALU

     port map(
        op_A => op_A_FF,
        op_B => op_B_FF,
        ALU_op => CPU_ir_value(7 downto 4),
        ALU_result => ALU_result,
        Z => Z,
        C => C,
        N => N,
        V => V
    );


    ram : ram_block
    generic map (
        address_bits => ADDR_W,
        ram_word_width => DATA_W

    )

    port map(

        CLK => CLK,
        enable => RAM_enable,
        w_enable => RAM_w_enable,
        address_bus => CPU_address_bus,
        data_in => RAM_data_in,
        data_out => RAM_data_recieve

    );


        DP : datapath

         generic map(
            ADDR_W => ADDR_W,
            Data_W => Data_W
        )
         port map(
            mem_din => RAM_data_recieve,
            mem_dout => DP_data_recieve,
            CLK => CLK,
            reset => reset,
            reg_we => DP_reg_we,
            reg_read_sel => DP_reg_read_sel,
            reg_write_sel => DP_reg_write_sel,
            pc_we => DP_pc_we,
            pc_src_sel => DP_pc_src_sel,
            pc_target => DP_pc_target,
            pc_out => CPU_pc_value,
            ir_we => DP_ir_we,
            ir_out => CPU_ir_value,
            ir1_we => DP_ir1_we,
            ir1_out => CPU_ir1_value,
            alu_result => alu_result,
            imm8 => EX_imm8,
            wb_sel => DP_wb_sel,
            sr_in => sr_in,
            sr_out => sr_out,
            sr_we => sr_we
        );


        sr_in <= Z & C & N & V & "0000"; --status register flag assignments


    --async reset
    process(CLK, reset)

    begin
        if reset = '1' then
            state <= FETCH0;
        elsif rising_edge(CLK) then
            state <= next_state;
        end if;
    end process;

    

    process(all)
    begin

    next_state <= state;


    RAM_enable <= '0';
    RAM_w_enable <= '0';
    DP_ir_we <= '0';
    DP_pc_we <= '0';
    DP_reg_we <= '0';
    sr_we <= '0';
    DP_wb_sel <= (others => '0');
    DP_pc_src_sel <= '0';
    DP_pc_target <= (others => '0');
    op_A_FF_en <= '0';
    op_B_FF_en <= '0';
    CPU_address_bus <= (others => '0');
    DP_ir1_we <= '0';
    DP_reg_read_sel <= (others => '0');
    DP_reg_write_sel <= (others => '0');

--FSM for the Fetch, Decode, Execute cycle... Extra states "%_Buff and LOADOPS" to allow time for RAM synchronous read

      case state is

        when FETCH0 =>
            
            CPU_address_bus <= CPU_pc_value;
            RAM_enable <= '1';
            
            next_state <= FETCH0_BUF;

        when FETCH0_BUF =>
            RAM_enable <= '1'; --maintain
            DP_ir_we <= '1';
            DP_pc_we <= '1';

            next_state <= DECODE0;

        when DECODE0 =>
        
        DP_reg_read_sel <= CPU_ir_value(2 downto 0);
        DP_reg_write_sel <= CPU_ir_value(2 downto 0);
        

        next_state <= DECODE0_BUF;


        when DECODE0_BUF =>
            
            op_A_FF_en <= '1';
            DP_reg_read_sel <= CPU_ir_value(2 downto 0); --maintain

            case CPU_ir_value(7 downto 4) is

            when "0001" | "0010" | "0011" |  --For operations: LOAD, STORE, MOVE
                "0100" | "0101" | "0110" |  -- BZ, BN, BRANCH
                "0111" | "1000" | "1001" |  -- OR, XOR, AND
                "1011" | "1100" =>          -- ADD, SUB
                    double_len <= '1';
                    next_state <= FETCH1;

            when others =>
                double_len <= '0'; --Can skip loading of op_B_FF for single-byte instructions
                next_state <= LOADOPS;

            end case;
                

        when FETCH1 =>
            CPU_address_bus <= CPU_pc_value;
            RAM_enable <= '1';

            next_state <= FETCH1_BUF;

        
        when FETCH1_BUF =>

            RAM_enable <= '1'; --maintain
            DP_ir1_we <= '1';
            DP_pc_we <= '1';

            next_state <= DECODE1;



        when DECODE1 =>
            
            DP_reg_read_sel <= CPU_ir1_value(7 downto 5);
            CPU_address_bus <= CPU_ir1_value;
            RAM_enable <= '1';

            next_state <= DECODE1_BUF;





        when DECODE1_BUF =>

            DP_reg_read_sel <= CPU_ir1_value(7 downto 5); --maintain
            op_B_FF_en <= '1';
            next_state <= LOADOPS;
            




        when LOADOPS =>

            CPU_address_bus <= CPU_ir1_value;
            RAM_enable <= '1';

            RAM_data_in <= op_A_FF;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0); --maintain


            next_state <= EXECUTE;
    
            
        when EXECUTE =>
        
    
    --Below is the case statement for each operation. (some use ALU and some don't)
    case CPU_ir_value(7 downto 4) is




        -- 0000 CLEAR: R[A] <- 0 

        when "0000" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);


        -- 0001 LOAD: R[A] <- MEM[addr8]

        when "0001" =>

            DP_reg_write_sel <= CPU_ir_value(2 downto 0);
            DP_wb_sel        <= "10";   -- memory mode
            DP_reg_we        <= '1';
            next_state       <= FETCH0;


        -- 0011 MOVE: R[A] <- R[B]

        when "0011" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '0';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);


        -- 0111 OR

        when "0111" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);


        -- 1000 XOR

        when "1000" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);


        -- 1001 AND

        when "1001" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);

            
        -- 1010 NOT

        when "1010" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);

            
        -- 1011 ADD

        when "1011" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);

            
        -- 1100 SUB
    
        when "1100" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);

            
        -- 1101 INC

        when "1101" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);


        -- 1110 DEC

        when "1110" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";
            sr_we  <= '1';
            next_state <= FETCH0;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);


        -- 0110 BRANCH
        
        when "0110" =>
            DP_pc_src_sel <= '1';
            DP_pc_target <= op_B_FF;
            DP_pc_we <= '1';
            next_state <= FETCH0;


        -- 1111 NOP
        
        when "1111" =>

            --chill out
            next_state <= FETCH0;


        -- 0100 BZ --flag order: sr_in <= Z & C & N & V & "0000";

        when "0100" =>

            if sr_out(7) = '1' then
                DP_pc_src_sel <= '1';
                DP_pc_target <= op_B_FF;
                DP_pc_we <= '1';

            end if;
            next_state <= FETCH0;


        -- 0101 BN --flag order: sr_in <= Z & C & N & V & "0000";
        
        when "0101" =>
            if sr_out(5) = '1' then
                DP_pc_src_sel <= '1';
                DP_pc_target <= op_B_FF;
                DP_pc_we <= '1';
            end if;
            next_state <= FETCH0;


        -- 0010 STORE

        when "0010" =>
            CPU_address_bus <= CPU_ir1_value; --maintain
            RAM_data_in <= op_A_FF; --maintain

            RAM_enable <= '1';
            RAM_w_enable <= '1';

            next_state <= FETCH0;

        
        when others =>
            next_state <= FETCH0;

        end case;
     
        
    when others =>
    next_state <= FETCH0;

  end case;
end process;





--op_A_FF is the flip flop that uses op_A (using FF to avoid implicit latching)
process(CLK)

begin
    if rising_edge(CLK) then
                if reset = '1' then
                    op_A_FF <= (others => '0');

                elsif op_A_FF_en = '1' then
                    op_A_FF<= DP_data_recieve;

                end if;
            end if;
end process;


--op_B_FF is used for double length instructions.
--if imm = '1', then the entire byte1 gets put into op_B_FF
--if imm = '0', then (7 downto 5) is used as the register B select

process(CLK)

begin
    if rising_edge(CLK) then
                if reset = '1' then
                    op_B_FF <= (others => '0');

                elsif op_B_FF_en = '1' then
                    
                    case CPU_ir_value(3) is

                    when '0' =>
                        op_B_FF <= DP_data_recieve;

                    when '1' =>
                        op_B_FF <= CPU_ir1_value;

                    when others =>
                        op_B_FF <= (others => '0');

                    end case;
                end if;
            end if;
end process;

end architecture;

