--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the 
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose: 
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core is
	generic (
		-- Users to add parameters here
    C_BLOCK_SIZE          : integer := 256
	);
  port (
    -----------------------------------------------------------------------------
    -- Clocks and reset
    -----------------------------------------------------------------------------      
    clk                    :  in std_logic;
    reset_n                :  in std_logic;
      
    -----------------------------------------------------------------------------
    -- Slave msgin interface
    -----------------------------------------------------------------------------
    -- Message that will be sent out is valid
    msgin_valid            : in std_logic;   
    -- Slave ready to accept a new message
    msgin_ready            : out std_logic;
    -- Message that will be sent out of the rsa_msgin module
    msgin_data             :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    -- Indicates boundary of last packet
    msgin_last             :  in std_logic;
    
    -----------------------------------------------------------------------------
    -- Master msgout interface
    -----------------------------------------------------------------------------
    -- Message that will be sent out is valid
    msgout_valid            : out std_logic;   
    -- Slave ready to accept a new message
    msgout_ready            :  in std_logic;
    -- Message that will be sent out of the rsa_msgin module
    msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    -- Indicates boundary of last packet
    msgout_last             : out std_logic;

    -----------------------------------------------------------------------------
    -- Interface to the register block
    -----------------------------------------------------------------------------    
	key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    r_mod_n                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    r2_mod_n                :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    rsa_status              : out std_logic_vector(31 downto 0)    
          
  );
end rsa_core;

architecture rtl of rsa_core is

    type state_m1 is (WAIT_MSG, WAIT_IDLE, START_MONEXP);
    signal curr_state_m1, next_state_m1: state_m1;
    
    type state_m2 is (WAIT_RD_MSG, WAIT_MSGOUT_READY, END_READOUT);
    signal curr_state_m2, next_state_m2: state_m2;
      
    signal s_start_monexp, inc_in_counter, monexp_idle: std_logic;
    signal monexp_msgout_ready, inc_out_counter, monexp_msgvalid: std_logic;
    
    signal in_count_sel, out_count_sel: std_logic_vector (1 downto 0);
    signal monexp_input_counter: unsigned(1 downto 0);
    signal monexp_output_counter: unsigned(1 downto 0);
    
    signal monexp_msgin_valid_0, monexp_msgin_valid_1, monexp_msgin_valid_2, monexp_msgin_valid_3: std_logic;
    signal monexp_msgin_last_0, monexp_msgin_last_1, monexp_msgin_last_2, monexp_msgin_last_3: std_logic;
    signal monexp_idle_0, monexp_idle_1, monexp_idle_2, monexp_idle_3: std_logic;
    
    signal monexp_msgout_valid_0, monexp_msgout_valid_1, monexp_msgout_valid_2, monexp_msgout_valid_3: std_logic;
    signal monexp_msgout_0, monexp_msgout_1, monexp_msgout_2, monexp_msgout_3: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal monexp_msgout_last_0, monexp_msgout_last_1, monexp_msgout_last_2, monexp_msgout_last_3: std_logic;
    signal monexp_msgout_ready_0, monexp_msgout_ready_1, monexp_msgout_ready_2, monexp_msgout_ready_3: std_logic; 

begin
  --msgout_valid <= msgin_valid;   
  --msgin_ready  <= msgout_ready;
  --msgout_data  <= msgin_data xor key_n;
  --msgout_last  <= msgin_last;
  --rsa_status   <= (others => '0');
  
INPUT_DEMUX_COMB_PROC: process (in_count_sel, s_start_monexp, msgin_last)
begin
    monexp_msgin_valid_0 <= '0';
    monexp_msgin_valid_1 <= '0';
    monexp_msgin_valid_2 <= '0';
    monexp_msgin_valid_3 <= '0';
    
    monexp_msgin_last_0 <= '0';
    monexp_msgin_last_1 <= '0';
    monexp_msgin_last_2 <= '0';
    monexp_msgin_last_3 <= '0';
    
    if (in_count_sel = "00") then
        monexp_msgin_valid_0 <= s_start_monexp;
        monexp_msgin_last_0 <= msgin_last;
    elsif (in_count_sel = "01") then
        monexp_msgin_valid_1 <= s_start_monexp;
        monexp_msgin_last_1 <= msgin_last;
    elsif (in_count_sel = "10") then
        monexp_msgin_valid_2 <= s_start_monexp;
        monexp_msgin_last_2 <= msgin_last;
    elsif (in_count_sel = "11") then
        monexp_msgin_valid_3 <= s_start_monexp;
        monexp_msgin_last_3 <= msgin_last;
    end if;
end process INPUT_DEMUX_COMB_PROC;

