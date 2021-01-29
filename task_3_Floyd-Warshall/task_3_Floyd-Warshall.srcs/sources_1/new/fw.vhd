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
    generic(NUMBER_OF_VERTICES : integer range 1 to 64 := 32; NUM_SIZE : integer :=32);
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

signal bram_raddr : integer range 0 to NUMBER_OF_VERTICES - 1;
signal bram_waddr : integer range 0 to NUMBER_OF_VERTICES - 1;
signal bram_in_value : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
signal bram_out_value : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 )-1);
signal bram_we : std_logic;

--for debug purposes
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
--end of debug purposes


signal param_value_buffer1 : integer;

signal param_addr_buffer1 : integer range 0 to NUMBER_OF_VERTICES - 1;


component bram
    generic(NUMBER_OF_VERTICES : integer range 1 to 64 := NUMBER_OF_VERTICES; NUM_SIZE : integer := 32);
    port(waddr : integer range 0 to NUMBER_OF_VERTICES - 1;
         raddr : integer range 0 to NUMBER_OF_VERTICES - 1;
         clk : in std_logic; 
         d_input : in std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 ) - 1); 
         we : in std_logic; 
         d_output : out std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 ) - 1));
end component;


type STATE_TYPE is (ready_to_read,processing,finished);
type READ_TYPE is (init,read,finished,wait_before_read,write_to_row,write_to_memory);
type FW_TYPE is (init, read_i,read_k,find_min1,find_min2,write_i,read_ik,wait_k);
type LOCK_TYPE is (lock_find1, lock_find2, lock_find2_again, unlock);

type ith_rows_type is array(0 to 3) of std_logic_vector(0 to (NUMBER_OF_VERTICES * NUM_SIZE )-1);
type ik_s_type is array(0 to 2) of std_logic_vector(0 to NUM_SIZE - 1);
type minimum_vectors_type is array(0 to 1) of std_logic_vector(0 to NUMBER_OF_VERTICES - 1);
type minimum_vector_type is array(0 to NUMBER_OF_VERTICES - 1) of integer range 0 to 1;

signal state : STATE_TYPE := ready_to_read;
signal read_state : READ_TYPE;
signal fw_state : FW_TYPE;
signal lock : LOCK_TYPE;

signal column : integer range 0 to NUMBER_OF_VERTICES - 1;

signal k_counter : integer range -4 to NUMBER_OF_VERTICES;
signal i_counter : integer range 0 to NUMBER_OF_VERTICES;
signal pipeline_length : integer range 0 to 6;

signal i_counter_context : integer range 0 to NUMBER_OF_VERTICES;
signal bram_raddr_context : integer range 0 to NUMBER_OF_VERTICES - 1;

signal ith_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * NUM_SIZE )-1);
signal new_ith_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * NUM_SIZE )-1);

signal kth_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * NUM_SIZE )-1);
signal ik_value : std_logic_vector(0 to NUM_SIZE - 1);
signal ik_plus_kj : std_logic_vector(0 to NUM_SIZE - 1);
signal kj_value : std_logic_vector(0 to NUM_SIZE - 1);


signal ith_rows : ith_rows_type;
signal ik_s : ik_s_type;

signal minimum_vector : std_logic_vector(0 to NUMBER_OF_VERTICES - 1);
--signal minimum_vector : minimum_vector_type;
signal left : integer range 0 to NUMBER_OF_VERTICES * NUM_SIZE - 1;
signal right : integer range 0 to NUMBER_OF_VERTICES * NUM_SIZE - 1;

signal current_row : std_logic_vector(0 to (NUMBER_OF_VERTICES * 32 ) - 1);


begin

graph: bram
    generic map(NUMBER_OF_VERTICES => NUMBER_OF_VERTICES,NUM_SIZE => NUM_SIZE)
    port map(waddr => bram_waddr, raddr => bram_raddr, clk => clk,d_input => bram_in_value, we => bram_we, d_output => bram_out_value);

fw: process (clk,rst)

variable tmp: std_logic_vector(0 to NUM_SIZE - 1);

