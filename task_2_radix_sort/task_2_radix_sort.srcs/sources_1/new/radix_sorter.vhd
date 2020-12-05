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
  generic(MEM_SIZE : integer := 2048; NUM_SIZE : integer :=32);
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

type STATE_TYPE is (ready, finished, eof, sorting, store_to_buffer, wait_for_buffer);
type SORT_TYPE is (init,pack_bin,unpack_bin_l,unpack_bin_r,store_to_left,store_to_right,
                   store_back_to_memory_from_left,store_back_to_memory_from_right, compare, read_from_memory, read_left, read_right, wait_right,wait_left
    );

signal state: STATE_TYPE;
signal sort_state : SORT_TYPE;

signal counter : integer;


--type ram_type is array (MEM_SIZE - 1 downto 0) of signed(NUM_SIZE - 1 downto 0);
--type bin_type is array (1 downto 0) of ram_type;

--attribute ram_style : string;

--signal memory : ram_type;
--signal bin_left : ram_type;
--signal bin_right : ram_type;

--attribute ram_style of memory : signal is "block";
--attribute ram_style of bin_left : signal is "block";
--attribute ram_style of bin_right : signal is "block";

signal bin_head_l : integer;
signal bin_head_r : integer;
signal j : integer;

signal bin_iteration : integer;

signal val_to_store : signed(NUM_SIZE - 1 downto 0);
signal place_to_store : integer;

-- bram stuff
component bram
    generic(MEM_SIZE :integer := MEM_SIZE; NUM_SIZE: integer := NUM_SIZE);
    port(a : integer; clk : in std_logic; d_input : in signed(31 downto 0); we : in std_logic; d_output : out signed(31 downto 0));
end component;
    
signal we_memory : std_logic;
signal memory_out : signed(31 downto 0);
signal memory_in : signed(31 downto 0);
signal memory_addr : integer;

signal we_left : std_logic;
signal left_out : signed(31 downto 0);
signal left_in : signed(31 downto 0);
signal left_addr : integer;

signal we_right : std_logic;
signal right_out : signed(31 downto 0);
signal right_in : signed(31 downto 0);
signal right_addr : integer;

signal out_buffer : signed(31 downto 0);

        
begin

memory : bram 
    generic map(MEM_SIZE => MEM_SIZE, NUM_SIZE => NUM_SIZE)
    port map (a => memory_addr, clk => clk, d_input => memory_in, we => we_memory, d_output => memory_out);

bin_left : bram
    generic map(MEM_SIZE => MEM_SIZE, NUM_SIZE => NUM_SIZE)
    port map (a => left_addr, clk => clk, d_input => left_in, we => we_left, d_output => left_out);
    
bin_right : bram 
    generic map(MEM_SIZE => MEM_SIZE, NUM_SIZE => NUM_SIZE)
    port map (a => right_addr, clk => clk, d_input => right_in, we => we_right, d_output => right_out);



