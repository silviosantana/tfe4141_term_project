----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/29/2018 09:00:05 AM
-- Design Name: 
-- Module Name: Montgomery_product - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reg is

    generic (
            reg_width:  integer :=256
            );
    
    Port (  
            input:                                    		in std_logic_vector (reg_width-1 downto 0);
            clk, reg_en, reset_n, reg_shift:		        in std_logic;
            output:                                   		out std_logic_vector (255 downto 0);
            outLSB:                                   		out std_logic
            );
end reg;

architecture Behavioral of reg is

    signal reg_value:    std_logic_vector (reg_width-1 downto 0);

begin
    process(clk, reset_n)
    begin
        if (reset_n = '0') then
            reg_value <= (others => '0');
        elsif rising_edge(clk) then
            if reg_en = '1' then
                reg_value <= input;
            elsif reg_shift = '1' then
                reg_value <= std_logic_vector(shift_right(unsigned(reg_value), 1));
            end if;
        end if;
    end process;
    output <= reg_value(255 downto 0);
    outLSB <= reg_value(0);    
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Montgomery_product is
  Port (    
            clk:            in std_logic;
            reset_n:        in std_logic;
            A:              in std_logic_vector (255 downto 0);
            B:              in std_logic_vector (255 downto 0);
            n:              in std_logic_vector (255 downto 0);
            P:              out std_logic_vector (255 downto 0);
            A_sreg_en:      in std_logic;
            B_reg_en:       in std_logic;
            U_sreg_en:      in std_logic;
            P_reg_en:       in std_logic;
			n_reg_en:		in std_logic;
            A_sreg_shift:   in std_logic;
            U_sreg_shift:   in std_logic;
            adder_en:       in std_logic
            );
end Montgomery_product;

architecture Behavioral of Montgomery_product is

    component reg
        generic (
            reg_width:  integer :=256
            );
        port (  
            input:                                    in std_logic_vector (reg_width-1 downto 0);
            clk, reg_en, reset_n, reg_shift:        in std_logic;
            output:                                   out std_logic_vector (255 downto 0);
            outLSB:                                   out std_logic
            );
    end component;

    signal A_LSB:   std_logic;
    signal B_LSB:   std_logic;
    signal U_LSB:   std_logic;
	signal P_LSB:	std_logic;
	signal n_LSB:	std_logic;
    signal add_n:   std_logic;
    signal n_mux:   std_logic_vector (255 downto 0);
    signal B_mux:   std_logic_vector (255 downto 0);
    signal A_out:   std_logic_vector (255 downto 0);
    signal B_out:   std_logic_vector (255 downto 0);
    signal U_out:   std_logic_vector (255 downto 0);
	signal n_out:	std_logic_vector (255 downto 0);
    signal sum:     std_logic_vector (256 downto 0);

begin

    A_sreg: reg
	
        port map(   input => A,
                    clk => clk,
                    reg_en => A_sreg_en,
                    reset_n => reset_n,
                    reg_shift => A_sreg_shift,
                    output => A_out,
                    outLSB => A_LSB); 
					
    B_reg: reg
	
        port map(   input => B,
                    clk => clk,
                    reg_en => B_reg_en,
                    reset_n => reset_n,
                    reg_shift => '0',
                    output => B_out,
                    outLSB => B_LSB);
					
    U_sreg: reg
	
		generic map(
					reg_width => 257)
					
        port map(   input => sum,
                    clk => clk,
                    reg_en => U_sreg_en,
                    reset_n => reset_n,
                    reg_shift => U_sreg_shift,
                    output => U_out,
                    outLSB => U_LSB);
					
    P_reg: reg
    
        port map(   input => U_out,
                    clk => clk,
                    reg_en => P_reg_en,
                    reset_n => reset_n,
                    reg_shift => '0',
                    output => P,
                    outLSB => P_LSB); 					
					
	n_reg: reg
		port map(	input => n,
                    clk => clk,
                    reg_en => n_reg_en,
                    reset_n => reset_n,
                    reg_shift => '0',
                    output => n_out,
                    outLSB => n_LSB); 
					
	process(A_LSB, B_out)
	begin
		if A_LSB = '1' then
			B_mux <= B_out;
		else
			B_mux <= (others => '0');
		end if;
	end process;
	
	
	add_n <= U_LSB xor B_mux(0);
	
	process(add_n, n_out)
	begin
		if add_n = '1' then
			n_mux <= n_out;
		else
			n_mux <= (others => '0');
		end if;
	end process;
	
	process(adder_en, U_out, B_mux, n_mux)
	begin
		if adder_en = '1' then
			sum <= std_logic_vector(resize(unsigned(U_out), 257) + resize(unsigned(B_mux), 257) + resize(unsigned(n_mux), 257));
		else
			sum <= (others => '0');
		end if;
	end process;

end Behavioral;
