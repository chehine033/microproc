library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_multiplier is
end tb_multiplier;

architecture sim of tb_multiplier is

    component multiplier
        port(
            a, b : in  STD_LOGIC_VECTOR(3 downto 0);
            p    : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    signal a, b : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal p    : STD_LOGIC_VECTOR(7 downto 0);

begin

    DUT : multiplier port map(a => a, b => b, p => p);

    stim : process
        variable expected : unsigned(7 downto 0);
    begin
        for i in 0 to 15 loop
            for j in 0 to 15 loop
                a <= std_logic_vector(to_unsigned(i, 4));
                b <= std_logic_vector(to_unsigned(j, 4));
                wait for 20 ns;
                expected := to_unsigned(i * j, 8);
                assert unsigned(p) = expected
                    report "FAIL: " & integer'image(i) & " x " & integer'image(j) &
                           " = " & integer'image(to_integer(unsigned(p))) &
                           " (expected " & integer'image(i * j) & ")"
                    severity error;
            end loop;
        end loop;
        report "All 256 combinations passed." severity note;
        wait;
    end process;

end sim;