input : process(CLK,RST)     
    begin
        if RST = '1' then 
            OUT_DATA_VALID <= '0'; 
            OUT_DATA_LAST <= '0';
            counter <= 0; 
            state <= ready; 
            sort_state <= init; 
            bin_iteration <= 0; 
            j <= 0;
            memory_addr <= 0;
            left_addr <= 0;
            right_addr <= 0;
            
            bin_head_l <= 0;
            bin_head_r <= 0;
        end if;
        if rising_edge(CLK) then            
            case state is
            
            when ready =>
            
                if IN_DATA_VALID = '1' then
                     if IN_DATA_LAST = '1' then
                         counter <= counter + 1; memory_in <= IN_DATA; memory_addr <= counter; state <= sorting; --state <= eof; safe_to_sort <= '1'; 
                     else we_memory <= '1'; memory_addr <= counter; memory_in <= IN_DATA; counter <= counter + 1;  
                     end if;
                end if;
                
            when sorting =>
                we_memory <= '0';
                we_left <= '0';
                we_right <= '0';
                
                case sort_state is
                    
                    when init =>
                        j <= 0;
                        bin_head_r <= 0;
                        bin_head_l <= 0;
                        if bin_iteration < NUM_SIZE then memory_addr <= j; sort_state <= pack_bin;
                        else
                            we_memory <= '0';
                            memory_addr <= 0; 
                            state <= wait_for_buffer;
                        end if;
                        
               
                    when pack_bin =>
                        if j < counter then
                            memory_addr <= j; 
                            sort_state <= read_from_memory; 
                        else
                            sort_state <= unpack_bin_l; j <= 0; end if;
                            
                    when read_from_memory =>
                        val_to_store <= memory_out;
                        sort_state <= compare;
                        
                    when compare =>
                             
                        if val_to_store(bin_iteration) = '0' then 
                            we_left <= '1';
                            left_addr <= bin_head_l;
                            left_in <= val_to_store;
                            sort_state <= store_to_left;
                        else
                            we_right <= '1';
                            right_addr <= bin_head_r;
                            right_in <= val_to_store;
                            sort_state <= store_to_right; end if;
                            
                    when store_to_left => j <= j + 1; memory_addr <= j + 1; bin_head_l <= bin_head_l + 1; sort_state <= pack_bin;
                    
                    when store_to_right => j <= j + 1; memory_addr <= j + 1; bin_head_r <= bin_head_r + 1; sort_state <= pack_bin; 
                                            
                    when unpack_bin_l =>
                        if j < bin_head_l then 
--                            val_to_store <= bin_left(j);
                            left_addr <= j;
                            sort_state <= wait_left;
                        else j <= 0; sort_state <= unpack_bin_r; end if;
                    
                    when wait_left =>
                        j <= j + 1;
                        memory_addr <= j;
                        sort_state <= read_left;
                    
                    when read_left =>  
                        val_to_store <= left_out;
                        sort_state <= store_back_to_memory_from_left;
                        
                    when unpack_bin_r =>
                        if j < bin_head_r then
--                         val_to_store <= bin_right(j); 
                         right_addr <= j;
                         sort_state <= wait_right;
                        else  j <= 0; bin_iteration <= bin_iteration + 1; sort_state <= init; end if;
                    
                    when wait_right =>
                        j <= j + 1;
                        memory_addr <= j + bin_head_l;
                        sort_state <= read_right;
                    
                    when read_right =>
                        val_to_store <= right_out; --right_out is updated now
                        sort_state <= store_back_to_memory_from_right;
                        
                    when store_back_to_memory_from_left =>                                                
                        we_memory <= '1';
                        memory_in <= val_to_store;
                        sort_state <= unpack_bin_l;
                    
                    when store_back_to_memory_from_right =>
                        we_memory <= '1';
                        memory_in <= val_to_store;
                        sort_state <= unpack_bin_r;
                end case;
                
            --for i in range(32): -- if bin_iteration < 32 then
                -- for j in range(counter) -- just if j < counter 
                 -- store_to_bin(memory(j)); 1 cycle
                 -- unpack_bin(); need state
                 -- j = 0;
            when wait_for_buffer =>
                state <= store_to_buffer;
            
            when store_to_buffer =>
                        out_buffer <= memory_out; --first value is ready, at the begining of the next clock the next will be ready
                        memory_addr <= memory_addr + 1;
                        state <= finished;
                    
            when finished =>
                OUT_DATA_VALID <= '1';
          
              if READY_TO_READ = '1' then
                if memory_addr = counter then OUT_DATA_LAST <= '1'; state <= eof; OUT_DATA <= memory_out;
                else
                    if memory_addr = 1 then OUT_DATA <= out_buffer; memory_addr <= memory_addr + 1;
                    else OUT_DATA_LAST <= '0'; memory_addr <= memory_addr + 1; OUT_DATA <= memory_out;
                    end if;
                end if;
              end if;
            when eof => state <= eof;
        end case;
        end if;
                     
    
end process;

end Behavioral;
