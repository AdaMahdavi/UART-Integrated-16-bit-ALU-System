
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity WO_Ram is
    generic(
        dataWidth : integer := 16;
        addLen : integer := 7;
        depth : integer := 128
    );
    port (
        inData : in  std_logic_vector(dataWidth-1 downto 0);
        readyRam : in  std_logic;
        clk : in  std_logic;
        reset : in  std_logic;
        recentData : out std_logic_vector(dataWidth-1 downto 0)
    );
end WO_Ram;

architecture Behavioral of WO_Ram is
    subtype word_t is std_logic_vector(dataWidth-1 downto 0);
    subtype addressType is unsigned(addLen-1 downto 0);
	  
    type ramType is array (0 to depth-1) of word_t;

    constant ZERO_WORD : word_t      := (others => '0');
    constant ZERO_ADDR : addressType := (others => '0');

    signal address : addressType := (others => '0');
 	 
    signal ram : ramType;                            
    signal recentData_t : word_t := (others => '0');
	 signal address_t : addressType := (others => '0');
    type status is (running, clearing);
    signal state : status := running;

                  

    begin
        ramWrite: process(clk) 
	     begin
            if rising_edge(clk) then
                 if reset = '1' then
                    state <= clearing;
		  
                 else
                     case state is
                     when running =>
                         if readyRam = '1' then
                             ram(to_integer(address)) <= inData;
									  recentData_t <= inData;
									  address_t <= address;
                             if address /= to_unsigned(depth-1, address'length) then
                                 address <= address + 1;
                             end if;
									  else
									      recentData_t <= ram(to_integer(address_t));


                         end if;
								 

                     when clearing =>
						
				                     for i in 0 to depth-1 loop
		                               ram(i) <= ZERO_WORD;
		                           end loop;  
                                 address <= ZERO_ADDR;
											recentData_t  <= ZERO_WORD; 
                                 state <= running;

                    end case;
	      
             end if;
		
    end if;
  end process;
  recentData <= recentData_t;
 
end Behavioral;
			

