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
          msgin_last             :  in std_logic;
          is_idle                : out std_logic;
          msgout_ready           : in std_logic;
          msgout_valid            : out std_logic;
          msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          msgout_last             : out std_logic;
          key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          r_mod_n                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
          r2_mod_n                :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
          );
  end component;

  signal clk: std_logic;
  signal reset_n: std_logic;
  signal msgin_valid: std_logic;
  signal msgin_last             :  std_logic;
  signal msgin_data: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal is_idle: std_logic;
  signal msgout_ready: std_logic;
  signal msgout_valid: std_logic;
  signal msgout_data: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
  signal msgout_last             : std_logic;
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
                                msgin_last  => msgin_last,
                                msgin_data   => msgin_data,
                                is_idle       => is_idle,
                                msgout_valid => msgout_valid,
                                msgout_ready  => msgout_ready,
                                msgout_data  => msgout_data,
                                msgout_last  => msgout_last,
                                key_e_d      => key_e_d,
                                key_n        => key_n,
                                r_mod_n      => r_mod_n,
                                r2_mod_n     => r2_mod_n );

  stimulus: process
  begin
  
    -- Put initialisation code here
    msgin_data  <=  x"0a23232323232323232323232323232323232323232323232323232323232323";
    key_e_d     <=  x"0000000000000000000000000000000000000000000000000000000000010001";
    key_n       <=  x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d";
    r_mod_n     <=  x"666dae8c529a9798eac7a157ff32d7edfd77038f56436722b36f298907008973";
    r2_mod_n    <=  x"56ddf8b43061ad3dbcd1757244d1a19e2e8c849dde4817e55bb29d1c20c06364";
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
    msgin_last <= '1';
    
    wait for 2*clock_period;
    msgin_valid  <= '0';
    msgin_last <= '0';
    
    wait for 1000*clock_period;
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