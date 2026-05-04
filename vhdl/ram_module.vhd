library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_block is
    generic(
        address_bits : integer := 2;
        ram_word_width : integer := 8

    );

    port(

        CLK : in std_logic;
        enable : in std_logic;
        w_enable : in std_logic;
        address_bus : in std_logic_vector(address_bits-1 downto 0); --the address we are indexing
        data_in: in std_logic_vector(ram_word_width-1 downto 0);
        data_out: out std_logic_vector(ram_word_width-1 downto 0)
    );
    end entity ram_block;

architecture behavioural of ram_block is

    type ram_type is array ((2**address_bits)-1 downto 0) --2 raised to the power of the adress bits
    of std_logic_vector(ram_word_width-1 downto 0);

    signal ram_memory : ram_type := (

        --example program

        0 => x"01", -- CLEAR R1                               (SINGLE)
        1 => x"1F", --load R7 with value in Mem 64 (imm = 1)  (DOUBLE)
        2 => x"40", --mem address (0x09 stored there)         
        3 => x"B1", --R1 <- R1 + R7 (0 + 9 = 9) (imm = 0)     (DOUBLE)
        4 => x"E0", --reg 7                                   
        5 => x"29", --store R1 (imm = 1)                      (DOUBLE)
        6 => x"10", -- store to destination (16)10             

                --POST EX: at mem (16)10 there should be a value of 9
        64 => x"09",



        others => x"00");


    begin

        process(CLK)
        begin
            if rising_edge(CLK) then
                if enable ='1' then
                    if w_enable ='1' then
                        ram_memory(to_integer(unsigned(address_bus)))<= data_in;
                    end if;
                    data_out <= ram_memory(to_integer(unsigned(address_bus)));
                end if;
            end if;

        end process;


end architecture;