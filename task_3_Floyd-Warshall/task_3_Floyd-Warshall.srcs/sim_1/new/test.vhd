library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use STD.textio.all;
use ieee.std_logic_textio.all;

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

type graph_type is array(0 to NUMBER_OF_VERTICES - 1, 0 to NUMBER_OF_VERTICES - 1) of integer;
--type filename_type is array(0 to 9) of string; 

file graph_file : text;

impure function read_graph(file_name: string; file f: text) return graph_type is 
    variable v_ILINE     : line;
    
    variable graph       : graph_type;
    
begin
    file_open(f, file_name,  read_mode);
   
 
    for i in 0 to NUMBER_OF_VERTICES - 1 loop
      readline(graph_file, v_ILINE);
      
        for j in 0 to NUMBER_OF_VERTICES - 1 loop
      
            read(v_ILINE, graph(i,j));
            
        end loop;
      end loop;

    file_close(f);
    return graph;
    
end function; 

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


process

  variable number_of_files : integer := 5;
  variable g : graph_type; --:= read_graph("input_graph.txt",graph_file);
                 begin
                 
                     
                     --for each file (they are NUMBER_OF_VERTICESxNUMBER_OF_VERTICES graphs)
                 for n in 1 to number_of_files loop
                    
                      rst <= '1';
                      delay(1,clk);
                      rst <= '0';    
--                     filepath := "../../../../test_files/prefix";
--                     available_prefixes are 4x4,16x16,32x32; 
--                     filename := "input_graph{i}";
-- vhdl has a very strange support of strings, hence : 
                     g := read_graph("../../../../test_files/4x4/" & "input_graph" & integer'image(n),graph_file);
                     
                     report "testing file " & "../../../../test_files/4x4/" & "input_graph" & integer'image(n);
                     
                     param_t_last <= '0';
                     for i in 0 to NUMBER_OF_VERTICES - 1 loop
                            for j in 0 to NUMBER_OF_VERTICES - 1 loop
                                wait until out_ready_to_read = '1';
                                param_write_enable <= '1';
                                
                                param_t_valid <= '1';
                                param_t_last <= '0';
                                if i = NUMBER_OF_VERTICES - 1 and j = NUMBER_OF_VERTICES - 1 then
                                    param_t_last <= '1';

                                end if;
                                param_addr <= i * NUMBER_OF_VERTICES + j;
                                param_value <= g(i,j);
                        end loop;
                    end loop;
                    wait until out_t_valid = '1';
                    --check result

                    g := read_graph("../../../../test_files/4x4/" & "input_graph" & integer'image(n) &"_dist", graph_file);
                    
                    for i in 0 to NUMBER_OF_VERTICES - 1 loop
                            for j in 0 to NUMBER_OF_VERTICES - 1 loop
                                param_write_enable <= '0';
                                param_addr <= i * NUMBER_OF_VERTICES + j;
                                wait until out_t_valid = '1';
                                assert out_value = g(i,j) report integer'image(param_addr) &
                                    " element is not "& integer'image(g(i,j))  & ", but is " & integer'image(out_value);
                            end loop;
                      end loop;
                      
                 end loop;
                 wait;
  end process;



-- just in case 
--process is 
--    begin
--    --fill the diagonal with 0's
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_t_last <= '0';
--        param_addr <= 0;
--        param_value <= 0;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_t_last <= '0';
--        param_addr <= 5;
--        param_value <= 0;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_t_last <= '0';
--        param_addr <= 10;
--        param_value <= 0;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 15;
--        param_value <= 0;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 2;
--        param_value <= -2;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 4;
--        param_value <= 4;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 6;
--        param_value <= 3;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 11;
--        param_value <= 2;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 13;
--        param_value <= -1;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 1;
--        param_value <= 10000;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 3;
--        param_value <= 10000;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 7;
--        param_value <= 10000;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 8;
--        param_value <= 10000;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 9;
--        param_value <= 10000;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 12;
--        param_value <= 10000;
--        wait until out_ready_to_read = '1';
--        param_write_enable <= '1';
--        param_t_valid <= '1';
--        param_addr <= 14;
--        param_t_last <= '1';
--        param_value <= 10000;
--        wait until out_t_valid = '1';
--        param_write_enable <= '0';
--        param_addr <= 15;
--        wait until out_t_valid = '1';
--        assert out_value = 0 report integer'image(param_addr) &
--                             " element is not 0"  & ", but is " & integer'image(out_value);
--        param_addr <= 10;
--        wait until out_t_valid = '1';
--        assert out_value = 0 report integer'image(param_addr) &
--                             " element is not 0"  & ", but is " & integer'image(out_value);
--        param_addr <= 13;
--        wait until out_t_valid = '1';
--        assert out_value = -1 report integer'image(param_addr) &
--                             " element is not -1"  & ", but is " & integer'image(out_value);
--        param_addr <= 0;
--        wait until out_t_valid = '1';
--        assert out_value = 0 report integer'image(param_addr) &
--                             " element is not 0"  & ", but is " & integer'image(out_value);
--        wait;
--end process;
-- end of just in case

end behavioral;