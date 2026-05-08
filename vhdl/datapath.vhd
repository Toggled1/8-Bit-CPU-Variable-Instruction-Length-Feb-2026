library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity datapath is

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

    end entity datapath;

architecture behavioural of datapath is


--gp register file template

component Dregx8 is

    generic (
        cells : integer := 8
    );
    port(
        din          :  in std_logic_vector (7 downto 0); 
        dout         :  out std_logic_vector (7 downto 0);
        CLK          :  in std_logic;                      
        reset        :  in std_logic;                      
        write_enable :  in std_logic;                      -- enable writing to a register (when write_enable = 1)
        write_select :  in std_logic_vector (2 downto 0);  -- select register to write to
        read_select  :  in std_logic_vector (2 downto 0)   -- select register to read from
        
    );
    end component;
--special register template

component Dreg is

    generic (
        cells : integer := 16
    );
    port(

        D : in std_logic_vector(cells-1 downto 0);
        Q : out std_logic_vector(cells-1 downto 0);
        enable : in std_logic;
        reset : in std_logic;
        CLK : in std_logic
        
    );
    end component;






--internal pc and ir/ir1 signals

signal int_pc_out : std_logic_vector(DATA_W-1 downto 0);
signal int_pc_next : std_logic_vector(DATA_W-1 downto 0);
signal int_ir_out : std_logic_vector(DATA_W-1 downto 0);
signal int_ir_next : std_logic_vector(DATA_W-1 downto 0);
signal int_ir1_out : std_logic_vector(DATA_W-1 downto 0);
signal int_ir1_next : std_logic_vector(DATA_W-1 downto 0);
signal pc_plus_1    : std_logic_vector(DATA_W-1 downto 0);

--internal gp register i/o signals

signal gp_reg_din : std_logic_vector(DATA_W-1 downto 0);
signal gp_reg_dout : std_logic_vector(DATA_W-1 downto 0);


begin

    pc_plus_1 <= std_logic_vector(unsigned(int_pc_out) + 1); --incremements pc

    int_pc_next <= pc_plus_1 when pc_src_sel='0' else pc_target; --either counts up 1 or jumps to target (from branch, BZ, or BN ops)

    ir_out <= int_ir_out; --linking to port
    ir1_out <= int_ir1_out; --linking to port
    int_ir_next <= mem_din; --rest is done in cpu_frame
    int_ir1_next <= mem_din; --rest is done in cpu_frame

    mem_dout <= gp_reg_dout; --read value from the selected gp register

    --setting values to the register from load or store command eventually from ALU

    gp_reg_din <= alu_result when wb_sel = "00" else --technically this could just be a 1 bit select
                  imm8 when wb_sel = "01" else --not actaully used
                    mem_din when wb_sel = "10" else
                        (others => '0');
                  

    pc_out <= int_pc_out; --linking to port



--program counter
PC : entity work.Dreg

    generic map (

    cells => DATA_W
)

    port map (
        D => int_pc_next,
        Q => int_pc_out,
        enable => pc_we,
        reset => reset,
        CLK => CLK
);




--instruction reg for current instruction byte0

IR : entity work.Dreg

generic map (

    cells => DATA_W
)

port map (
    D => int_ir_next,
    Q => int_ir_out,
    enable => ir_we,
    reset => reset,
    CLK => CLK
);

--instruction reg for current instruction byte1 (used for double length instructions) 
IR1 : entity work.Dreg

generic map (

    cells => DATA_W
)

port map (
    D => int_ir1_next,
    Q => int_ir1_out,
    enable => ir1_we,
    reset => reset,
    CLK => CLK
);

--status register where flags are stored in sequence (Z & C & N & V & "0000")
SR : entity work.Dreg

generic map (

    cells => DATA_W
)

port map (
    D => sr_in,
    Q => sr_out,
    enable => sr_we,
    reset => reset,
    CLK => CLK
);




--8 general purpose registers... selected by reg_write_sel and reg_read_sel
gp_regs : entity work.Dregx8

    port map(
        din          => gp_reg_din,
        dout         => gp_reg_dout,
        CLK          => CLK,
        reset        => reset,
        write_enable => reg_we,     
        write_select => reg_write_sel,
        read_select  => reg_read_sel
    );
        



end architecture;