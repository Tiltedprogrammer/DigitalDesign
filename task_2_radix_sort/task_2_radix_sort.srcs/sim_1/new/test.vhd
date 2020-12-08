library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test is end;

architecture Behavioral of test is

signal clk,rst : std_logic;
signal in_data : signed(31 downto 0);
signal in_data_valid, in_data_last : std_logic;
signal ready_to_read : std_logic;

signal out_data : signed(31 downto 0);
signal out_data_valid, out_data_last : std_logic;

procedure delay(n: integer; signal clk : std_logic) is
    begin
       for i in 1 to n loop
        wait until clk'event and clk = '1';
       end loop;
end delay;

begin
    
    DUT : entity work.radix_sorter port map(CLK => clk, RST => rst, IN_DATA => in_data,IN_DATA_LAST => in_data_last, 
                                            IN_DATA_VALID => in_data_valid,READY_TO_READ => ready_to_read,OUT_DATA_VALID => out_data_valid, OUT_DATA_LAST => out_data_last, OUT_DATA => out_data);
    
    
process is begin
    clk <= '0';
    wait for 5ns;
    clk <= '1';
    wait for 5ns;
end process;
 
 
process is begin
    rst <= '1';
    in_data_valid <= '0';
    delay(2,clk);
    rst <= '0';
    delay(1,clk);
    in_data_valid <= '1';
    in_data <= to_signed(223,32);
    delay(1,clk);
    in_data <= to_signed(256,32);
    delay(1,clk);
    in_data <= to_signed(265,32);
    delay(1,clk);
    in_data <= to_signed(127,32);
    delay(1,clk);
    in_data <= to_signed(3,32);
    delay(1,clk);
    in_data <= to_signed(1,32);
    delay(1,clk);
    in_data <= to_signed(11,32);
    delay(1,clk);
    in_data <= to_signed(4,32);
    delay(1,clk);
    in_data <= to_signed(5,32);
    delay(1,clk);
    in_data <= to_signed(6,32);
    delay(1,clk);
    in_data_last <= '1';
    in_data <= to_signed(7,32);
    wait;
-- these lines could be uncommented with the 
-- above wait being commented out, 
-- bottom lines shows that the sorter can sort again after reset;

--    wait until out_data_last = '1';
--    delay(1,clk);
--    rst <= '1';
--    in_data_valid <= '0';
--    in_data_last <= '0';
--    delay(2,clk);
--    rst <= '0';
--    delay(1,clk);
--    in_data_valid <= '1';
--    in_data <= to_signed(7,32);
--    delay(1,clk);
--    in_data <= to_signed(4,32);
--    delay(1,clk);
--    in_data <= to_signed(5,32);
--    delay(1,clk);
--    in_data <= to_signed(2,32);
--    delay(1,clk);
--    in_data_last <= '1';
--    in_data <= to_signed(1,32);
--    wait;

end process;

--check output when it is ready
process is

begin
    wait until out_data_valid = '1'; 
        ready_to_read <= '1';
        delay(1,clk);
        delay(1, clk);
        assert out_data = to_signed(1,32) report "first element is not 1, but is " & integer'image(to_integer(out_data));
        delay(1, clk);
        assert out_data = to_signed(3,32) report "first element is not 3, but is " & integer'image(to_integer(out_data));
        delay(1, clk);
        assert out_data = to_signed(4,32) report "first element is not 5, but is " & integer'image(to_integer(out_data));
        delay(1, clk);
        assert out_data = to_signed(5,32) report "first element is not 5, but is " & integer'image(to_integer(out_data));
        delay(1, clk);
        assert out_data = to_signed(6,32) report "first element is not 1, but is " & integer'image(to_integer(out_data));
        delay(1,clk);
        assert out_data = to_signed(7,32) report "first element is not 7, but is " & integer'image(to_integer(out_data));
        delay(1, clk);
        assert out_data = to_signed(11,32) report "first element is not 11, but is " & integer'image(to_integer(out_data));
        delay(1,clk);
        assert out_data = to_signed(127,32) report "second element is not 127, but is " & integer'image(to_integer(out_data));
        delay(1,clk);
        assert out_data = to_signed(223,32) report "third element is not 223, but is " & integer'image(to_integer(out_data));
        delay(1,clk);
        assert out_data = to_signed(256,32) report "third element is not 256, but is " & integer'image(to_integer(out_data));
        delay(1,clk);
        assert out_data = to_signed(265,32) report "third element is not 265, but is " & integer'image(to_integer(out_data));
    wait;
end process;

end Behavioral;  