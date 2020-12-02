library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test is end;

architecture Behavioral of test is

signal clk,rst : std_logic;
signal input : signed(31 downto 0);
signal input_ready, input_end : std_logic;
signal ready_to_read : std_logic;

signal output : signed(31 downto 0);
signal output_ready, output_end : std_logic;

procedure delay(n: integer; signal clk : std_logic) is
    begin
       for i in 1 to n loop
        wait until clk'event and clk = '1';
       end loop;
end delay;

begin
    
    DUT : entity work.radix_sorter port map(CLK => clk, RST => rst, IN_DATA => input,IN_DATA_LAST => input_end, 
                                            IN_DATA_VALID => input_ready,READY_TO_READ => ready_to_read,OUT_DATA_VALID => output_ready, OUT_DATA_LAST => output_end, OUT_DATA => output);
    
    
process is begin
    clk <= '0';
    wait for 5ns;
    clk <= '1';
    wait for 5ns;
end process;
 
 
process is begin
    rst <= '1';
    input_ready <= '0';
    delay(2,clk);
    rst <= '0';
    delay(1,clk);
    input_ready <= '1';
    input <= to_signed(256,32);
    delay(1,clk);
    input <= to_signed(223,32);
    delay(1,clk);
    input <= to_signed(265,32);
    delay(1,clk);
    input <= to_signed(127,32);
    delay(1,clk);
    input_end <= '1';
    input <= to_signed(7,32);
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

--check output when it is ready
process is

begin
    wait until output_ready = '1'; 
        ready_to_read <= '1';
        delay(1,clk);
        delay(1,clk);
        assert output = to_signed(7,32) report "first element is not 7, but is " & integer'image(to_integer(output));
        delay(1,clk);
        assert output = to_signed(127,32) report "second element is not 127, but is " & integer'image(to_integer(output));
        delay(1,clk);
        assert output = to_signed(223,32) report "third element is not 223, but is " & integer'image(to_integer(output));
        delay(1,clk);
        assert output = to_signed(256,32) report "third element is not 256, but is " & integer'image(to_integer(output));
        delay(1,clk);
        assert output = to_signed(265,32) report "third element is not 265, but is " & integer'image(to_integer(output));
    wait;
end process;

end Behavioral;  