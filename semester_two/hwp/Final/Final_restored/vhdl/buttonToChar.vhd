library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buttonToChar is port(
	clk_50 : in std_logic;
	blocked : in std_logic;
	analogIn : in std_logic_vector(11 downto 0);

	keyOut: out std_logic_vector(31 downto 0)
);
end buttonToChar;


architecture a of buttonToChar is

	type Statetype is (init, buttonPressed, increase, decrease, nextCharacter, check);
	signal State : Statetype := init;
	signal findkey : std_logic := '0';
	

	type arr is array (0 to 3) of unsigned(7 downto 0);
	signal chars : arr := (others => to_unsigned(97, 8));

	signal array_index : unsigned(1 downto 0) := "00";
	signal todo_lshift : unsigned (1 downto 0) := "00";
	signal counter : unsigned(12 downto 0);
	signal buttonIn : std_logic_vector(3 downto 0);

begin
	-- code for inserting the key through the buttons
	process (clk_50, blocked)
	begin
		if blocked = '1' then
			State <= init;
		elsif rising_edge(clk_50) then 

      		if findkey = '1' and State = check then
      			if array_index <= todo_lshift then
      				array_index <= array_index + 1;
      			elsif array_index = todo_lshift and todo_lshift /= "00" then
      				array_index <= "00";
      				todo_lshift <= "00";
      			end if;
      			
      			if counter > 2500 then
      				State <= increase;
      				counter <= (others => '0');
      			else
      				counter <= counter + 1;
      			end if;

			elsif State = init and (buttonIn(0) = '1' or buttonIn(1) = '1' or buttonIn(2) = '1') then
--			if State = init and (buttonIn(0) = '1' or buttonIn(1) = '1' or buttonIn(2) = '1' or buttonIn(3) = '1') then
				State <= buttonPressed;
				counter <= (others => '0');
			elsif State = buttonPressed and counter > 2500 and buttonIn(0) = '1' then
				State <= increase;
				counter <= (others => '0');
			elsif State = buttonPressed and counter > 2500 and buttonIn(2) = '1' then
				State <= decrease;
				counter <= (others => '0');
			elsif State = buttonPressed and counter > 2500 and buttonIn(1) = '1' then
				State <= nextCharacter;
				counter <= (others => '0');
			elsif State = buttonPressed and counter > 2500 and buttonIn(3) = '1' then
				counter <= (others => '0');
				findkey <= '1';
				State <= check;
			elsif State = buttonPressed and counter < 2500 and buttonIn = "0000" then
				State <= init;

			elsif State = nextCharacter and counter < 50 then
				State <= check;
				counter <= (others => '0');
				array_index <= array_index + 1;
			
			elsif State = increase and counter < 50 then
				State <= check;
				counter <= (others => '0');
				if chars(to_integer(array_index)) = 122 then
					chars(to_integer(array_index)) <= to_unsigned(97, 8);
					if findkey = '1' then
						todo_lshift <= todo_lshift + 1;
					end if;
				else
				   chars(to_integer(array_index)) <= chars(to_integer(array_index)) + 1;
				end if;
			
			elsif State = decrease and counter < 50 then
				State <= check;
				counter <= (others => '0');
				if chars(to_integer(array_index)) = 97 then
					chars(to_integer(array_index)) <= to_unsigned(122, 8);
				else
				   chars(to_integer(array_index)) <= chars(to_integer(array_index)) - 1;
				end if;
			elsif State = check and counter > 100 and buttonIn = "0000" then
				State <= init;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;
	
	

	keyOut(31 downto 24) <= Std_logic_vector(chars(0));
	keyOut(23 downto 16) <= Std_logic_vector(chars(1));
	keyOut(15 downto 8) <= Std_logic_vector(chars(2));
	keyOut(7 downto 0) <= Std_logic_vector(chars(3));
	
	
	
	-- re-used code from ex04
	
	-- button 1 (increase)
	buttonIn(0) <= '1' WHEN to_integer(unsigned(analogIn)) > 0 and
	            				to_integer(unsigned(analogIn)) < 50 ELSE '0';

	-- button 2 (next character)
	buttonIn(1) <= '1' WHEN to_integer(unsigned(analogIn)) > 900 and
	            				to_integer(unsigned(analogIn)) < 1100 ELSE '0';

	-- button 3 (decrease)
	buttonIn(2) <= '1' WHEN to_integer(unsigned(analogIn)) > 1700 and
	            				to_integer(unsigned(analogIn)) < 2000 ELSE '0';
									
	-- button 4: auto-decode
	buttonIn(3) <= '1' WHEN to_integer(unsigned(analogIn)) > 2500 and
									to_integer(unsigned(analogIn)) < 2800 ELSE '0';

end a;

