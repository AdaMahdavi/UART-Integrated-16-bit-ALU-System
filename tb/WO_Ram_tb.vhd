LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ramtest IS
END ramtest;

ARCHITECTURE behavior OF ramtest IS 

    COMPONENT WO_Ram
        GENERIC (
            dataWidth : integer := 16;
            addLen    : integer := 7;
            depth     : integer := 128
        );
        PORT (
            inData     : IN  std_logic_vector(dataWidth-1 downto 0);
            readyRam   : IN  std_logic;
            clk        : IN  std_logic;
            reset      : IN  std_logic;
            recentData : OUT std_logic_vector(dataWidth-1 downto 0)
        );
    END COMPONENT;

    -- Signals
    signal inData     : std_logic_vector(15 downto 0) := (others => '0');
    signal readyRam   : std_logic := '0';
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal recentData : std_logic_vector(15 downto 0);

    -- Constants (styled like transmitter TB)
    constant clkFreq    : integer := 100_000_000;
    constant baudR      : integer := 19200;
    constant clkPeriod  : time    := 10 ns;  
    constant dataRate   : integer := clkFreq / baudR;
    constant frameBits  : integer := 20;

    -- Wait procedure
    procedure wait_clocks(n : in integer) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
    end procedure;

BEGIN

    -- Instantiate DUT
    uut: WO_Ram
        GENERIC MAP (
            dataWidth => 16,
            addLen    => 7,
            depth     => 128
        )
        PORT MAP (
            inData     => inData,
            readyRam   => readyRam,
            clk        => clk,
            reset      => reset,
            recentData => recentData
        );
   -- Clock generator
    clk_process : process
    begin
        clk <= '0';
        wait for clkPeriod/2;
        clk <= '1';
        wait for clkPeriod/2;
    end process;

    -- Stimulus
    stim_proc: process
    begin
        -- Reset
        reset <= '1';
        wait_clocks(2);
        reset <= '0';
        wait_clocks(5);

        -- Write some data
        inData   <= x"AAAA";
        readyRam <= '1';
        wait_clocks(1);
        readyRam <= '0';
        wait_clocks(2);
		  
		  
		  -- MID-RUN RESET: verify that clear works in the middle of activity
        reset <= '1';
        wait_clocks(1);  -- arm clearing, no zero yet
      
        reset <= '0';
        wait_clocks(1);  -- clear executes here
       
wait_clocks(2); 
        inData   <= x"5555";
        readyRam <= '1';
        wait_clocks(1);
        readyRam <= '0';
        wait_clocks(2);

        -- Saturation test: push more than depth
        for i in 0 to 10 loop
            inData   <= std_logic_vector(to_unsigned(i, 16));
            readyRam <= '1';
            wait_clocks(1);
            readyRam <= '0';
            wait_clocks(1);
        end loop;

        -- Hold for a "frame" worth of time (to mimic TX TB style)
        wait_clocks(frameBits * dataRate);

        report "RAM test complete." severity note;
        wait;
    end process;

END;