begin

    if rising_edge(clk) then
        
        if rst = '1' then
         i_counter <= 0;
         k_counter <= 0;
         out_t_valid <= '0';
         out_ready_to_read <= '1';
         bram_we <= '0';
         state <= ready_to_read;
         read_state <= init;
         fw_state <= init;
         pipeline_length <= 6;
        
        end if;
        
        case state is
            when ready_to_read =>
                if param_t_valid = '1' then
                    if param_t_last = '0' then
                        case read_state is 
                            when init =>
                                bram_we <= '0';
                                param_value_buffer1 <= param_value; --first read
                                bram_raddr <= param_addr / NUMBER_OF_VERTICES; --row_id
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
                                bram_waddr <= param_addr / NUMBER_OF_VERTICES;
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
                                bram_raddr <= param_addr / NUMBER_OF_VERTICES; --row_id
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
                                bram_waddr <= param_addr / NUMBER_OF_VERTICES; 
                                out_ready_to_read <= '1';                                
                                read_state <= finished;
                            when finished => 
                                bram_we <= '0';
                                bram_raddr <= k_counter; --start with k = 0;
                                out_ready_to_read <= '0';
                                state <= processing;
                        end case;  
                    end if;
                end if;
                        
                when processing =>
--                    if k_counter < NUMBER_OF_VERTICES then
                        --read [k,j] \forall j
                   
                            case fw_state is --(init, read_i,read_k,find_min);
                                when init => --read kth here 
                                    bram_we <= '0';
                                    --read i_th row
--                                   
                                     --need to wait
                                    fw_state <= read_k;
                                
                                when read_k => 
                                    bram_raddr <= i_counter; --read ith_row then
                                    i_counter <= i_counter + 1;
                                    kth_row <= bram_out_value;
                                    fw_state <= read_i;
                                
                                when read_i =>
                                    bram_raddr <= i_counter; -- read next i
                                    bram_we <= '0';
                                    i_counter <= i_counter + 1;
                                    fw_state <= wait_k;
                                    
                                when wait_k => --read_i process starts here
                                    bram_raddr <= i_counter; --i_counter will be read in ith_rows(0)
                                    ith_row <= bram_out_value;
                                    ik_value <= ith_row(k_counter * NUM_SIZE to (k_counter + 1) * NUM_SIZE - 1); --does not "width-typecheck"
                                    i_counter <= i_counter + 1;
                                    fw_state <= read_ik;    
                                
                                --read_ik start at this point ith_rows(0) = i_0
                                when read_ik => --i_counter + 1 in ith_rows(0) ik is ith_rows(0)[k]
--                                    
                                    bram_raddr <= i_counter;
                                    i_counter <= i_counter + 1;
                                    fw_state <= find_min1;
--                                    at this point ith_rows(1) = i_0
                                when find_min1 => --need ik(1) and ith_rows(2)
                                    
                                        bram_raddr <= i_counter;
                                        i_counter <= i_counter + 1;
--                                        end if;
                                        
                                        fw_state <= find_min2;
                                   
--                                    at this point ith_rows(2) = i_0
                                when find_min2 => --will be locked at 1st iter
                                    
                                        if lock = lock_find1 then
                                            bram_raddr <= bram_raddr_context;
                                            i_counter <= i_counter_context;
                                        else
                                            bram_raddr <= i_counter;
                                            i_counter <= i_counter + 1;
                                            
                                        end if;    
                                       fw_state <= write_i;
                                            
--                                    at this point ith_rows(3) = i_0
                                 when write_i => 
--                                    
                                        
                                        case lock is
                                            when lock_find1 =>
                                                bram_we <= '1';
                                                bram_raddr <= bram_raddr_context;
                                                i_counter <= i_counter_context;
--                                                store
                                                bram_waddr <= i_counter - pipeline_length; --need to read up to the end here
                                                bram_in_value <= new_ith_row;
                                                
                                            when lock_find2 => --unpdate k_rh row
                                                if i_counter <= NUMBER_OF_VERTICES - 1 then
                                                    bram_raddr <= i_counter;
                                                end if;
                                                i_counter <= i_counter + 1;
                                                kth_row <= new_ith_row; 
                                            when lock_find2_again =>
                                                if i_counter <= NUMBER_OF_VERTICES - 1 then
                                                    bram_raddr <= i_counter;
                                                end if;
                                                i_counter <= i_counter + 1;
                                            when unlock =>
                                                bram_we <= '1';
                                               if i_counter < NUMBER_OF_VERTICES - 1 + 7 then
                                                
                                                if i_counter <= NUMBER_OF_VERTICES - 1 then
                                                    bram_raddr <= i_counter;
                                                end if;
                                                
                                                i_counter <= i_counter + 1;
                                                bram_waddr <= i_counter - pipeline_length; --need to read up to the end here
                                                bram_in_value <= new_ith_row;
                                               else
                                                   
                                                k_counter <= k_counter + 1;
                                                i_counter <= 0;
                                                if k_counter /= NUMBER_OF_VERTICES - 1 then 
                                                    bram_raddr <= k_counter + 1;
                                                else
                                                    read_state <= init;
                                                    out_t_valid <= '1';
                                                    bram_we <= '0';
                                                    state <= finished; 
                                                end if;
                                                fw_state <= init;
                                               
                                        end if;
                                                 
                                                
                                        end case;
                            end case; 
