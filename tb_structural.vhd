library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity microproc_str_tb is
end microproc_str_tb;

architecture sim of microproc_str_tb is

    component microproc_str
        port(clk, reset : in std_logic);
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

begin

    DUT : microproc_str port map(clk => clk, reset => reset);

    clk <= not clk after CLK_PERIOD / 2;

    stim : process
    begin
        reset <= '1';
        wait for 3 * CLK_PERIOD;
        reset <= '0';
        wait for 100 * CLK_PERIOD;
        wait;
    end process;

end sim;
