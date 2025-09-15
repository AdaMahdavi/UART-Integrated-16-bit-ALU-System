
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity receiverAlu is
    generic ( 
	        clkFrequency : integer := 100_000_000;
			  baudrate : integer := 19200
	        );
    Port ( rx : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           outAlu : out  STD_LOGIC_VECTOR (15 downto 0);
           readyRam : out  STD_LOGIC);
end receiverAlu;

architecture Behavioral of receiverAlu is 
     type status is( idle, startBit, receiving, stopBit, arithmetic);

    constant dataRate : integer := clkFrequency / baudrate; 
	 signal bitIndx : integer range 0 to 17 := 0;
	 signal clkCount : integer range 0 to dataRate-1 := 0;
	 
	 signal state : status := idle;
	 
	 
	 signal shiftReg : STD_LOGIC_VECTOR (17 downto 0) :=(others => '0');
	 
	 signal rx_t1, rx_t2 : std_logic := '1';
	 
	 

begin 



    reciveralu: process (clk)
	 
        variable op : std_logic_vector(1 downto 0);
		  variable d1_t : std_logic_vector(15 downto 0);
	     variable  d2_t : std_logic_vector(15 downto 0);
		  variable res : std_logic_vector(15 downto 0);
					
						 
    begin
		  
	     if rising_edge(clk) then
		      readyRam <= '0';
		  
		      if reset = '1' then
				    state <= idle;
				    bitIndx <= 0;
				    clkCount <= 0;
					 shiftReg <= (others => '0');
		          outAlu <= (others => '0');
					 readyRam <= '0';
				    
					 rx_t1 <= '1';
					 rx_t2 <= '1';
					 
				else
					 rx_t1 <= rx;
		          rx_t2 <= rx_t1;
            
				case state is
				
				    when idle =>
					     clkCount <= 0;
						  bitIndx <= 0;
						  
					     if rx_t2 = '0' then
						      state <= startBit;
						  end if;
						  
					 when startBit =>
					     if clkCount = dataRate/2 then
						      clkCount <= 0;
						      if rx_t2 = '0' then
								    state <= receiving;
								else 
								    state <= idle; --glitch detected
								end if;
						  else
						  clkCount <= clkCount+1;
						  end if;
					 
					 
					 when receiving =>
					  if clkCount = dataRate-1 then
						      clkCount <= 0;
						      shiftReg <= rx_t2 & shiftReg(17 downto 1); --imortant note on this bit
								
								 if bitIndx = 17 then 
								     bitIndx <= 0;
									  state <= stopBit;
									  
								 else
								     bitIndx <= bitIndx+1;
									  
								 end if;
								 
						  else
						  clkCount <= clkCount+1;
						  end if;
					 
					 when stopBit =>
					     if clkCount = dataRate-1 then
						      clkCount <= 0;
						      if rx_t2 = '1' then
								    state <= arithmetic;
								else 
								    state <= idle; --glitch detected
								end if;
						  else
						  clkCount <= clkCount+1;
						  end if;
					 

					 when arithmetic =>
					 
					     op := shiftReg(1 downto 0);
					     d2_t := (others => '0');
					     d2_t(7 downto 0) := shiftReg(9 downto 2);
					     d1_t := (others => '0');
					     d1_t(7 downto 0) := shiftReg(17 downto 10);
					     res := (others => '0');
					 
					 
					     case op is 
					         when "00" => 
						          res := d1_t(7 downto 0) & d2_t( 7 downto 0);
						      when "01" =>
						          res := std_logic_vector (unsigned(d1_t) and unsigned(d2_t)); 
						      when "11" =>
						          res(7 downto 0) := not (std_logic_vector (unsigned(d1_t(7 downto 0)) xor unsigned(d2_t(7 downto 0)))); res(15 downto 8) := (others => '0');
						      when others =>
						          res := std_logic_vector (unsigned(d1_t) xor unsigned(d2_t));
					     end case;
						  
					 
					     outAlu <= res;
					     readyRam <= '1'; 
					     state <= idle;
						  
					 when others => null;
					 
	
				
				end case;
				
				end if;
				
				
		  end if;
				
    end process;


       
end Behavioral;

