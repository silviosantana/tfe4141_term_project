library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity rsa_core_tb is
generic (
          C_BLOCK_SIZE          : integer := 256
          );
end rsa_core_tb;

architecture Behavioral of rsa_core_tb is

     signal clk: std_logic;
     signal reset_n: std_logic;
     
     signal start_write: std_logic;
     signal start_read: std_logic;
    
     signal msgin_valid  : std_logic;   
     signal msgin_ready  : std_logic;
     signal msgin_data   : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
     signal msgin_last   : std_logic;
     
     -----------------------------------------------------------------------------
     -- core-msgout interface
     -----------------------------------------------------------------------------
     signal msgout_valid : std_logic;   
     signal msgout_ready : std_logic;
     signal msgout_data  : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
     signal msgout_last  : std_logic;
    
     -----------------------------------------------------------------------------
     -- Interface to the register block
     -----------------------------------------------------------------------------    
     signal key_e_d      : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
     signal key_n        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
     signal r_mod_n      : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
     signal r2_mod_n        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
     signal rsa_status   : std_logic_vector(31 downto 0);
    
    
    signal msgout_1        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal msgout_2        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal msgout_3        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal msgout_4        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal msgout_5        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal msgout_6        : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    
    type state_write is (IDLE_WRITE, SEND_1, SEND_2, SEND_3, SEND_4, SEND_5, SEND_6);
    signal curr_state_m1, next_state_m1: state_write;
    
    type state_read is (IDLE_READ, READ_1, SAVE_1, READ_2, SAVE_2, READ_3, SAVE_3, READ_4, SAVE_4, READ_5, SAVE_5, READ_6, SAVE_6);
    signal curr_state_m2, next_state_m2: state_read;
    
    constant clock_period: time := 10 ns;
    signal stop_the_clock: boolean;
begin

RSA_CORE_0: entity work.rsa_core(rtl)
port map( 
        clk               => clk,
        reset_n           => reset_n,
        msgin_valid       => msgin_valid,
        msgin_ready       => msgin_ready,  
        msgin_data        => msgin_data,
        msgin_last        => msgin_last,
        msgout_valid      => msgout_valid,
        msgout_ready      => msgout_ready,
        msgout_data       => msgout_data,
        msgout_last       => msgout_last,
        key_e_d           => key_e_d,
        key_n             => key_n,
        r_mod_n           => r_mod_n,
        r2_mod_n          => r2_mod_n,
        rsa_status        => rsa_status
    );

stimulus: process
  begin
  
    -- Put initialisation code here
    key_e_d     <=  std_logic_vector(to_unsigned(10, 256));
    key_n       <=  std_logic_vector(to_unsigned(13, 256));
    r_mod_n     <=  std_logic_vector(to_unsigned(3, 256));
    r2_mod_n    <=  std_logic_vector(to_unsigned(9, 256));
    start_write  <= '0';
    start_read  <= '0';
    
    
    reset_n <= '1';
    wait for clock_period/2;
    reset_n <= '0';
    wait for clock_period;
    reset_n <= '1';
    

    wait for clock_period;
    start_write  <= '1';
    wait for clock_period;
    start_write  <= '0';
    
    wait for clock_period;
    start_read  <= '1';
    wait for clock_period;
    start_read  <= '0';
    
    wait for 500*clock_period;

    -- Put test bench stimulus code here

    --stop_the_clock <= true;
    wait;
  end process stimulus;

clocking: process
begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
end process clocking;

