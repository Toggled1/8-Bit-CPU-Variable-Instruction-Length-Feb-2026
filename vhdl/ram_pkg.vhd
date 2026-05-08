library ieee;
use ieee.std_logic_1164.all;

package ram_pkg is

    -- generic(
    --     address_bits : integer := 8
    --     ram_word_width : integer := 8
    -- );

    type ram_type is array (0 to (2**8)-1) --FOR NOW JUST ASSUME address_bits = 2 and ram_word_width = 8
    of std_logic_vector(8-1 downto 0);

    end package;