----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2018 11:15:53 AM
-- Design Name: 
-- Module Name: rsa_modexp - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rsa_modexp is
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
        -- Message that will be sent out of the rsa_msgin module
        msgin_data             :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        is_idle                :  out std_logic;
        -----------------------------------------------------------------------------
        -- Master msgout interface
        -----------------------------------------------------------------------------
        -- Message that will be sent out is valid
        msgout_ready            : in std_logic;
        msgout_valid            : out std_logic;   
        -- Message that will be sent out of the rsa_msgin module
        msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        
        -----------------------------------------------------------------------------
        -- Interface to the register block
        -----------------------------------------------------------------------------    
        key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        r_mod_n                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        r2_mod_n                :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        rsa_status              : out std_logic_vector(31 downto 0)
    );
end rsa_modexp;

architecture Behavioral of rsa_modexp is

    type state is (IDLE, ONE, ONE_A, TWO, THREE, THREE_A, THREE_A_2, THREE_B, THREE_C, THREE_D, FOUR, FIVE, SIX);
    signal curr_state, next_state: state;
    
    -----------------------------------------------------------------------------
    -- Montegomery Product Module signals
    ----------------------------------------------------------------------------- 
    signal prod_valid, EN_prod, RST_prod: std_logic;
    
    -----------------------------------------------------------------------------
    -- Internal signals
    -----------------------------------------------------------------------------
    signal EN_x, EN_m, EN_r, EN_in_m: std_logic;
    signal S0, S1: std_logic;
    signal S2: std_logic_vector(1 downto 0);
    
    --counter signals
    signal count_overflow, load_counter, dec_count: std_logic;
    signal exp_iteration_cnt: unsigned(7 downto 0);
    
    -- E_shifter signals
    signal E_load, E_shift, E_msb: std_logic;
    signal E_reg: std_logic_vector (C_BLOCK_SIZE-1 downto 0);
    
    -----------------------------------------------------------------------------
    -- Internal registers
    -----------------------------------------------------------------------------
    signal x_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal m_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal m_in_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal r_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    
    -----------------------------------------------------------------------------
    -- Internal wires
    -----------------------------------------------------------------------------
    signal w_x_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal w_m_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal w_m_in_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
   -- signal w_r_reg: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal w_mon_pro_result: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal w_m1: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal w_m2: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    
    
   

