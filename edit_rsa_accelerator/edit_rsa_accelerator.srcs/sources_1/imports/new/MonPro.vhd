----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2018 04:37:14 PM
-- Design Name: 
-- Module Name: MonPro - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MonPro is
    port(
    clk:            in std_logic;
    A:              in std_logic_vector (255 downto 0);
    B:              in std_logic_vector (255 downto 0);
    n:              in std_logic_vector (255 downto 0);
    P:              out std_logic_vector (255 downto 0);
    Mon_Pro_en:     in std_logic;
    global_reset:   in std_logic;
    pro_valid:		out std_logic
    );
end MonPro;

architecture rtl of MonPro is

signal A_sreg_en:      std_logic;
signal B_reg_en:       std_logic;
signal U_sreg_en:      std_logic;
signal P_reg_en:       std_logic;
signal n_reg_en:	   std_logic;
signal A_sreg_reset:   std_logic;
signal B_reg_reset:    std_logic;
signal U_sreg_reset:   std_logic;
signal P_reg_reset:    std_logic;
signal n_reg_reset:	   std_logic;
signal A_sreg_shift:   std_logic;
signal U_sreg_shift:   std_logic;
signal adder_en:       std_logic;

begin

    MonPro_datapath:        entity work.Montgomery_Product port map(
        clk                 =>  clk,           
        A                   =>  A,
        B                   =>  B,
        n                   =>  n,
        P                   =>  P,
        A_sreg_en           =>  A_sreg_en,
        B_reg_en            =>  B_reg_en,
        U_sreg_en           =>  U_sreg_en,
        P_reg_en            =>  P_reg_en,
        n_reg_en            =>  n_reg_en,
        A_sreg_reset        =>  A_sreg_reset,
        B_reg_reset         =>  B_reg_reset,
        U_sreg_reset        =>  U_sreg_reset,
        P_reg_reset         =>  P_reg_reset,
        n_reg_reset         =>  n_reg_reset,
        A_sreg_shift        =>  A_sreg_shift,
        U_sreg_shift        =>  U_sreg_shift,
        adder_en            =>  adder_en
    );
    
    Mon_Pro_controlpath:    entity work.MonPro_control_path port map(
        clk                 =>  clk,
        Mon_Pro_en          =>  Mon_Pro_en,
        global_reset        =>  global_reset,
        A_sreg_en           =>  A_sreg_en,
        B_reg_en            =>  B_reg_en,
        U_sreg_en           =>  U_sreg_en,
        P_reg_en            =>  P_reg_en,
        n_reg_en            =>  n_reg_en,
        A_sreg_reset        =>  A_sreg_reset,
        B_reg_reset         =>  B_reg_reset,
        U_sreg_reset        =>  U_sreg_reset,
        P_reg_reset         =>  P_reg_reset,
        n_reg_reset         =>  n_reg_reset,
        A_sreg_shift        =>  A_sreg_shift,
        U_sreg_shift        =>  U_sreg_shift,
        adder_en            =>  adder_en,
        pro_valid           =>  pro_valid
        );

end rtl;
