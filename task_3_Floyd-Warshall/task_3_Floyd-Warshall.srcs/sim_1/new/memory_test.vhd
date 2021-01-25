library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.conv_std_logic_vector;

entity test_mem is end;

use work.p.all;

architecture Behavioral of test_mem is

signal clk,we : std_logic;
signal addr : integer;
signal d_input : std_logic_vector(4 * 32 - 1 downto 0);
signal d_output : std_logic_vector(4 * 32 - 1 downto 0);


procedure delay(n: integer; signal clk : std_logic) is
    begin
       for i in 1 to n loop
        wait until clk'event and clk = '1';
       end loop;
end delay;

begin
    DUT : entity work.bram port map (addr => addr,clk => clk,d_input => d_input, we => we, d_output => d_output);
    
process is begin
    clk <= '0';
    wait for 5ns;
    clk <= '1';
    wait for 5ns;
end process;

process is begin
    addr <= 1;
    we <= '1';
    d_input <= std_logic_vector(to_signed(1, 32)) & std_logic_vector(to_signed(4, 32)) & std_logic_vector(to_signed(3, 32)) & std_logic_vector(to_signed(1, 32));
    delay(2,clk);
    addr <= 1;
    we <= '0';
    delay(2,clk);
    assert d_output = std_logic_vector(to_signed(1, 32)) & std_logic_vector(to_signed(4, 32)) & std_logic_vector(to_signed(3, 32)) & std_logic_vector(to_signed(1, 32));
    wait;
 end process;

end Behavioral;