begin 
    w_x_reg <= x_reg;
    w_m_reg <= m_reg;
    w_m_in_reg <= m_in_reg;
    
    msgout_data <= r_reg;
    
    Counter_proc: process (clk, reset_n)
    begin
        if (reset_n = '0') then
            --exp_iteration_cnt <= (others => '0');
            exp_iteration_cnt <= to_unsigned(C_BLOCK_SIZE-1,8);
        elsif rising_edge(clk) then
            if(load_counter = '1') then
                exp_iteration_cnt <= to_unsigned(C_BLOCK_SIZE-1,8);
            elsif (dec_count = '1') then
                exp_iteration_cnt <= exp_iteration_cnt - 1;
            end if;
        end if;
    end process Counter_proc;
    count_overflow <= nor_reduce(std_logic_vector(exp_iteration_cnt));
    --count_overflow <= exp_iteration_cnt(8);
    
    E_shift_reg_proc: process (clk, reset_n)
    begin
      if (reset_n = '0') then
          E_reg <= (others => '0');
      elsif rising_edge(clk) then
          if(E_load = '1') then
              E_reg <= key_e_d;
          elsif (E_shift = '1') then
              E_reg <= std_logic_vector(shift_left(unsigned(E_reg), 1));
          end if;
      end if;
    end process E_shift_reg_proc;
    E_msb <= E_reg(C_BLOCK_SIZE-1);

    X_REG_PROC: process (clk, reset_n)
    begin
        if (reset_n = '0') then
            x_reg <= (others => '0');
        elsif rising_edge(clk) then
            if(EN_x = '1') then
                if (S0 = '0') then
                    x_reg <= w_mon_pro_result;
                elsif (S0 = '1') then
                    x_reg <= r_mod_n;
                end if;
            end if; 
        end if;
    end process X_REG_PROC;
    
    M_IN_REG_PROC: process (clk, reset_n)
    begin
        if (reset_n = '0') then
            m_in_reg <= (others => '0');
        elsif rising_edge(clk) then
            if(EN_in_m = '1') then
                m_in_reg <= msgin_data;
            end if; 
        end if;
    end process M_IN_REG_PROC;
    
    M_REG_PROC: process (clk, reset_n)
    begin
        if (reset_n = '0') then
            m_reg <= (others => '0');
        elsif rising_edge(clk) then
            if(EN_m = '1') then
                m_reg <= w_mon_pro_result;
            end if; 
        end if;
    end process M_REG_PROC;
    
    R_REG_PROC: process (clk, reset_n)
    begin
        if (reset_n = '0') then
            r_reg <= (others => '0');
        elsif rising_edge(clk) then
            if(EN_r = '1') then
                r_reg <= w_mon_pro_result;
            end if; 
        end if;
    end process R_REG_PROC;
    
    M1_COMB_PROC: process (S1, w_x_reg)
    begin
        if (S1 = '0') then
            w_m1 <= w_x_reg;
        elsif (S1 = '1') then
            w_m1 <= r2_mod_n;
        end if;
    end process M1_COMB_PROC;
    
    M2_COMB_PROC: process (S2, w_x_reg, w_m_reg, msgin_data)
    begin
        if (S2 = "00") then
            w_m2 <= w_x_reg;
        elsif (S2 = "01") then
            w_m2 <= w_m_in_reg;
        elsif (S2 = "10") then
            w_m2 <= w_m_reg;
        elsif (S2 = "11") then
            w_m2 <=  std_logic_vector(to_unsigned(1, C_BLOCK_SIZE));
        end if;
    end process M2_COMB_PROC;
    
    --TODO instantiate MonPro
    MonPro: entity work.dummy_monpro(Behavioral)
    port map( 
            A             => w_m1,
            B             => w_m2,
            start_prod    => EN_prod,
            clk           => clk,
            reset_n       => RST_prod,
            
            out_xor       =>  w_mon_pro_result,
            valid_out     => prod_valid
        );
    
    --FSM
    Synch_state_proc: process (reset_n, clk)
    begin
        if (reset_n = '0') then
            curr_state <= IDLE;
        elsif rising_edge(clk) then
            curr_state <= next_state;
        end if;
    end process Synch_state_proc;
    
    Comb_proc: process (curr_state, msgin_valid, prod_valid, count_overflow, E_msb, msgout_ready)
    begin
        
        S0 <= '0'; 
        S1 <= '0';
        S2 <= "00"; 
        EN_x <= '0';
        EN_m <= '0';
        EN_in_m <= '0';
        EN_r <= '0';
        EN_prod <= '0';
        RST_prod <= '1';
        msgout_valid <= '0';
        load_counter <= '0'; 
        dec_count <= '0';
        E_load <= '0';
        E_shift <= '0';
        is_idle <= '0';
      
        case (curr_state) is
        when IDLE =>
            S0 <= '0'; 
            S1 <= '0';
            S2 <= "00"; 
            EN_x <= '0';
            EN_m <= '0';
            EN_in_m <= '1';
            EN_r <= '0';
            EN_prod <= '0';
            RST_prod <= '0';
            msgout_valid <= '0';
            load_counter <= '0'; 
            dec_count <= '0';
            E_load <= '0';
            E_shift <= '0';
            is_idle <= '1';
            
            if (msgin_valid = '1') then
                next_state <= ONE;
            else
                next_state <= IDLE;
            end if;
            
        when ONE =>
            S0 <= '1'; 
            S1 <= '1';
            S2 <= "01";
            EN_x <= '1';
            EN_in_m <= '0';
            RST_prod <= '1';
            EN_prod <= '1';
            load_counter <= '1'; 
            E_load <= '1';
            is_idle <= '0';
            
            next_state <= ONE_A;
            
        when ONE_A =>
            S1 <= '1';
            S2 <= "01";
            EN_x <= '0';
            EN_m <= '1';
            EN_prod <= '0';
            load_counter <= '0';
            E_load <= '0'; 
            
            if (prod_valid = '1') then
                next_state <= TWO;
            else
                next_state <= ONE_A;
            end if;
            
        when TWO =>
            EN_m <= '0';
            RST_prod <= '0';
            next_state <= THREE;
            
        when THREE =>
            S1 <= '0';
            S2 <= "00";
            EN_x <= '0';
            EN_m <= '0';
            RST_prod <= '1';
            EN_prod <= '1';
            dec_count <= '1';
            E_shift <= '0';
           
            next_state <= THREE_A;
            
        when THREE_A =>
            S1 <= '0';
            S2 <= "00";
            EN_x <= '1';
            EN_prod <= '0';
            dec_count <= '0';
            
            if (prod_valid = '1') and (E_msb = '1') then 
                next_state <= THREE_A_2;
            elsif (prod_valid = '1') and (E_msb = '0') then 
                next_state <= THREE_D;
            else
                next_state <= THREE_A;
            end if;
            
        when THREE_A_2 =>
            EN_x <= '0';
            RST_prod <= '0';
            
            next_state <= THREE_B;
            
        when THREE_B =>
            S0 <= '0'; 
            S1 <= '0';
            S2 <= "10";
            RST_prod <= '1';
            EN_prod <= '1';
    
            next_state <= THREE_C;
            
        when THREE_C =>
            S1 <= '0';
            S2 <= "10";
            EN_x <= '1';
            EN_prod <= '0';
            
            if (prod_valid = '1') then
                next_state <= THREE_D;
            else
                next_state <= THREE_C;
            end if;
            
        when THREE_D =>
            S0 <= '0';  
            EN_x <= '0';
            E_shift <= '1';
            RST_prod <= '0';
    
            if (count_overflow = '1') then --if counter < 0 next_state = FOUR
                next_state <= FOUR;
            else --if counter >=0 next_state = THREE
                next_state <= THREE;
            end if;
            
        when FOUR =>
            S1 <= '0';
            S2 <= "11";
            EN_x <= '0';
            RST_prod <= '1';
            EN_prod <= '1';
            load_counter <= '1'; 
            E_shift <= '0';
            
            next_state <= FIVE;
            
        when FIVE =>
            S1 <= '0';
            S2 <= "11";
            EN_r <= '1';
            EN_prod <= '0';
            load_counter <= '0'; 
            
            if (prod_valid = '1') then
                next_state <= SIX;
            else 
                next_state <= FIVE;
            end if;
            
        when SIX =>
            EN_r <= '0';
            RST_prod <= '0';
            msgout_valid <= '1';
            
            if (msgout_ready = '1') then
                next_state <= IDLE;
            else 
                next_state <= SIX;
            end if;   
                 
        when others => 
            next_state <= IDLE;
        end case;
    end process Comb_proc;
    
end Behavioral;
