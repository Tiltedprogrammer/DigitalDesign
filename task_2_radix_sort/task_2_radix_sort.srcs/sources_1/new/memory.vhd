----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2020 10:58:14 PM
-- Design Name: 
-- Module Name: memory - Behavioral
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
--use IEEE.std_logic_arith.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bram is
    generic(MEM_SIZE : integer := 64; NUM_SIZE : integer :=32);
    port ( a : in integer;
           clk : in std_logic;
           d_input : in signed(NUM_SIZE - 1 downto 0);
           we : in std_logic;
           d_output : out signed(NUM_SIZE - 1 downto 0)
    ); 
end bram;

architecture syn of bram is
    type mem is array (MEM_SIZE - 1 downto 0) of signed(NUM_SIZE - 1 downto 0);
    signal memory : mem; 
begin
    process(clk) begin
    
    if rising_edge(clk) then
        if we = '1' then
            memory(a) <= d_input;
        else d_output <= memory(a);
        end if;
    end if;
    
    end process;
--   result := to_signed(a) + to_signed(b);
   

end syn;

