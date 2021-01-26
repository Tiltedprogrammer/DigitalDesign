library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test is generic(NUMBER_OF_VERTICES : integer := 4);
 end test;

architecture behavioral of test is

signal clk,rst : std_logic;
signal param_t_valid : std_logic;
signal param_value : integer;
signal param_addr : integer range 0 to NUMBER_OF_VERTICES * NUMBER_OF_VERTICES - 1;
signal param_t_last : std_logic;
signal param_write_enable : std_logic;
signal out_value : integer;
signal out_t_valid, out_ready_to_read : std_logic;

procedure delay(n: integer; signal clk : std_logic) is
    begin
       for i in 1 to n loop
        wait until clk'event and clk = '1';
       end loop;
end delay;

begin
    
    DUT : entity work.fw
    generic map(NUMBER_OF_VERTICES => NUMBER_OF_VERTICES) 
    port map(clk => clk, rst => rst,
             param_t_valid => param_t_valid,
             param_addr => param_addr,
             param_value => param_value,
             param_write_enable => param_write_enable,
             param_t_last => param_t_last,
             out_t_valid => out_t_valid,
             out_ready_to_read => out_ready_to_read,
             out_value => out_value);
    
    
process is begin
    clk <= '0';
    wait for 4ns;
    clk <= '1';
    wait for 4ns;
end process;

process is 
    begin
    --fill the diagonal with 0's
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_t_last <= '0';
        param_addr <= 0;
        param_value <= 0;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_t_last <= '0';
        param_addr <= 5;
        param_value <= 0;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_t_last <= '0';
        param_addr <= 10;
        param_value <= 0;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 15;
        param_value <= 0;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 2;
        param_value <= -2;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 4;
        param_value <= 4;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 6;
        param_value <= 3;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 11;
        param_value <= 2;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 13;
        param_value <= -1;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 1;
        param_value <= 10000;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 3;
        param_value <= 10000;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 7;
        param_value <= 10000;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 8;
        param_value <= 10000;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 9;
        param_value <= 10000;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 12;
        param_value <= 10000;
        wait until out_ready_to_read = '1';
        param_write_enable <= '1';
        param_t_valid <= '1';
        param_addr <= 14;
        param_t_last <= '1';
        param_value <= 10000;
        wait until out_t_valid = '1';
--        param_write_enable <= '0';
--        param_addr <= 15;
--        wait until out_t_valid = '1';
--        assert out_value = 9 report integer'image(param_addr) &
--                             " element is not 9"  & ", but is " & integer'image(out_value);
--        param_addr <= 10;
--        wait until out_t_valid = '1';
--        assert out_value = 5 report integer'image(param_addr) &
--                             " element is not 5"  & ", but is " & integer'image(out_value);
--        param_addr <= 5;
--        wait until out_t_valid = '1';
--        assert out_value = 3 report integer'image(param_addr) &
--                             " element is not 3"  & ", but is " & integer'image(out_value);
--        param_addr <= 0;
--        wait until out_t_valid = '1';
--        assert out_value = 4 report integer'image(param_addr) &
--                             " element is not 4"  & ", but is " & integer'image(out_value);
--        wait;
end process;

end behavioral;