library ieee;
use ieee.std_logic_1164.all;

package ram_pkg is



    type ram_type is array (0 to (2**8)-1) --FOR NOW JUST ASSUME address_bits = 8 and ram_word_width = 8
    of std_logic_vector(8-1 downto 0);

    end package;