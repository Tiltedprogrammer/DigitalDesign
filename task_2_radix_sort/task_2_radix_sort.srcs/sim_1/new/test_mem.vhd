library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.conv_std_logic_vector;

entity test_mem is end;

architecture Behavioral of test_mem is

signal clk,we : std_logic;
signal a : integer;
signal d_input : signed(31 downto 0);
signal d_output : signed(31 downto 0);


procedure delay(n: integer; signal clk : std_logic) is
    begin
       for i in 1 to n loop
        wait until clk'event and clk = '1';
       end loop;
end delay;

begin
    
    DUT : entity work.bram port map(a => a, clk => clk, d_input => d_input, we => we, d_output => d_output
                                      );
    
    
process is begin
    clk <= '0';
    wait for 5ns;
    clk <= '1';
    wait for 5ns;
end process;
 
 
process is begin
    a <= 1;
    we <= '1';
    d_input <= to_signed(4,32);
    delay(2,clk);
    a <= 1;
    we <= '0';
    delay(2,clk);
    assert d_output = to_signed(4,32);
    wait;
-- these lines could be uncommented with the 
-- above wait being commented out, 
-- bottom lines shows that the sorter can sort again after reset;

--    wait until output_end = '1';
--    delay(1,clk);
--    rst <= '1';
--    input_ready <= '0';
--    input_end <= '0';
--    delay(2,clk);
--    rst <= '0';
--    delay(1,clk);
--    input_ready <= '1';
--    input <= to_signed(7,32);
--    delay(1,clk);
--    input <= to_signed(4,32);
--    delay(1,clk);
--    input <= to_signed(5,32);
--    delay(1,clk);
--    input <= to_signed(2,32);
--    delay(1,clk);
--    input_end <= '1';
--    input <= to_signed(1,32);
--    wait;

end process;

end Behavioral;  