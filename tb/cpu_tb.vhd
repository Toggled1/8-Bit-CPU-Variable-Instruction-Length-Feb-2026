library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg.all;
use std.textio.all;
use ieee.std_logic_textio.all;

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
        reset : in std_logic;
        debug_RAM_contents_full: out ram_type


        
    );

    end component;

    signal CLK : std_logic := '0';
    signal reset : std_logic := '1';
    signal debug_RAM_contents : ram_type;


begin



    dut : entity work.cpu_frame

    port map(
        CLK => CLK,

        reset => reset,

        debug_RAM_contents_full => debug_RAM_contents
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
    reset <= '1';   --NOTE: Verification was done with waveform comparison with programs hardcoded in preloaded RAM
                    --UPDATE: Toolchain preloads the RAM now for execution

    wait for 25 ns;   --guarantees at least two rising edges at 5ns and 15ns

    reset <= '0';     --release reset, CPU starts running
    wait for 140000 ns; --this should be long enough!

    assert false report "Simulation finished" severity failure;
  end process;

end architecture;