INPUT_MUX_COMB_PROC: process (in_count_sel, monexp_idle_0, monexp_idle_1, monexp_idle_2, monexp_idle_3)
begin
    if (in_count_sel = "00") then
        monexp_idle <= monexp_idle_0;
    elsif (in_count_sel = "01") then
        monexp_idle <= monexp_idle_1;
    elsif (in_count_sel = "10") then
        monexp_idle <= monexp_idle_2;
    elsif (in_count_sel = "11") then
        monexp_idle <= monexp_idle_3;
    end if;
end process INPUT_MUX_COMB_PROC;

OUTPUT_MUX_COMB_PROC: process (out_count_sel,
        monexp_msgout_valid_0, monexp_msgout_valid_1, monexp_msgout_valid_2, monexp_msgout_valid_3,
        monexp_msgout_0, monexp_msgout_1, monexp_msgout_2, monexp_msgout_3,
        monexp_msgout_last_0, monexp_msgout_last_1, monexp_msgout_last_2, monexp_msgout_last_3)
begin
    if (out_count_sel = "00") then
        monexp_msgvalid <= monexp_msgout_valid_0;
        msgout_data <= monexp_msgout_0;
        msgout_last <= monexp_msgout_last_0;
    elsif (out_count_sel = "01") then
        monexp_msgvalid <= monexp_msgout_valid_1;
        msgout_data <= monexp_msgout_1;
        msgout_last <= monexp_msgout_last_1;
    elsif (out_count_sel = "10") then
        monexp_msgvalid <= monexp_msgout_valid_2;
        msgout_data <= monexp_msgout_2;
        msgout_last <= monexp_msgout_last_2;
    elsif (out_count_sel = "11") then
        monexp_msgvalid <= monexp_msgout_valid_3;
        msgout_data <= monexp_msgout_3;
        msgout_last <= monexp_msgout_last_3;
    end if;
end process OUTPUT_MUX_COMB_PROC;

OUTPUT_DEMUX_COMB_PROC: process (out_count_sel, monexp_msgout_ready)
begin
    monexp_msgout_ready_0 <= '0';
    monexp_msgout_ready_1 <= '0';
    monexp_msgout_ready_2 <= '0';
    monexp_msgout_ready_3 <= '0';
    
    if (out_count_sel = "00") then
        monexp_msgout_ready_0 <= monexp_msgout_ready;
    elsif (out_count_sel = "01") then
        monexp_msgout_ready_1 <= monexp_msgout_ready;
    elsif (out_count_sel = "10") then
        monexp_msgout_ready_2 <= monexp_msgout_ready;
    elsif (out_count_sel = "11") then
        monexp_msgout_ready_3 <= monexp_msgout_ready;
    end if;
end process OUTPUT_DEMUX_COMB_PROC;

INPUT_COUNTER_PROC: process (clk, reset_n)
begin
    if (reset_n = '0') then
        monexp_input_counter <= (others => '0');
    elsif rising_edge(clk) then
        if(inc_in_counter = '1') then
            if(monexp_input_counter = 3) then
                monexp_input_counter <= (others => '0');
            else
                monexp_input_counter <= monexp_input_counter + 1;
            end if;
        else 
            monexp_input_counter <= monexp_input_counter; 
        end if;
    end if;
end process INPUT_COUNTER_PROC;
in_count_sel <= std_logic_vector(monexp_input_counter);

OUTPUT_COUNTER_PROC: process (clk, reset_n)
begin
    if (reset_n = '0') then
        monexp_output_counter <= (others => '0');
    elsif rising_edge(clk) then
        if(inc_out_counter = '1') then
            if(monexp_output_counter = 3) then
                monexp_output_counter <= (others => '0');
            else
                monexp_output_counter <= monexp_output_counter + 1;
            end if;
        else 
            monexp_output_counter <= monexp_output_counter; 
        end if;
    end if;
end process OUTPUT_COUNTER_PROC;
out_count_sel <= std_logic_vector(monexp_output_counter);

-- ModExp modules
ModExp_0: entity work.rsa_modexp(Behavioral)
port map( 
        clk               => clk,
        reset_n           => reset_n,
        msgin_valid       => monexp_msgin_valid_0,  
        msgin_data        => msgin_data,
        is_idle           => monexp_idle_0,
        msgout_ready      => monexp_msgout_ready_0,
        msgout_valid      => monexp_msgout_valid_0,
        msgout_data       => monexp_msgout_0,
        key_e_d           => key_e_d,
        key_n             => key_n,
        r_mod_n           => r_mod_n,
        r2_mod_n          => r2_mod_n,
        rsa_status        => rsa_status
    );
    
