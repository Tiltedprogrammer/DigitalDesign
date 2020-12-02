----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2020 10:44:21 PM
-- Design Name: 
-- Module Name: radix_sorter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity radix_sorter is
  generic(MEM_SIZE : integer := 64; NUM_SIZE : integer :=32);
  port (CLK : in std_logic; --clock
        RST : in std_logic; --reset
        
        IN_DATA : in signed(NUM_SIZE - 1 downto 0); -- input integer
        IN_DATA_LAST : in std_logic;
        IN_DATA_VALID : in std_logic;
        READY_TO_READ : in std_logic;
        
        OUT_DATA_VALID : out std_logic;
        OUT_DATA_LAST : out std_logic;
        OUT_DATA : out signed(NUM_SIZE - 1 downto 0) );
end radix_sorter;

architecture Behavioral of radix_sorter is

type STATE_TYPE is (ready, finished,eof, sorting);
type SORT_TYPE is (init,pack_bin,unpack_bin_l,unpack_bin_r);
signal state: STATE_TYPE;
signal sort_state : SORT_TYPE;

signal counter : integer;


type ram_type is array (MEM_SIZE - 1 downto 0) of signed(NUM_SIZE - 1 downto 0);
type bin_type is array (1 downto 0) of ram_type;
signal memory : ram_type;

signal bins : bin_type;

signal bin_head_l : integer;
signal bin_head_r : integer;
signal j : integer;

signal bin_iteration : integer;
signal current : integer;

begin


input : process(CLK,RST) 
    
    begin
        if RST = '1' then 
            OUT_DATA_VALID <= '0'; 
            OUT_DATA_LAST <= '0';
            counter <= 0; 
            state <= ready; 
            sort_state <= init; 
            bin_iteration <= 0; 
            current <= 0;
            j <= 0;
            bin_head_l <= 0;
            bin_head_r <= 0;
        end if;
        if rising_edge(CLK) then            
            case state is
            
            when ready =>
            
                if IN_DATA_VALID = '1' then
                     if IN_DATA_LAST = '1' then
                        memory(counter) <= IN_DATA; counter <= counter + 1; state <= sorting; --state <= eof; safe_to_sort <= '1'; 
                     else memory(counter) <= IN_DATA; counter <= counter + 1;
                     end if;
                end if;
            when sorting =>
                case sort_state is
                    
                    when init =>
                        j <= 0;
                        bin_head_r <= 0;
                        bin_head_l <= 0;
                        if bin_iteration < NUM_SIZE then sort_state <= pack_bin;
                        else state <= finished;
                        end if;
                    when pack_bin =>
                        if j < counter then 
                            if memory(j)(bin_iteration) = '0' then bins(0)(bin_head_l) <= memory(j); bin_head_l <= bin_head_l + 1; j <= j + 1;
                            else bins(1)(bin_head_r) <= memory(j); bin_head_r <= bin_head_r + 1; j <= j + 1; end if;
                        else sort_state <= unpack_bin_l; j <= 0; end if;
                    when unpack_bin_l =>
                        if j < bin_head_l then memory(j) <= bins(0)(j); j <= j + 1;
                        else j <= 0; sort_state <= unpack_bin_r; end if;
                    when unpack_bin_r =>
                        if j < bin_head_r then memory(j + bin_head_l) <= bins(1)(j); j <= j + 1;
                        else  j <= 0; bin_iteration <= bin_iteration + 1; sort_state <= init; end if;
                end case;
                
            --for i in range(32): -- if bin_iteration < 32 then
                -- for j in range(counter) -- just if j < counter 
                 -- store_to_bin(memory(j)); 1 cycle
                 -- unpack_bin(); need state
                 -- j = 0;

            when finished =>
                OUT_DATA_VALID <= '1';
          
              if READY_TO_READ = '1' then
                if current = counter - 1 then OUT_DATA_LAST <= '1'; state <= eof;
                else OUT_DATA_LAST <= '0'; end if;
                OUT_DATA <= memory(current); current <= current + 1;
              end if;
            when eof => state <= eof;
        end case;
        end if;
                     
    
end process;

end Behavioral;