--                         --read i_th row
                         --then k_th row
                            
                        
--                    --floyd-warshall here
                when finished =>
                    
                    if param_write_enable = '0' then
                        case read_state is
                            when init => 
                                bram_we <= '0';
                                bram_raddr <= param_addr / NUMBER_OF_VERTICES; --row_id
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

read_ik_s : process(clk) is 
begin
    if rising_edge(clk) and (lock = unlock or lock = lock_find2_again) then
        if fw_state = read_ik or fw_state = find_min1 or fw_state = find_min2 or fw_state = write_i then
            ik_s(0) <= ith_rows(0)(k_counter * NUM_SIZE to (k_counter + 1) * NUM_SIZE - 1);
            for i in 1 to 2 loop
                ik_s(i) <= ik_s(i-1);
            end loop;
        end if;
    end if;
end process;

read_ith_row : process(clk) is
begin
    if rising_edge(clk) and (lock = unlock or lock = lock_find2_again) then
        
        if fw_state = wait_k or fw_state = read_ik or fw_state = find_min1 or fw_state = find_min2 or fw_state = write_i then --check state as well
            ith_rows(0) <= bram_out_value;
                for i in 1 to 3 loop
                    ith_rows(i) <= ith_rows(i-1);
            end loop;
        end if;
    end if;
end process;


find_min1_ps : process(clk) is
begin
--if k == i_counter need to update k first
if rising_edge(clk) then
    if rst = '1' then lock <= unlock; else
    
    case lock is 
        when unlock =>
        
            if fw_state = find_min1 or fw_state = find_min2 or fw_state = write_i then
                for j in 0 to NUMBER_OF_VERTICES - 1 loop
--                                        kj_value := kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1);
                                        
                                            --g(i,j) > [i,k] + [k,j]
                    if  (signed(ith_rows(1)(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))) > 
                        (signed(ik_s(0))) + (signed(kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))) then
                              minimum_vector(j) <= '0';
                    else minimum_vector(j) <= '1';    
                    end if;
                                            
                                          
                end loop;
    
                if k_counter = i_counter - 4 then --need to pause for 3 cycles
                    lock <= lock_find1;
                    i_counter_context <= i_counter;
                    bram_raddr_context <= bram_raddr;
    
                end if;
    
            end if;
        
        when lock_find1 =>
            lock <= lock_find2;
            
        when lock_find2 => --write is updating kth_row
            lock <= lock_find2_again;
        when lock_find2_again =>
            if fw_state = find_min1 or fw_state = find_min2 or fw_state = write_i then
                for j in 0 to NUMBER_OF_VERTICES - 1 loop
--                                        
                                        
                                            --g(i,j) > [i,k] + [k,j]
                    if  (signed(ith_rows(1)(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))) > 
                        (signed(ik_s(0))) + (signed(kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))) then
                              minimum_vector(j) <= '0';
                    else minimum_vector(j) <= '1';    
                    end if;
                                            
                                          
                end loop;
    
                    
                    
            end if;
            lock <= unlock;
    end case;
     end if;
end if; 

end process;

find_min2ps : process(clk) is

begin
    if rising_edge(clk) then
    
      if lock = unlock or lock = lock_find1 then
        if fw_state = find_min2 or fw_state = write_i then

--                new_ith_row <= ith_rows(2);
            for j in 0 to NUMBER_OF_VERTICES - 1 loop
                
                if minimum_vector(j) = '0' then
                    new_ith_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1) <= std_logic_vector(signed(ik_s(1)) + signed(kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1)));
                else 
                     new_ith_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1) <= ith_rows(2)(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1);
                end if;
--                new_ith_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1) <= std_logic_vector(to_signed((minimum_vector(j) * to_integer(signed(ith_rows(2)(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))) +
--                         (1 - minimum_vector(j)) * (to_integer(signed(ik_s(1))) + to_integer(signed(kth_row(j * NUM_SIZE to (j + 1) * NUM_SIZE - 1))))),NUM_SIZE));
             end loop;

      end if;
      end if;
     end if;
end process;

end behavioral;