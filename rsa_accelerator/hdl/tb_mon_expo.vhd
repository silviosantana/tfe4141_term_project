library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity rsa_modexp_tb is
generic (
          C_BLOCK_SIZE          : integer := 256
          );
end;

architecture bench of rsa_modexp_tb is

  component rsa_modexp
      generic (
          C_BLOCK_SIZE          : integer := 256
          );
      port (
          clk                    :  in std_logic;
          reset_n                :  in std_logic;
          msgin_valid            : in std_logic;
          msgin_data             :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          is_idle                : out std_logic;
          msgout_ready           : in std_logic;
          msgout_valid            : out std_logic;
          msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          r_mod_n                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          r2_mod_n                :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          rsa_status              : out std_logic_vector(31 downto 0)
      );
  end component;

  signal clk: std_logic;
  signal reset_n: std_logic;
  signal msgin_valid: std_logic;
  signal msgin_data: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal is_idle: std_logic;
  signal msgout_ready: std_logic;
  signal msgout_valid: std_logic;
  signal msgout_data: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal key_e_d: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal key_n: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal r_mod_n: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal r2_mod_n: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal rsa_status: std_logic_vector(31 downto 0) ;

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  -- Insert values for generic parameters !!
  uut: rsa_modexp generic map ( C_BLOCK_SIZE =>  C_BLOCK_SIZE)
                     port map ( clk          => clk,
                                reset_n      => reset_n,
                                msgin_valid  => msgin_valid,
                                msgin_data   => msgin_data,
                                is_idle       => is_idle,
                                msgout_valid => msgout_valid,
                                msgout_ready  => msgout_ready,
                                msgout_data  => msgout_data,
                                key_e_d      => key_e_d,
                                key_n        => key_n,
                                r_mod_n      => r_mod_n,
                                r2_mod_n     => r2_mod_n,
                                rsa_status   => rsa_status );

  stimulus: process
  begin
  
    -- Put initialisation code here
    msgin_data  <=  std_logic_vector(to_unsigned(7, 256));
    key_e_d     <=  std_logic_vector(to_unsigned(10, 256));
    key_n       <=  std_logic_vector(to_unsigned(13, 256));
    r_mod_n     <=  std_logic_vector(to_unsigned(3, 256));
    r2_mod_n    <=  std_logic_vector(to_unsigned(9, 256));
    msgin_valid  <= '0';
    msgout_ready  <= '0';
    reset_n <= '1';
    wait for 3*clock_period;
    
    reset_n <= '0';
    wait for clock_period;
    reset_n <= '1';
    wait for clock_period;
    

    wait for clock_period;
    msgin_valid  <= '1';
    
    wait for 2*clock_period;
    msgin_valid  <= '0';
    
    wait for 500*clock_period;
    msgout_ready  <= '1';

    -- Put test bench stimulus code here

    --stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;