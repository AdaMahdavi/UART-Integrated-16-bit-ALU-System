LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY receiveralutest IS
END receiveralutest;

ARCHITECTURE behavior OF receiveralutest IS
  COMPONENT receiverAlu
    GENERIC (
      clkFrequency : integer := 100_000_000;
      baudrate     : integer := 19200
    );
    PORT (
      rx        : IN  std_logic;
      clk       : IN  std_logic;
      reset     : IN  std_logic;
      outAlu    : OUT std_logic_vector(15 downto 0);
      readyRam  : OUT std_logic
    );
  END COMPONENT;
  signal rx       : std_logic := '1';  -- idle high
  signal clk      : std_logic := '0';
  signal reset    : std_logic := '0';
  signal outAlu   : std_logic_vector(15 downto 0) := (others => '0');
  signal readyRam : std_logic := '0';
--  signal rr0: std_logic := '0';
--  signal rr1: std_logic := '0';
--  signal ready_edge : std_logic := '0';

  constant clkFreq   : integer := 100_000_000;
  constant baudR     : integer := 19200;
  constant clkPeriod : time    := 10 ns;
  constant dataRate  : integer := clkFreq / baudR;  -- clocks per bit
  constant frameBits : integer := 20;

  procedure wait_clocks(n : in integer) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;
  procedure send_frame(
    signal rx_t : out std_logic;
    constant op  : in std_logic_vector(1 downto 0);
    constant d1  : in std_logic_vector(7 downto 0);
    constant d2  : in std_logic_vector(7 downto 0)
  ) is
  begin
    
    rx_t <= '0';
    wait_clocks(dataRate);

    
    for i in 0 to 1 loop
      rx_t <= op(i);
      wait_clocks(dataRate);
    end loop;

    
    for i in 0 to 7 loop
      rx_t <= d2(i);
      wait_clocks(dataRate);
    end loop;
    for i in 0 to 7 loop
      rx_t <= d1(i);
      wait_clocks(dataRate);
    end loop;

    
    rx_t <= '1';
    wait_clocks(dataRate/2);
  end procedure;

BEGIN
  -- UUT
  uut : receiverAlu
    generic map (
      clkFrequency => clkFreq,
      baudrate     => baudR
    )
    port map (
      rx       => rx,
      clk      => clk,
      reset    => reset,
      outAlu   => outAlu,
      readyRam => readyRam
    );
	 
	 
	 
	 
  -- clock Procedure
  clk_process : process
  begin
    clk <= '0';
    wait for clkPeriod/2;
    clk <= '1';
    wait for clkPeriod/2;
  end process;
-------------chk prc
--process(clk)
--begin
--  if rising_edge(clk) then
--    rr1 <= rr0;
--    rr0 <= readyRam;
--    ready_edge <= rr0 and not rr1;  -- 1 clk on rising edge
--  end if;
--end process;
 
  stim_proc : process
  begin
      reset <= '1';
    wait_clocks(2);
    reset <= '0';
    wait_clocks(5);

    -- Frame A: AND
    send_frame(rx, "01", "10010101", "10101010");
    wait until readyRam = '1';
    report "Frame A received (AND)" severity note;
    wait_clocks(10);

    -- Frame B: XNOR
    send_frame(rx, "11", "01100000", "00001111");
    wait until readyRam = '1';
    report "Frame B received (XNOR)" severity note;
    wait_clocks(10);
	 
	 -- Frame B: CONC 
	 send_frame(rx, "00", "01110101", "10101010");
    wait until readyRam = '1';
    report "Frame A received (CONC)" severity note;
    wait_clocks(10);
	 
	 -- Frame D: XOR
	 send_frame(rx, "10", "10010101", "10101010");
    wait until readyRam = '1';
    report "Frame A received (XOR)" severity note;
    wait_clocks(10);




 
    -- Done
    wait_clocks(frameBits * 2);
    report "receiverAlu TB done." severity note;
    wait;
  end process;

END behavior;




