library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity core_tbfkin2 is
--  Port ( );
end core_tbfkin2;

architecture Behavioral of core_tbfkin2 is


component rsa_core is
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
    r_mod_n             :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    r2_mod_n            :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    rsa_status              : out std_logic_vector(31 downto 0)    
          
  );
end component;

constant C_BLOCK_SIZE : integer := 256;
signal clk, msgin_ready,msgout_valid, msgout_ready, msgout_last : std_logic;
signal  msgout_data, key_e_d, key_n, key_r_mod_n, key_rr_mod_n : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal rsa_status : std_logic_vector(31 downto 0);
signal msgin_valid : std_logic := '1';
signal message_count  : integer range 0 to 10   :=0;
signal msgin_data : std_logic_vector(C_BLOCK_SIZE-1 downto 0) := x"13d36c9d473d7e79521ee7962710f7ad16a61dc0b47454ca222484bb4995bbac";
signal msgin_last : std_logic := '0';
signal reset_n : std_logic := '1';
begin

u_rsa_core : entity work.rsa_core
  generic map (
    C_BLOCK_SIZE => C_BLOCK_SIZE  
  )
  port map (
    -----------------------------------------------------------------------------
    -- Clocks and reset
    -----------------------------------------------------------------------------      
    clk                    => clk,
    reset_n                => reset_n,
    
    -----------------------------------------------------------------------------
    -- Slave msgin interface
    -----------------------------------------------------------------------------
    msgin_valid            => msgin_valid,   
    msgin_ready            => msgin_ready,
    msgin_data             => msgin_data,
    msgin_last             => msgin_last,
  
    -----------------------------------------------------------------------------
    -- Master msgout interface
    -----------------------------------------------------------------------------
    msgout_valid           => msgout_valid,   
    msgout_ready           => msgout_ready,
    msgout_data            => msgout_data,
    msgout_last            => msgout_last,

    -----------------------------------------------------------------------------
    -- Interface to the register block
    -----------------------------------------------------------------------------    
    key_e_d                => key_e_d,
    key_n                  => key_n,
    r_mod_n            => key_r_mod_n,
    r2_mod_n           => key_rr_mod_n,
    rsa_status             => rsa_status    
  
  );
  
process
    begin
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    end process;
    
    process(clk)
    begin
        if clk'event and clk = '1' then
            if(msgin_ready = '1') then
                if(message_count = 0) then
                   msgin_data <=   x"7bf4d072768bbfa27c8d09ca9d24052cd7511498f3e37efe7b7f7c7f7647bf2c";
                elsif(message_count = 1) then
                   msgin_data <=   x"38294e778cd67832d07278c437713328feb994725af0125d26c66712b48287d4";
                elsif(message_count = 2) then
                     msgin_data <=   x"7c0520b41ca8b3ff26e77716f40c0503e74699f48cc0dc6f796eaadfb23409ab";
              elsif(message_count = 3) then
                   msgin_data <=   x"2e8360061e33ba6b3dd3bfbee7eb55ab14b156f1ef082fdd6456d3779d3ad000";
            elsif(message_count = 4) then
                 msgin_data <=   x"8995a9ba4e47ad8c71ddd6e23ba6ca63a3617a46ee6361d030ef76469cd4e15a";
                  elsif(message_count = 5) then
                       msgin_data <=   x"741ea8226934c182bff038c6f5b52b892ee76eeefe26f01333ab13b6492e8dce";
                elsif(message_count = 6) then
                  msgin_data <=   x"98a972e01e876628b259c57b3217bc25d807e185700abe4fec5fa335679ab618";
           elsif(message_count = 7) then
                msgin_data <=   x"1c6a9b8ec4485bd5a460e171a1f6723680599cfb58315b9c8ce213b0a81ef034";
                 elsif(message_count = 8) then
                      msgin_data <=   x"1c6a9b8ec4485bd5a460e171a1f6723680599cfb58315b9c8ce213b0a81ef034";
                elsif(message_count = 9) then
                    msgin_data <=   x"85ee722363960779206a2b37cc8b64b5fc12a934473fa0204bbaaf714bc90c01";
                    msgin_last <= '1';
                elsif(message_count = 10)then
                    msgin_valid <= '0';
                end if;
                 message_count <= message_count+1;
            end if;
           
            if(msgout_valid = '1') then
                msgout_ready <= '1'; 
            else
                msgout_ready <= '0';
            end if;
        end if;
    end process;


    reset_n <= '1';
    key_e_d <=      x"0cea1651ef44be1f1f1476b7539bed10d73e3aac782bd9999a1e5a790932bfe9";
    key_n <=        x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d";
    key_r_mod_n <=  x"33490ba4f7cfc6cac056e407fd9887c9f8650aae02ca35681a4d7c9b15019c59";
    key_rr_mod_n <= x"28533fe966bbe428c8d5187911ac3654b520199625a72ddad5a8c7829102a076";
    
    
end Behavioral;
