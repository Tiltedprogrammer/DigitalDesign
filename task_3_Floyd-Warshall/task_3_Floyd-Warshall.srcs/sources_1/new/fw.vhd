library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fw is
    generic(NUMBER_OF_VERTICES : integer := 32; NUM_SIZE : integer :=32);
    port (clk : in std_logic; --clock
        rst : in std_logic; --reset
        
        param_t_valid : std_logic;
        param_addr : in integer range 0 to NUMBER_OF_VERTICES * NUMBER_OF_VERTICES- 1;
        param_value : in integer;
        param_write_enable : in std_logic;
        param_t_last : in std_logic;
        out_ready_to_read : out std_logic;
        out_t_valid : out std_logic;
        out_value : out integer
        );
    end fw;
    
architecture behavioral of fw is

signal bram_addr : integer range 0 to NUMBER_OF_VERTICES - 1;
signal bram_in_value : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
signal bram_out_value : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
signal bram_we : std_logic;
--signal read_addr : integer;

--for debuf purposes
function to_string ( a: std_logic_vector) return string is
variable b : string (1 to a'length) := (others => NUL);
variable stri : integer := 1; 
begin
    for i in a'range loop
        b(stri) := std_logic'image(a((i)))(2);
    stri := stri+1;
    end loop;
return b;
end function;
--end of debuf purposes

function minimum (a : in std_logic_vector; b : in std_logic_vector) return std_logic_vector is
    begin
     if a = (0 to a'length - 1 => '1') then
        return b;
     else 
        if b = (0 to b'length - 1 => '1') then
            return a;
        else 
            if to_integer(signed(a)) > to_integer(signed(b)) then
                return b;
            else return a;
            end if;
        end if;
     end if;
end minimum;

signal param_value_buffer1 : integer;

signal param_addr_buffer1 : integer range 0 to NUMBER_OF_VERTICES - 1;


component bram
    generic(NUMBER_OF_VERTICES : integer := NUMBER_OF_VERTICES);
    port(addr : integer range 0 to NUMBER_OF_VERTICES - 1; clk : in std_logic; 
         d_input : in std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 ) - 1); 
         we : in std_logic; 
         d_output : out std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 ) - 1));
end component;


type STATE_TYPE is (non_reseted,reseting,ready_to_read,processing,finished);
type READ_TYPE is (init,read,finished,wait_before_read,write_to_row,write_to_memory);
type FW_TYPE is (init, read_i,read_k,find_min,write_i,read_ik);

signal state : STATE_TYPE := non_reseted;
signal read_state : READ_TYPE;
signal fw_state : FW_TYPE;

signal column : integer range 0 to NUMBER_OF_VERTICES - 1;

signal k_counter : integer range 0 to NUMBER_OF_VERTICES;
signal i_counter : integer range 0 to NUMBER_OF_VERTICES;

signal ith_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
signal kth_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
signal ik_value : std_logic_vector(0 to NUM_SIZE - 1);
signal ik_plus_kj : std_logic_vector(0 to NUM_SIZE - 1);
signal kj_value : std_logic_vector(0 to NUM_SIZE - 1);

signal current_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 ) - 1);
begin

graph: bram
    generic map(NUMBER_OF_VERTICES => NUMBER_OF_VERTICES)
    port map(addr => bram_addr,clk => clk,d_input => bram_in_value, we => bram_we, d_output => bram_out_value);

fw: process (clk,rst)

--variable current_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
--variable ith_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
--variable kth_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
--variable ik_value : std_logic_vector(0 to NUM_SIZE - 1);
--variable ik_plus_kj : std_logic_vector(0 to NUM_SIZE - 1);
--variable kj_value : std_logic_vector(0 to NUM_SIZE - 1);
variable tmp: std_logic_vector(0 to NUM_SIZE - 1);

begin

    if rising_edge(clk) then
        
        if rst = '1' then
         out_ready_to_read <= '0';
         i_counter <= 0;
         k_counter <= 0;
         state <= non_reseted;
        end if;
        
        case state is
            when non_reseted => 
                read_state <= init;
                state <= reseting;
                fw_state <= init;
                bram_addr <= 0;
                bram_in_value <= (others => '0'); --how to declare infinity?
                bram_we <= '1';
            when reseting =>
                if bram_addr < NUMBER_OF_VERTICES - 1 then
                    bram_addr <= bram_addr + 1;
--                    bram_in_value <= (others => '1'); --infinity
                else 
                    state <= ready_to_read;
                    out_t_valid <= '0';
                    out_ready_to_read <= '1';
                    bram_we <= '0';
--                    bram_addr <= 0; 
                end if;
            when ready_to_read =>
                if param_t_valid = '1' then
                    if param_t_last = '0' then
                        case read_state is 
                            when init =>
                                bram_we <= '0';
                                param_value_buffer1 <= param_value; --first read
                                bram_addr <= param_addr / NUMBER_OF_VERTICES; --row_id
                                param_addr_buffer1 <= param_addr;
                                
                                read_state <= wait_before_read;
                                out_ready_to_read <= '0';
                            when wait_before_read =>
                                
                                column <= param_addr_buffer1 mod NUMBER_OF_VERTICES;
                                
                                read_state <= read;  
                            when read => 
                                
                                current_row <= bram_out_value;
