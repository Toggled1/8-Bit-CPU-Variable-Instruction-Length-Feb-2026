library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CPU_TB is
    
end entity CPU_TB;

architecture Behavioural of CPU_TB is

component cpu_frame is


    generic(

        ADDR_W : integer := 8;
        Data_W : integer := 8
    );
    port (
        

        



        --General CPU

        CLK : in std_logic;
        reset : in std_logic
        
    );

    end component;

    signal CLK : std_logic := '0';
    signal reset : std_logic := '1';


begin

    dut : cpu_frame

    port map(
        CLK => CLK,

        reset => reset


    );


    stim : process

    begin

        

        while true loop
        CLK <= '0';
        wait for 5 ns;
        CLK <= '1';
        wait for 5 ns;
    end loop;

    end process;


    process
  begin
    reset <= '1';
    wait for 25 ns;   -- guarantees at least two rising edges at 5ns and 15ns

    reset <= '0';     -- release reset, CPU starts running
    wait for 140000 ns;

    assert false report "Simulation finished" severity failure;
  end process;

end architecture;