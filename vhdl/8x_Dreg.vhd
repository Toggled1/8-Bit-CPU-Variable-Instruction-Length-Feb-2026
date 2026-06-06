library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dregx8 is

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
    end entity Dregx8;

architecture structural of Dregx8 is
    
    signal reg_en : std_logic_vector(7 downto 0);
    signal Data0 : std_logic_vector (7 downto 0);
    signal Data1 : std_logic_vector (7 downto 0);
    signal Data2 : std_logic_vector (7 downto 0);
    signal Data3 : std_logic_vector (7 downto 0);
    signal Data4 : std_logic_vector (7 downto 0);
    signal Data5 : std_logic_vector (7 downto 0);
    signal Data6 : std_logic_vector (7 downto 0);
    signal Data7 : std_logic_vector (7 downto 0);



begin

    --decoder thingy for which register to write to:

    reg_en(0) <= write_enable when write_select = "000" else '0';
    reg_en(1) <= write_enable when write_select = "001" else '0';
    reg_en(2) <= write_enable when write_select = "010" else '0';
    reg_en(3) <= write_enable when write_select = "011" else '0';
    reg_en(4) <= write_enable when write_select = "100" else '0';
    reg_en(5) <= write_enable when write_select = "101" else '0';
    reg_en(6) <= write_enable when write_select = "110" else '0';
    reg_en(7) <= write_enable when write_select = "111" else '0';





    --mapping registers!
    reg0: entity work.Dreg 
    
        port map(
            D => din, 
            Q => Data0, 
            enable => reg_en(0), 
            reset => reset, 
            CLK => CLK
        
            );

    reg1: entity work.Dreg 
        
        port map(
            D => din, 
            Q => Data1, 
            enable => reg_en(1), 
            reset => reset, 
            CLK => CLK
            );

    reg2: entity work.Dreg

        port map(
            D => din, 
            Q => Data2, 
            enable => reg_en(2), 
            reset => reset, 
            CLK => CLK
            );
            
    reg3: entity work.Dreg 

        port map(
            D => din, 
            Q => Data3, 
            enable => reg_en(3), 
            reset => reset, 
            CLK => CLK);

    reg4: entity work.Dreg 

        port map(
            D => din, 
            Q => Data4, 
            enable => 
            reg_en(4), 
            reset => 
            reset, 
            CLK => CLK
            );

    reg5: entity work.Dreg 

        port map(
            D => din, 
            Q => Data5, 
            enable => reg_en(5), 
            reset => reset, 
            CLK => CLK
            );

    reg6: entity work.Dreg 

        port map(D => din, 
            Q => Data6, 
            enable => reg_en(6), 
            reset => reset, 
            CLK => CLK
            );

    reg7: entity work.Dreg 

        port map(D => din, 
            Q => Data7, 
            enable => reg_en(7), 
            reset => reset, 
            CLK => CLK
            );

    --mapping output for reading the registers
    dout <= Data0 when read_select = "000" else
            Data1 when read_select = "001" else
            Data2 when read_select = "010" else
            Data3 when read_select = "011" else
            Data4 when read_select = "100" else
            Data5 when read_select = "101" else
            Data6 when read_select = "110" else
            Data7;

        
end architecture;