--                                report "current_row is " & to_string(current_row);
                                tmp := std_logic_vector(to_signed(param_value_buffer1, NUM_SIZE));
                                                     
                                read_state <= write_to_row;
                            when write_to_row =>
                                
                                current_row(column * NUM_SIZE to (column + 1) * NUM_SIZE - 1) <= tmp; --std_logic_vector(to_signed(param_value_buffer1, NUM_SIZE));
                                
                          
                                read_state <= write_to_memory;
                            when write_to_memory =>  
                                
                                bram_we <= '1';
                                bram_in_value <= current_row;
                                out_ready_to_read <= '1';
                                read_state <= init;
                            when finished =>
                                --nothing here actually
                        end case;
                    else --last element
                        case read_state is 
                            when init =>
                                bram_we <= '0';
                                param_value_buffer1 <= param_value; 
                                bram_addr <= param_addr / NUMBER_OF_VERTICES; --row_id
                                param_addr_buffer1 <= param_addr;
                                
                                read_state <= wait_before_read;
                                out_ready_to_read <= '0';
                            when wait_before_read => 
                                column <= param_addr_buffer1 mod NUMBER_OF_VERTICES;
                                
                                read_state <= read;
                            when read => 
                                current_row <= bram_out_value;
                                tmp := std_logic_vector(to_signed(param_value_buffer1, NUM_SIZE));
--                                report "current_row is " & to_string(current_row);
                                read_state <= write_to_row;
                                
                            when write_to_row =>
                                current_row(column * NUM_SIZE to (column + 1) * NUM_SIZE - 1) <=  tmp;--std_logic_vector(to_signed(param_value_buffer1, NUM_SIZE));
                                read_state <= write_to_memory;
                            when write_to_memory =>
                                bram_in_value <= current_row;
                                bram_we <= '1';
                                 
                                out_ready_to_read <= '1';                                
                                read_state <= finished;
                            when finished => 
                                bram_we <= '0';
                                out_ready_to_read <= '0';
                                state <= processing;
                        end case;  
                    end if;
                end if;
                        
                when processing =>
                    if k_counter < NUMBER_OF_VERTICES then
                        if i_counter <= NUMBER_OF_VERTICES then
                            case fw_state is --(init, read_i,read_k,find_min);
                                when init => 
                                    bram_we <= '0';
                                    --read i_th row
                                    if i_counter = NUMBER_OF_VERTICES then
                                        k_counter <= k_counter + 1;
                                        bram_addr <= 0;
                                        i_counter <= 0;
                                    else bram_addr <= i_counter;
                                    end if; --need to wait
                                    fw_state <= read_i;
                                when read_i =>
                                    bram_addr <= k_counter;
                                    fw_state <= read_k;
                                when read_k =>
                                    ith_row <= bram_out_value;
                                    
                                    fw_state <= read_ik;
                                    
                                when read_ik =>
                                    ik_value <= ith_row(k_counter * NUM_SIZE to (k_counter + 1) * NUM_SIZE - 1);
                                    kth_row <= bram_out_value;
                                    bram_addr <= i_counter;
                                    fw_state <= find_min;
                                when find_min =>
--                                    kth_row := bram_out_value;
                                    for j in 0 to NUMBER_OF_VERTICES - 1 loop
--                                        kj_value := kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1);
                                        
                                        
                                            if  to_integer(signed(ith_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))) > 
                                                to_integer(signed(ik_value)) + to_integer(signed(kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))) then
                                            ith_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1) <= 
                                                std_logic_vector(signed(ik_value) + signed(kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1)));
                                            end if;
                                          
                                    end loop;
                                    i_counter <= i_counter + 1;
                                    fw_state <= write_i;
                                    
                                 when write_i =>
--                                    --waiting
                                    bram_we <= '1';
                                    bram_in_value <= ith_row;
                                    fw_state <= init;
                                    
                            end case; 
--                         --read i_th row
                         --then k_th row
                            
                        end if;
                    else
                        read_state <= init;
                        out_t_valid <= '1';
                        state <= finished;
                    end if;
--                    --floyd-warshall here
                when finished =>
                    
                    if param_write_enable = '0' then
                        case read_state is
                            when init => 
                                bram_addr <= param_addr / NUMBER_OF_VERTICES; --row_id
                                column <= param_addr mod NUMBER_OF_VERTICES;
                                read_state <= wait_before_read;
                                out_t_valid <= '0';
                            when wait_before_read =>
                                --do nothing
                                read_state <= write_to_row;
                            when write_to_row =>
                                read_state <= read;
                            when read =>
                                current_row <= bram_out_value;
--                                report "current_row is " & to_string(current_row);
--                                out_value <= to_integer(signed(current_row(column * NUM_SIZE to (column + 1) * NUM_SIZE - 1)));
                                                                
                                read_state <= write_to_memory;
                            
                            when write_to_memory =>
                                out_value <= to_integer(signed(current_row(column * NUM_SIZE to (column + 1) * NUM_SIZE - 1)));
                                out_t_valid <= '1';                                
                                read_state <= init;
                            when finished =>
                                --nothing
                        end case;
                    end if;
                    
            
    end case;
  end if;
end process;
end behavioral;