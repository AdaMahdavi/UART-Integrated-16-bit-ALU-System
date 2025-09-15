library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Transmitter is
    generic ( 
	        clkFrequency : integer := 100_000_000;
			  baudrate : integer := 19200
	        );
    Port ( opcode : in  STD_LOGIC_VECTOR (1 downto 0);
           data1 : in  STD_LOGIC_VECTOR (7 downto 0);
           data2 : in  STD_LOGIC_VECTOR (7 downto 0);
           ready : in  STD_LOGIC;
			  clk : in STD_LOGIC;
			  reset : in STD_LOGIC;
			  tx : out STD_LOGIC
			  );
end Transmitter;

architecture Behavioral of Transmitter is
    type status is( idle, startData, sendData, stopData );
	 
	 constant dataRate : integer := clkFrequency / baudrate; 
	 
	 signal state : status := idle;
	 signal shiftReg : STD_LOGIC_VECTOR(17 downto 0) := (others => '0'); 
	 signal bitIndx : integer range 0 to 17 := 0;
	 signal clkCount : integer range 0 to (dataRate - 1) := 0; 
	 signal baudCount : integer range 0 to 19 := 0;
	 
	 signal txBit : STD_LOGIC := '1';
	 
begin
    
	 tx <= txBit; 
	 
	 readnTransmit: process (clk, reset)
	 
	       variable currentState : status;
	       variable currentBit : std_logic;
	       variable currentIndx: integer range 0 to 17;
			 variable currentClkCount : integer range 0 to (dataRate - 1);
	       variable baudReady  : boolean;
			 variable currentBaudCount : integer range 0 to 19;
	 
    begin
	 
	 
	        
	     if reset = '1' then
		      state <= idle;
		      shiftReg <= (others => '0');
		      txBit <= '1';
		      bitIndx <= 0;
		      clkCount <= 0;
				
	     elsif rising_edge(clk) then 
		  
		       baudReady := false;
		       currentState := state;
				 currentIndx := bitIndx;
				 currentBit := txBit;
				 currentBaudCount := baudCount;
				 currentClkCount := clkCount;

	 
		      if state = idle then
				
                if ready = '1' then
                    shiftReg <= data1 & data2 & opcode; 
                    currentBit := '1';         
                    currentClkCount := 0;           
                    currentIndx := 0;
						  currentBaudCount := 0;
                    currentState := startData;   
                else
                   currentBit := '1';            
                end if;
					 
				else
				     currentClkCount := currentClkCount + 1;
				     if currentClkCount = dataRate - 1 then
				        baudReady := true; 
			           currentClkCount := 0; 
				     end if;
				 
				     if baudReady then 
				         currentBaudCount := currentBaudCount + 1;
				         case currentState is
					  
					      when startData => currentBit := '0'; currentState:= sendData;
				 
				 
				         when sendData => currentBit := shiftReg(currentIndx);
					                       if currentIndx = 17 then currentState := stopData;
											     else currentIndx := currentIndx + 1;
											     end if;
											 
					      when stopData => currentBit := '1';
					                       if currentBaudCount = 20 then 
												  currentBaudCount := 0;
											     currentState := idle;
											     end if;
												 
					      when others => currentState := idle;
					  
				         end case;
					    
				      end if;
				  end if;
				  state <= currentState;
				  bitIndx <= currentIndx;
				  txBit <= currentBit;
				  baudCount <= currentBaudCount;
				  clkCount <= currentClkCount;
			end if;
    end process readnTransmit;
	  
		  

end Behavioral;

