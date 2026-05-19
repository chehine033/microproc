library ieee;
use ieee.std_logic_1164.all;

entity Full_Adder is
    port(
        X, Y, Cin : in  std_logic;
        sum, Cout : out std_logic
    );
end Full_Adder;

architecture bhv of Full_Adder is
begin
    sum  <= (X xor Y) xor Cin;
    Cout <= (X and (Y or Cin)) or (Cin and Y);
end bhv;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mux_4to1 is
    port(
        A, B : in  STD_LOGIC_VECTOR(3 downto 0);
        S0   : in  STD_LOGIC;
        Z    : out STD_LOGIC_VECTOR(3 downto 0)
    );
end mux_4to1;

architecture bhv of mux_4to1 is
begin
    with S0 select
        Z <= A when '0',
             B when others;
end bhv;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity adder is
    Generic (N : natural := 8);
    port(
        A, B : in  std_logic_vector(N-1 downto 0);
        Cin  : in  std_logic;
        Cout : out std_logic;
        S    : out std_logic_vector(N-1 downto 0)
    );
end adder;

architecture adderarch of adder is
    signal C : std_logic_vector(N-2 downto 0);
    component Full_Adder
        port(X, Y, Cin : in std_logic; sum, Cout : out std_logic);
    end component;
begin
    fa_lsb : Full_Adder port map(X=>A(0), Y=>B(0), Cin=>Cin, sum=>S(0), Cout=>C(0));
    fa_chain : for i in 1 to N-2 generate
        fa : Full_Adder port map(A(i), B(i), C(i-1), S(i), C(i));
    end generate;
    fa_msb : Full_Adder port map(A(N-1), B(N-1), C(N-2), S(N-1), Cout);
end adderarch;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity multiplier is
    port(
        a, b : in  STD_LOGIC_VECTOR(3 downto 0);
        p    : out STD_LOGIC_VECTOR(7 downto 0)
    );
end multiplier;

architecture bhv of multiplier is
    signal om1, om2, om3, om4 : std_logic_vector(3 downto 0);
    signal co1, co2, co3      : std_logic;
    signal i1, i2, i3, i4    : std_logic_vector(7 downto 0);
    signal s1, s2             : std_logic_vector(7 downto 0);

    component adder
        port(
            A, B : in  std_logic_vector(7 downto 0);
            Cin  : in  std_logic;
            Cout : out std_logic;
            S    : out std_logic_vector(7 downto 0)
        );
    end component;

    component mux_4to1
        port(
            A, B : in  STD_LOGIC_VECTOR(3 downto 0);
            S0   : in  STD_LOGIC;
            Z    : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

begin
    -- Partial products via MUX: select A if B[i]=1, else 0000
    pp0 : mux_4to1 port map("0000", a, b(0), om1);
    pp1 : mux_4to1 port map("0000", a, b(1), om2);
    pp2 : mux_4to1 port map("0000", a, b(2), om3);
    pp3 : mux_4to1 port map("0000", a, b(3), om4);

    -- Shift partial products to their bit-weight positions
    i1 <= "0000" & om1;
    i2 <= "000"  & om2 & "0";
    i3 <= "00"   & om3 & "00";
    i4 <= "0"    & om4 & "000";

    -- Sum all partial products
    add_lo  : adder port map(i1, i2, '0', co1, s1);
    add_hi  : adder port map(i3, i4, '0', co2, s2);
    add_out : adder port map(s1, s2, '0', co3,  p);

end bhv;
