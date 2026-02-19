library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dreg is

    generic (
        cells : integer := 8
    );
    port(

        D : in std_logic_vector(cells-1 downto 0);
        Q : out std_logic_vector(cells-1 downto 0);
        enable : in std_logic;
        reset : in std_logic;
        CLK : in std_logic
        
    );
    end entity Dreg;
 --synchronous enable and reset
architecture behavioural of Dreg is

begin
    process(CLK)
    begin

            if rising_edge(CLK) then
                if reset = '1' then
                    Q<=(others => '0');
                elsif enable = '1' then
                    Q<=D;

                end if;
            end if;
    end process;


end architecture;