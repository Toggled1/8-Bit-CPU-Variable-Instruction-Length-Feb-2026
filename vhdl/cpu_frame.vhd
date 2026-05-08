library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;

entity cpu_frame is


    generic(

        ADDR_W : integer := 8;
        Data_W : integer := 8
    );
    port (
        
        --General CPU ports

        CLK : in std_logic;
        reset : in std_logic;
        debug_RAM_contents_full: out ram_type
        
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
        data_out: out std_logic_vector(ram_word_width-1 downto 0);
        debug_RAM_contents: out ram_type
    );
    end component;


    --debug
    signal debug_RAM_contents : ram_type;




    --signal declarations are below

    signal ALU_op     : std_logic_vector(3 downto 0);
    signal ALU_result : std_logic_vector(7 downto 0);

    signal Z : std_logic;  -- Zero
    signal C : std_logic;  -- Carry
    signal N : std_logic;  -- Negative
    signal V : std_logic;   -- Overflow
    


    type cpu_state_t is (FETCH0, FETCH1, FETCH0_BUF, FETCH1_BUF, LOADOPS, EXECUTE);
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


        --signal double_len : std_logic; --just an internal signal but doesn't do anything logically
        

        signal op_A_FF : std_logic_vector(7 downto 0);
        signal op_B_FF : std_logic_vector(7 downto 0);
        signal op_A_FF_en : std_logic;
        signal op_B_FF_en : std_logic;

begin

    debug_RAM_contents_full <= debug_RAM_contents;
    
    ALU_cpu : entity work.ALU

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


    ram : entity work.ram_block
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
        data_out => RAM_data_recieve,
        debug_RAM_contents => debug_RAM_contents

    );


        DP : entity work.datapath

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

            DP_ir_we <= '1';


            DP_reg_read_sel <= RAM_data_recieve(2 downto 0); --take directly from RAM to avoid waiting for the ir!!!
            op_A_FF_en <= '1'; --this can also now be moved from decode0

            case RAM_data_recieve(7 downto 4) is --same as above, now using RAM_data_recieve rather than from IR

            when "0001" | "0010" | "0011" |  --LOAD, STORE, MOVE
                "0100" | "0101" | "0110" |  -- BZ, BN, BRANCH
                "0111" | "1000" | "1001" |  -- OR, XOR, AND
                "1011" | "1100" =>          -- ADD, SUB

                    DP_pc_we <= '1'; --just increment pc here
                    next_state <= FETCH1;

            when others =>

                next_state <= EXECUTE;

            end case;
                

        when FETCH1 =>
            CPU_address_bus <= CPU_pc_value;
            RAM_enable <= '1';

            next_state <= FETCH1_BUF;




        
        when FETCH1_BUF =>

            DP_ir1_we <= '1';
            op_B_FF_en <= '1'; --now we can do this here because the signal was changed to take directly from RAM (at bottom of this file)

            DP_reg_read_sel <= RAM_data_recieve(7 downto 5); --same here

            --CPU_ir_value was already latched with Byte0 so can now use that here
            if CPU_ir_value(7 downto 4) = "0001" or CPU_ir_value(7 downto 4) = "0010" then



                    -- LOAD and STORE instructions need extra state to wait for the sync RAM
                    next_state <= LOADOPS;
                else

                    next_state <= EXECUTE;
                end if;







        when LOADOPS =>

            CPU_address_bus <= CPU_ir1_value; --ir1 is now latched so cool beans!
            RAM_enable <= '1';

            RAM_data_in <= op_A_FF;
            DP_reg_write_sel <= CPU_ir_value(2 downto 0); --maintain

            if CPU_ir_value(7 downto 4) = "0010" then 
                
                --for STORE:
                RAM_data_in <= op_A_FF;
                RAM_w_enable <= '1';
                DP_pc_we <= '1'; --increment pc before goes back to fetch state
                next_state <= FETCH0;
            else
                next_state <= EXECUTE;
            end if;
    
            
        when EXECUTE =>
        
            DP_pc_we <= '1'; --just increment pc here
            DP_reg_write_sel <= CPU_ir_value(2 downto 0);
            
        --Below is the case statement for each operation. (some use ALU and some don't)
        case CPU_ir_value(7 downto 4) is




        -- 0000 CLEAR: R[A] <- 0 

        when "0000" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result
            sr_we  <= '1';


        -- 0001 LOAD: R[A] <- MEM[addr8]

        when "0001" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "10";   -- memory mode

        -- 0011 MOVE: R[A] <- R[B]

        when "0011" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";     -- ALU_result


        --FOR ALL THESE: 0111 OR, 1000 XOR, 1001 AND, 1010 NOT, 1011 ADD, 1100 SUB, 1101 INC, 1110 DEC
        when "0111" | "1000" | "1001" | "1010" | "1011" | "1100" | "1101" | "1110" =>
            DP_reg_we <= '1';
            DP_wb_sel <= "00";
            sr_we  <= '1';



        -- 0110 BRANCH
        
        when "0110" =>
            DP_pc_src_sel <= '1';
            DP_pc_target <= op_B_FF;


        -- 1111 NOP
        
        when "1111" =>

            --chill out


        -- 0100 BZ --flag order: sr_in <= Z & C & N & V & "0000";

        when "0100" =>

            if sr_out(7) = '1' then
                DP_pc_src_sel <= '1';
                DP_pc_target <= op_B_FF;
            else DP_pc_src_sel <= '0';

            end if;


        -- 0101 BN --flag order: sr_in <= Z & C & N & V & "0000";
        
        when "0101" =>
            if sr_out(5) = '1' then
                DP_pc_src_sel <= '1';
                DP_pc_target <= op_B_FF;
            else
                DP_pc_src_sel <= '0';
            end if;



        when others =>
            --nothing

        end case;
     
        next_state <= FETCH0;
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
                        op_B_FF <= RAM_data_recieve;

                    when others =>
                        op_B_FF <= (others => '0');

                    end case;
                end if;
            end if;
end process;

end architecture;

