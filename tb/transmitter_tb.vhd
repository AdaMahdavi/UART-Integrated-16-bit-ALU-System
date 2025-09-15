
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

ENTITY transmittest IS
END transmittest;
 
	ARCHITECTURE behavior OF transmittest IS 

 
    COMPONENT Transmitter
	 GENERIC (
	      clkFrequency : integer := 100_000_000;
         baudrate : integer := 19200
	 );
    PORT(
         opcode : IN  std_logic_vector(1 downto 0);
         data1 : IN  std_logic_vector(7 downto 0);
         data2 : IN  std_logic_vector(7 downto 0);
         ready : IN  std_logic;
         clk : IN  std_logic;
         reset : IN  std_logic;
         tx : OUT  std_logic
        );
    END COMPONENT;
	 
					 
    
   signal opcode : std_logic_vector(1 downto 0) := (others => '0');
   signal data1 : std_logic_vector(7 downto 0) := (others => '0');
   signal data2 : std_logic_vector(7 downto 0) := (others => '0');
   signal ready : std_logic := '0';
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal tx : std_logic;
	
	-----------------
	
	constant clkFreq : integer := 100_000_000;
	constant baudR : integer := 19200; 
	constant clkPeriod: time    := 10 ns;  
   constant dataRate : integer := clkFreq / baudR;
	constant frameBits : integer := 20;
	procedure wait_clocks(n : in integer) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;
  
  function to_bstring(slv : std_logic_vector) return string is
        variable s : string(1 to slv'length);
        begin
            for i in slv'range loop
                 if slv(i) = '1' then
                      s(slv'length - i) := '1';  
                 else
                      s(slv'length - i) := '0';
                 end if;
            end loop;
        return s;
    end;
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Transmitter 
	generic map ( 
	              clkFrequency => clkFreq,
	              baudrate => baudR
                )	
	
	
	PORT MAP (
          opcode => opcode,
          data1 => data1,
          data2 => data2,
          ready => ready,
          clk => clk,
          reset => reset,
          tx => tx
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clkPeriod/2;
		clk <= '1';
		wait for clkPeriod/2;
   end process;
 

   stim_proc: process
	
	   variable seed1, seed2 : positive := 1357;  
      variable rand_real    : real;
      
		variable rand_int1     : integer;
		variable rand_int2     : integer;
		variable rand_int3     : integer;
		
   begin		
      
		reset <= '1';
      wait for 100 ns;	
      reset <= '0';
      wait_clocks(5);


for frame in 1 to 20 loop


      -- random opcode (0-3)
        uniform(seed1, seed2, rand_real);
        rand_int1 := integer(rand_real * 4.5); 
       wait until rising_edge(clk);
	
		-- random data1 (0-255)
       uniform(seed1, seed2, rand_real);
      rand_int2 := integer(rand_real * 256.5);
	
		-- random data2 (0-255)
       uniform(seed1, seed2, rand_real);
       rand_int3 := integer(rand_real * 256.0);
		
------			
        wait until rising_edge(clk);
------         
       opcode <= std_logic_vector(to_unsigned(rand_int1, 2));
       data1 <= std_logic_vector(to_unsigned(rand_int2, 8));
       data2 <= std_logic_vector(to_unsigned(rand_int3, 8));
------
        -- pulse ready
       wait until rising_edge(clk);
       ready <= '1';
      wait until rising_edge(clk);
     ready <= '0';
------         
------			
			wait_clocks(frameBits * dataRate * 5);
------			
       report "Frame " & integer'image(frame) &
       " done. opcode=" & to_bstring(opcode) &
       " data1=" & to_bstring(data1) &
       " data2=" & to_bstring(data2)
       severity note;
------
         -- spacing between frames
        wait_clocks(frameBits * dataRate * 3);
------
     end loop;
----
    wait;
   end process;

END;