--FSM M1
 Synch_state: process (reset_n, clk)
 begin
     if (reset_n = '0') then
         curr_state_m1 <= IDLE_WRITE;
         curr_state_m2 <= IDLE_READ;
     elsif rising_edge(clk) then
         curr_state_m1 <= next_state_m1;
         curr_state_m2 <= next_state_m2;
     end if;
 end process Synch_state;
 
 Comb_proc_write: process (curr_state_m1, msgin_ready, start_write)
 begin

    msgin_data  <=  std_logic_vector(to_unsigned(0, 256));
    msgin_valid <= '0';
    msgin_last <= '0';
    
    case (curr_state_m1) is
    when IDLE_WRITE =>
        msgin_data  <=  std_logic_vector(to_unsigned(0, 256));
        msgin_valid <= '0';
        msgin_last <= '0';
        
        if (start_write = '1') then
            next_state_m1 <= SEND_1;
        else
            next_state_m1 <= IDLE_WRITE;
        end if;
        
    when SEND_1 =>
        msgin_data  <=  std_logic_vector(to_unsigned(7, 256));
        msgin_valid  <= '1';
        msgin_last <= '0';
                
        if (msgin_ready = '1') then
            next_state_m1 <= SEND_2;
        else
            next_state_m1 <= SEND_1;
        end if;
        
    when SEND_2 =>
        msgin_data  <=  std_logic_vector(to_unsigned(2564, 256));
        msgin_valid  <= '1';
        msgin_last <= '0';
                
        if (msgin_ready = '1') then
            next_state_m1 <= SEND_3;
        else
            next_state_m1 <= SEND_2;
        end if;
    
    when SEND_3 =>
        msgin_data  <=  std_logic_vector(to_unsigned(2465451, 256));
        msgin_valid  <= '1';
        msgin_last <= '0';
                
        if (msgin_ready = '1') then
            next_state_m1 <= SEND_4;
        else
            next_state_m1 <= SEND_3;
        end if;

    when SEND_4 =>
        msgin_data  <=  std_logic_vector(to_unsigned(788912, 256));
        msgin_valid  <= '1';
        msgin_last <= '0';
                
        if (msgin_ready = '1') then
            next_state_m1 <= SEND_5;
        else
            next_state_m1 <= SEND_4;
        end if;
        
     when SEND_5 =>
        msgin_data  <=  std_logic_vector(to_unsigned(12254, 256));
        msgin_valid  <= '1';
        msgin_last <= '0';
                
        if (msgin_ready = '1') then
            next_state_m1 <= SEND_6;
        else
            next_state_m1 <= SEND_5;
        end if;
        
     when SEND_6 =>
        msgin_data  <=  std_logic_vector(to_unsigned(7, 256));
        msgin_valid  <= '1';
        msgin_last <= '1';
                
        if (msgin_ready = '1') then
            next_state_m1 <= IDLE_WRITE;
        else
            next_state_m1 <= SEND_6;
        end if;
   
             
     when others => 
         next_state_m1 <= IDLE_WRITE;
     end case;
 end process Comb_proc_write;
 
 Comb_proc_read: process (curr_state_m2, msgout_valid, start_read, msgout_data)
  begin
    
    msgout_ready <= '0';
     
     case (curr_state_m2) is
     when IDLE_READ =>
         msgout_ready <= '0';
         
         if (start_read = '1') then
             next_state_m2 <= READ_1;
         else
             next_state_m2 <= IDLE_READ;
         end if;
         
     when READ_1 =>
         msgout_ready <= '0';
                 
         if (msgout_valid = '1') then
             next_state_m2 <= SAVE_1;
         else
             next_state_m2 <= READ_1;
         end if;
         
     when SAVE_1 =>
         msgout_ready <= '1';
         msgout_1 <= msgout_data;
         
         next_state_m2 <= READ_2;
         
      when READ_2 =>
          msgout_ready <= '0';
                  
          if (msgout_valid = '1') then
              next_state_m2 <= SAVE_2;
          else
              next_state_m2 <= READ_2;
          end if;
          
      when SAVE_2 =>
          msgout_ready <= '1';
          msgout_2 <= msgout_data;
          
          next_state_m2 <= READ_3;
          
      when READ_3 =>
           msgout_ready <= '0';
                   
           if (msgout_valid = '1') then
               next_state_m2 <= SAVE_3;
           else
               next_state_m2 <= READ_3;
           end if;
           
       when SAVE_3 =>
           msgout_ready <= '1';
           msgout_3 <= msgout_data;
           
           next_state_m2 <= READ_4;
           
      when READ_4 =>
          msgout_ready <= '0';
                  
          if (msgout_valid = '1') then
              next_state_m2 <= SAVE_4;
          else
              next_state_m2 <= READ_4;
          end if;
          
      when SAVE_4 =>
          msgout_ready <= '1';
          msgout_4 <= msgout_data;
          
          next_state_m2 <= READ_5;
          
      when READ_5 =>
         msgout_ready <= '0';
                 
         if (msgout_valid = '1') then
             next_state_m2 <= SAVE_5;
         else
             next_state_m2 <= READ_5;
         end if;
         
     when SAVE_5 =>
         msgout_ready <= '1';
         msgout_5 <= msgout_data;
         
         next_state_m2 <= READ_6;  
         
     when READ_6 =>
          msgout_ready <= '0';
                  
          if (msgout_valid = '1') then
              next_state_m2 <= SAVE_6;
          else
              next_state_m2 <= READ_6;
          end if;
          
      when SAVE_6 =>
          msgout_ready <= '1';
          msgout_6 <= msgout_data;
          
          next_state_m2 <= IDLE_READ;          
     
   
      when others => 
          next_state_m2 <= IDLE_READ;
      end case;
  end process Comb_proc_read;

end Behavioral;
