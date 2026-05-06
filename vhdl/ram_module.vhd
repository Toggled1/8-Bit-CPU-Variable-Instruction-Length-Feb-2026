library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

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
    --changed so it now goes 0 and up becuase was flipped in the previous version
    type ram_type is array (0 to (2**address_bits)-1) --2 raised to the power of the adress bits
    of std_logic_vector(ram_word_width-1 downto 0);

    impure function ram_init(file_name : in string) return ram_type is

        file text_file       : text open read_mode is file_name;
        variable text_line   : line;--from textio!!!
        variable hex_val     : std_logic_vector(ram_word_width-1 downto 0);
        variable ram_content : ram_type := (others => x"00");
        variable i           : integer := 0;


        
    begin
        while not endfile(text_file) and i < 2**address_bits loop


            readline(text_file, text_line); --just gets the line
            hread(text_line, hex_val); --hexadecimal read

            ram_content(i) := hex_val;
            i := i + 1; --increment the counter

        end loop;

        return ram_content;



    end function;




    --this uses the function that i made above
    signal ram_memory : ram_type := ram_init("Assembler/output.txt");


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