ModExp_1: entity work.rsa_modexp(Behavioral)
port map( 
        clk               => clk,
        reset_n           => reset_n,
        msgin_valid       => monexp_msgin_valid_1,  
        msgin_data        => msgin_data,
        is_idle           => monexp_idle_1,
        msgout_ready      => monexp_msgout_ready_1,
        msgout_valid      => monexp_msgout_valid_1,
        msgout_data       => monexp_msgout_1,
        key_e_d           => key_e_d,
        key_n             => key_n,
        r_mod_n           => r_mod_n,
        r2_mod_n          => r2_mod_n,
        rsa_status        => rsa_status
    );

ModExp_2: entity work.rsa_modexp(Behavioral)
port map( 
        clk               => clk,
        reset_n           => reset_n,
        msgin_valid       => monexp_msgin_valid_2,  
        msgin_data        => msgin_data,
        is_idle           => monexp_idle_2,
        msgout_ready      => monexp_msgout_ready_2,
        msgout_valid      => monexp_msgout_valid_2,
        msgout_data       => monexp_msgout_2,
        key_e_d           => key_e_d,
        key_n             => key_n,
        r_mod_n           => r_mod_n,
        r2_mod_n          => r2_mod_n,
        rsa_status        => rsa_status
    );
    
ModExp_3: entity work.rsa_modexp(Behavioral)
port map( 
        clk               => clk,
        reset_n           => reset_n,
        msgin_valid       => monexp_msgin_valid_3,  
        msgin_data        => msgin_data,
        is_idle           => monexp_idle_3,
        msgout_ready      => monexp_msgout_ready_3,
        msgout_valid      => monexp_msgout_valid_3,
        msgout_data       => monexp_msgout_3,
        key_e_d           => key_e_d,
        key_n             => key_n,
        r_mod_n           => r_mod_n,
        r2_mod_n          => r2_mod_n,
        rsa_status        => rsa_status
    );
    
--FSM M1
 Synch_state_proc_m1: process (reset_n, clk)
 begin
     if (reset_n = '0') then
         curr_state_m1 <= WAIT_MSG;
     elsif rising_edge(clk) then
         curr_state_m1 <= next_state_m1;
     end if;
 end process Synch_state_proc_m1;
 
 Comb_proc_m1: process (curr_state_m1, msgin_valid, monexp_idle)
 begin

    s_start_monexp <= '0';
    inc_in_counter <= '0';
    msgin_ready <= '0';
    
    case (curr_state_m1) is
    when WAIT_MSG =>
        s_start_monexp <= '0';
        inc_in_counter <= '0';
        msgin_ready <= '0';
         
        if (msgin_valid = '1') then
            next_state_m1 <= WAIT_IDLE;
        else
            next_state_m1 <= WAIT_MSG;
        end if;
        
    when WAIT_IDLE =>        
        if (monexp_idle = '1') then
            next_state_m1 <= START_MONEXP;
        else
            next_state_m1 <= WAIT_IDLE;
        end if;

    when START_MONEXP =>
        s_start_monexp <= '1';
        inc_in_counter <= '1';
        msgin_ready <= '1';
        
        next_state_m1 <= WAIT_MSG;
             
     when others => 
         next_state_m1 <= WAIT_MSG;
     end case;
 end process Comb_proc_m1;
 
 
 --FSM M2
  Synch_state_proc_m2: process (reset_n, clk)
  begin
      if (reset_n = '0') then
          curr_state_m2 <= WAIT_RD_MSG;
      elsif rising_edge(clk) then
          curr_state_m2 <= next_state_m2;
      end if;
  end process Synch_state_proc_m2;
  
  Comb_proc_m2: process (curr_state_m2, monexp_msgvalid, msgout_ready)
  begin
 
     monexp_msgout_ready <= '0';
     inc_out_counter <= '0';
     msgout_valid <= '0';
     
     case (curr_state_m2) is
     when WAIT_RD_MSG =>
         monexp_msgout_ready <= '0';
         inc_out_counter <= '0';
          
         if (monexp_msgvalid = '1') then
             next_state_m2 <= WAIT_MSGOUT_READY;
         else
             next_state_m2 <= WAIT_RD_MSG;
         end if;
         
     when WAIT_MSGOUT_READY => 
         msgout_valid <= '1';       
         if (msgout_ready = '1') then
             next_state_m2 <= END_READOUT;
         else
             next_state_m2 <= WAIT_MSGOUT_READY;
         end if;
 
     when END_READOUT =>
         monexp_msgout_ready <= '1';
         inc_out_counter <= '1';
         msgout_valid <= '0';
         
         next_state_m2 <= WAIT_RD_MSG;
              
      when others => 
          next_state_m2 <= WAIT_RD_MSG;
      end case;
  end process Comb_proc_m2;
  
  
end rtl;
