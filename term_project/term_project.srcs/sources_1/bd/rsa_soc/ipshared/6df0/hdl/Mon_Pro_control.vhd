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

entity MonPro_control_path is

    port (
            clk:            in std_logic;
            Mon_Pro_en:     in std_logic;
            reset_n:        in std_logic;
            rst_prod:       in std_logic;
            A_sreg_en:      out std_logic;
            B_reg_en:       out std_logic;
            U_sreg_en:      out std_logic;
            P_reg_en:       out std_logic;
			n_reg_en:		out std_logic;
            A_sreg_shift:   out std_logic;
            U_sreg_shift:   out std_logic;
            adder_en:       out std_logic;
			pro_valid:		out std_logic
        );
		
end MonPro_control_path;

architecture Behavioral of MonPro_control_path is

    type state is (IDLE, ONE, TWO, THREE, FOUR, FIVE);
    --signal curr_state:                              state;
    signal next_state: 					state;
    signal curr_state: state := IDLE;
	--signal counter: 								std_logic_vector(8 downto 0);
	signal counter: std_logic_vector(8 downto 0) := (others => '0');
	signal count:		std_logic;
	--signal count_overflow:		std_logic;
	signal count_overflow: std_logic := '0';

begin

	process (reset_n, clk)
    begin
        if (reset_n = '0') then
            curr_state <= IDLE;
        elsif rising_edge(clk) then
            curr_state <= next_state;
        end if;
    end process;
	
	process (count, rst_prod)
    begin
        if rst_prod = '0' then
            --exp_iteration_cnt <= (others => '0');
            counter <= (others => '0');
            count_overflow <= '0';
		elsif (count = '1') then
			if unsigned(counter) /= 255 then
				counter <= std_logic_vector(unsigned(counter) + 1);
				count_overflow <= '0';
			elsif unsigned (counter) = 255 then
				count_overflow <= '1';
				counter <= (others => '0');
			end if;
		end if;
	end process;

	
	process (Mon_Pro_en, count_overflow, curr_state, rst_prod)
	begin
		A_sreg_en    <= '0';
		B_reg_en     <= '0';
		U_sreg_en    <= '0';
		P_reg_en     <= '0';
		n_reg_en	 <= '0';
		A_sreg_shift <= '0';
		U_sreg_shift <= '0';
		adder_en     <= '0';
		pro_valid	 <= '0';
		count        <= '0';
		
		case (curr_state) is
		when IDLE =>
			A_sreg_en    <= '0';
			B_reg_en     <= '0';
			U_sreg_en    <= '0';
			P_reg_en     <= '0';
			n_reg_en	 <= '0';
			A_sreg_shift <= '0';
			U_sreg_shift <= '0';
			adder_en     <= '0';
			pro_valid	 <= '0';
			
			if Mon_Pro_en = '1' then
				next_state <= ONE;
			else
				next_state <= IDLE;
			end if;
			
		when ONE =>
            A_sreg_en    <= '1';
            B_reg_en     <= '1';
            U_sreg_en    <= '1';
            P_reg_en     <= '0';
            n_reg_en     <= '1';
            
            next_state <= TWO;
			
		when TWO =>
			A_sreg_en    <= '0';
			B_reg_en     <= '0';
			U_sreg_en    <= '1';
			P_reg_en     <= '0';
			n_reg_en	 <= '0';
			A_sreg_shift <= '0';
			U_sreg_shift <= '0';
			adder_en     <= '1';
			pro_valid	 <= '0';
			
			count <= '0';
			next_state <= THREE;
			
		when THREE =>
			A_sreg_en    <= '0';
			B_reg_en     <= '0';
			U_sreg_en    <= '0';
			P_reg_en     <= '0';
			n_reg_en	 <= '0';
			A_sreg_shift <= '1';
			U_sreg_shift <= '1';
			adder_en     <= '0';
			pro_valid	 <= '0';
			
			if count_overflow = '0' then
				count <= '1';
				next_state <= TWO;
			else
				next_state <= FOUR;
			end if;
		
		when FOUR =>
			A_sreg_en    <= '0';
			B_reg_en     <= '0';
			U_sreg_en    <= '0';
			P_reg_en     <= '1';
			n_reg_en	 <= '0';
			A_sreg_shift <= '0';
			U_sreg_shift <= '0';
			adder_en     <= '0';
			pro_valid	 <= '0';
			
			next_state <= FIVE;
			
		when FIVE =>
            A_sreg_en    <= '0';
            B_reg_en     <= '0';
            U_sreg_en    <= '0';
            P_reg_en     <= '1';
            n_reg_en     <= '0';
            A_sreg_shift <= '0';
            U_sreg_shift <= '0';
            adder_en     <= '0';
            pro_valid    <= '1';
            
            if (rst_prod = '1') then
                next_state <= IDLE;
            else
                next_state <= FIVE;
            end if;
               
		end case;
	end process;
end Behavioral;
		
		
			