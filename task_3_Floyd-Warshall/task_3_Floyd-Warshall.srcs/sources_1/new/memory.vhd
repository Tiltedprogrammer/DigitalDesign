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

package p is
    type tarr is array (natural range<>) of integer;
end p;

use work.p.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bram is
    generic(ROWS : integer := 64; COLUMNS : integer := 64 * 32);
    port ( addr : in integer range 0 to ROWS - 1;
           clk : in std_logic;
           d_input : in std_logic_vector(COLUMNS-1 downto 0);
           we : in std_logic;
           d_output : out std_logic_vector(COLUMNS-1 downto 0)
    ); 
end bram;

architecture syn of bram is
--    type mem is array (ROWS - 1 downto 0) of tarr(COLUMNS - 1 downto 0);
    type mem is array (ROWS - 1 downto 0) of std_logic_vector(COLUMNS-1 downto 0);
    signal memory : mem;
begin
    process(clk) begin
    
    if rising_edge(clk) then
        if we = '1' then
            memory(addr) <= d_input;
        else d_output <= memory(addr);
        end if;
    end if;
    
    end process;
--   result := to_signed(a) + to_signed(b);
   

end syn;
