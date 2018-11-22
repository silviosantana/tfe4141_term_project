----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/05/2018 08:36:53 AM
-- Design Name: 
-- Module Name: dummy_monpro - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dummy_monpro is
    generic (
        -- Users to add parameters here
        C_BLOCK_SIZE          : integer := 256
    );
    
    Port ( 
        A             :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        B             :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        start_prod    :  in std_logic;
        clk           :  in std_logic;
        reset_n       :  in std_logic;
        
        out_xor       :  out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        valid_out     :  out std_logic
    );
end dummy_monpro;


architecture Behavioral of dummy_monpro is
    type state is (IDLE, ONE, TWO, THREE, FOUR, FIVE, SIX);
    signal curr_state, next_state: state;
begin
    Synch_state_proc: process (reset_n, clk)
    begin
        if (reset_n = '0') then
            curr_state <= IDLE;
        elsif rising_edge(clk) then
            curr_state <= next_state;
        end if;
    end process Synch_state_proc;
    
    Comb_proc: process (curr_state, A, B, start_prod)
        begin
            
            out_xor <= std_logic_vector(to_unsigned(0, C_BLOCK_SIZE)); 
            valid_out <= '0';
          
            case (curr_state) is
            when IDLE =>
                out_xor <= std_logic_vector(to_unsigned(0, C_BLOCK_SIZE)); 
                valid_out <= '0';
                
                if (start_prod = '1') then
                    next_state <= ONE;
                else
                    next_state <= IDLE;
                end if;
                
            when ONE =>
                next_state <= TWO;
                            
            when TWO =>               
                next_state <= THREE;
                
            when THREE =>
                next_state <= FOUR;
                
            when FOUR =>             
                next_state <= FIVE;
                
            when FIVE =>
                next_state <= SIX;
                
            when SIX =>
                out_xor <= A xor B; 
                valid_out <= '1';
                
                next_state <= IDLE;   
                     
            when others => 
                next_state <= IDLE;
            end case;
        end process Comb_proc;

end Behavioral;
