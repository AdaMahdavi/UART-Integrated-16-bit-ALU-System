
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity topModule is

 generic (
    clkFrequency : integer := 100_000_000;
    baudrate      : integer := 19200;
    depth     : integer := 128
  );
    port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    ready   : in  std_logic;                         
    opcode  : in  std_logic_vector(1 downto 0);
    data1   : in  std_logic_vector(7 downto 0);
    data2   : in  std_logic_vector(7 downto 0);
    dataOut : out std_logic_vector(15 downto 0)	

  );
  end entity;
  
architecture Behavioral of topModule is
-----------components---------------

----------component Transmitter
component Transmitter
    generic (
      clkFrequency : integer := 100_000_000;
      baudrate     : integer := 19200
    );
    port (
      opCode : in  std_logic_vector(1 downto 0);
      data1  : in  std_logic_vector(7 downto 0);
      data2  : in  std_logic_vector(7 downto 0);
      ready  : in  std_logic;
      clk    : in  std_logic;
      reset  : in  std_logic;
      tx     : out std_logic
    );
  end component;
  
----------component receiver/Alu
component ReceiverALU
    generic (
      clkFrequency : integer := 100_000_000;
      baudrate     : integer := 19200
    );
    port (
      clk       : in  std_logic;
      reset     : in  std_logic;
      rx        : in  std_logic;                       
      outAlu  : out std_logic_vector(15 downto 0);   
      readyRam : out std_logic                        
    );
  end component;
----------component write_only RAM
  component WO_Ram
    generic (
      depth : integer := 128
    );
    port (
      clk       : in  std_logic;
      reset     : in  std_logic;
      readyRam        : in  std_logic;  
      inData      : in  std_logic_vector(15 downto 0);
		recentData : out std_logic_vector(15 downto 0)		
  
    );
  end component;
  
  signal tx_rx     : std_logic;                        
  signal outAlu_s : std_logic_vector(15 downto 0);
  signal readyRam_s : std_logic;
  
  
  


  
  begin
  -------transmitter---------
    U_TX : Transmitter
    generic map (
      clkFrequency => clkFrequency,
      baudrate     => baudrate
    )
    port map (
      opcode => opcode,
      data1  => data1,
      data2  => data2,
      ready  => ready,
      clk    => clk,
      reset  => reset,
      tx     => tx_rx
    );



--------receiver-----------

    U_RX : ReceiverALU
    generic map (
      clkFrequency => clkFrequency,
      baudrate     => baudrate
    )
    port map (
      clk       => clk,
      reset     => reset,
      rx        => tx_rx,
      outAlu   => outAlu_s,
      readyRam => readyRam_s
    );

----------ram------------

    U_RAM : WO_RAM
    generic map (
      depth => depth
    )

    port map (
      clk   => clk,
      reset => reset,
      readyRam    => readyRam_s,     
      inData   => outAlu_s,
		recentData => dataOut
    );

-----------topProcess-----------
--
--    process(clk)
--    begin
--	    if rising_edge(clk) then
--            if reset = '1' then
--            dataOutReg <= (others => '0');
--             
--             elsif readyRam_s = '1' then
--                 dataOutReg <= outAlu_s;  
--             end if;
--        end if;
--
--  
--  end process;
--  		  `
--  debugOut <= ramProbe; 
--  dataOut <= dataOutReg;

end Behavioral;

