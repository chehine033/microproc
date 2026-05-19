library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mux_12to1 is
    port(
        A, B : in  STD_LOGIC_VECTOR(11 downto 0);
        S0   : in  STD_LOGIC;
        Z    : out STD_LOGIC_VECTOR(11 downto 0)
    );
end mux_12to1;

architecture archmux12 of mux_12to1 is
begin
    with S0 select
        Z <= A              when '0',
             B              when '1',
             "XXXXXXXXXXXX" when others;
end archmux12;


library ieee;
use ieee.std_logic_1164.all;

entity Full_Adder is
    port(
        X, Y, Cin : in  std_logic;
        sum, Cout  : out std_logic
    );
end Full_Adder;

architecture fadder of Full_Adder is
begin
    sum  <= (X xor Y) xor Cin;
    Cout <= (X and (Y or Cin)) or (Cin and Y);
end fadder;


library ieee;
use ieee.std_logic_1164.all;

entity Full_Subber is
    port(
        X, Y, Cin : in  std_logic;
        sum, Cout  : out std_logic
    );
end Full_Subber;

architecture fsubber of Full_Subber is
begin
    sum  <= (X xor Y) xor Cin;
    -- Borrow-out: majority of (NOT X, Y, Cin)
    -- old formula (not X and Y) or (Cin and (X xor Y)) was wrong for
    -- X=1,Y=0,Cin=1 (produced borrow=1; correct is 0) and
    -- X=1,Y=1,Cin=1 (produced borrow=0; correct is 1)
    Cout <= (not X and Y) or (not X and Cin) or (Y and Cin);
end fsubber;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity subber is
    Generic (N : natural := 16);
    port(
        A, B : in  std_logic_vector(N-1 downto 0);
        Cin  : in  std_logic;
        Cout : out std_logic;
        S    : out std_logic_vector(N-1 downto 0)
    );
end subber;

architecture subberarch of subber is
    signal C : std_logic_vector(N-2 downto 0);
    component Full_Subber
        port(X, Y, Cin : in std_logic; sum, Cout : out std_logic);
    end component;
begin
    U       : Full_Subber port map(X=>A(0), Y=>B(0), Cin=>Cin, sum=>S(0), Cout=>C(0));
    a5tani  : for i in 1 to N-2 generate
        addi : Full_Subber port map(A(i), B(i), C(i-1), S(i), C(i));
    end generate;
    dernier : Full_Subber port map(A(N-1), B(N-1), C(N-2), S(N-1), Cout);
end subberarch;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity adder is
    Generic (N : natural := 16);
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
    U       : Full_Adder port map(X=>A(0), Y=>B(0), Cin=>Cin, sum=>S(0), Cout=>C(0));
    a5tani  : for i in 1 to N-2 generate
        addi : Full_Adder port map(A(i), B(i), C(i-1), S(i), C(i));
    end generate;
    dernier : Full_Adder port map(A(N-1), B(N-1), C(N-2), S(N-1), Cout);
end adderarch;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity mux_16to1 is
    port(
        A, B : in  STD_LOGIC_VECTOR(15 downto 0);
        S0   : in  STD_LOGIC;
        Z    : out STD_LOGIC_VECTOR(15 downto 0)
    );
end mux_16to1;

architecture archmux16 of mux_16to1 is
begin
    with S0 select
        Z <= A                  when '0',
             B                  when '1',
             "XXXXXXXXXXXXXXXX" when others;
end archmux16;


library ieee;
use ieee.std_logic_1164.all;

entity buffer1 is
    port(
        a      : in  std_logic_vector(15 downto 0);
        enable : in  std_logic;
        b      : out std_logic_vector(15 downto 0)
    );
end buffer1;

architecture archbuffer of buffer1 is
begin
    with enable select
        b <= a                  when '1',
             "ZZZZZZZZZZZZZZZZ" when others;
end archbuffer;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Async_RAM is
    port(
        address : in    std_logic_vector(11 downto 0);
        data    : inout std_logic_vector(15 downto 0);
        we      : in    std_logic
    );
end Async_RAM;

architecture archARAM of Async_RAM is
    type ram_type is array (4095 downto 0) of std_logic_vector(15 downto 0);
    -- Program (addr 0-13) + data (addr 2048-2053)
    --
    --  0: LDA 2048   ACC = 10
    --  1: ADD 2049   ACC = 15
    --  2: STO 2050   RAM[2050] = 15
    --  3: LDA 2051   ACC = 3  (loop counter)
    --  4: SUB 2052   ACC = ACC - 1          <─┐ loop
    --  5: JNE 4      jump to 4 if ACC ≠ 0   ──┘
    --  6: JGE 8      ACC=0 ≥ 0  → taken, jump to 8
    --  7: JMP 11     (skipped)
    --  8: LDA 2053   ACC = 0xFFFF (-1 in two's complement)
    --  9: JGE 11     ACC=-1 < 0 → not taken, fall through
    -- 10: JMP 12     jump to correct halt
    -- 11: JMP 13     only reachable on wrong JGE behaviour
    -- 12: STP        correct halt
    -- 13: STP        wrong-path indicator
    signal RAM : ram_type := (
        0      => "0000100000000000",   -- LDA 2048
        1      => "0010100000000001",   -- ADD 2049
        2      => "0001100000000010",   -- STO 2050
        3      => "0000100000000011",   -- LDA 2051
        4      => "0011100000000100",   -- SUB 2052
        5      => "0110000000000100",   -- JNE 4
        6      => "0101000000001000",   -- JGE 8
        7      => "0100000000001011",   -- JMP 11
        8      => "0000100000000101",   -- LDA 2053
        9      => "0101000000001011",   -- JGE 11
        10     => "0100000000001100",   -- JMP 12
        11     => "0100000000001101",   -- JMP 13
        12     => "0111000000000000",   -- STP  (correct halt)
        13     => "0111000000000000",   -- STP  (wrong-path indicator)
        2048   => "0000000000001010",   -- 10
        2049   => "0000000000000101",   -- 5
        2050   => "0000000000000000",   -- result slot (will hold 15)
        2051   => "0000000000000011",   -- 3  (loop counter)
        2052   => "0000000000000001",   -- 1  (decrement step)
        2053   => "1111111111111111",   -- 0xFFFF  (-1 in two's complement)
        others => (others => '0')
    );
begin
    RAM(to_integer(unsigned(address))) <= data when we = '1';
    with we select
        data <= RAM(to_integer(unsigned(address))) when '0',
                "ZZZZZZZZZZZZZZZZ"                 when others;
end archARAM;


library ieee;
use ieee.std_logic_1164.all;

entity PC is
    port(
        clk   : in  std_logic;
        pc_ld : in  std_logic;
        A     : in  std_logic_vector(15 downto 0);
        B     : out std_logic_vector(11 downto 0)
    );
end PC;

architecture archPC of PC is
    signal B_reg : std_logic_vector(11 downto 0) := (others => '0');
begin
    B <= B_reg;
    process(clk)
    begin
        if rising_edge(clk) then
            if pc_ld = '1' then
                B_reg <= A(11 downto 0);
            end if;
        end if;
    end process;
end archPC;


library ieee;
use ieee.std_logic_1164.all;

entity IR is
    port(
        clk    : in  std_logic;
        ir_ld  : in  std_logic;
        A      : in  std_logic_vector(15 downto 0);
        B      : out std_logic_vector(11 downto 0);
        opcode : out std_logic_vector(3 downto 0)
    );
end IR;

architecture archIR of IR is
    signal B_reg      : std_logic_vector(11 downto 0) := (others => '0');
    signal opcode_reg : std_logic_vector(3 downto 0)  := (others => '0');
begin
    B      <= B_reg;
    opcode <= opcode_reg;
    process(clk)
    begin
        if rising_edge(clk) then
            if ir_ld = '1' then
                B_reg      <= A(11 downto 0);
                opcode_reg <= A(15 downto 12);
            end if;
        end if;
    end process;
end archIR;


-- FIX 1: separate carry signals for adder and subber, muxed to ualoorflag.
-- Original drove ualoorflag from both simultaneously causing a resolved-signal conflict.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UAL is
    port(
        a          : in  std_logic_vector(15 downto 0);
        b          : in  std_logic_vector(15 downto 0);
        alufs      : in  std_logic_vector(1 downto 0);
        ualoorflag : out std_logic;
        s          : out std_logic_vector(15 downto 0)
    );
end UAL;

architecture archUAL of UAL is
    component adder
        port(
            A, B : in  std_logic_vector(15 downto 0);
            Cin  : in  std_logic;
            Cout : out std_logic;
            S    : out std_logic_vector(15 downto 0)
        );
    end component;
    component subber
        port(
            A, B : in  std_logic_vector(15 downto 0);
            Cin  : in  std_logic;
            Cout : out std_logic;
            S    : out std_logic_vector(15 downto 0)
        );
    end component;
    signal addresult, subresult : std_logic_vector(15 downto 0);
    signal addcout, subcout     : std_logic;
begin
    add1 : adder  port map(a, b, '0', addcout, addresult);
    sub1 : subber port map(a, b, '0', subcout, subresult);

    with alufs select
        s <= b                                 when "00",
             std_logic_vector(unsigned(b) + 1) when "11",
             addresult                          when "10",
             subresult                          when others;

    with alufs select
        ualoorflag <= addcout when "10",
                      subcout  when "01",
                      '0'      when others;
end archUAL;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ACC is
    port(
        A      : in  std_logic_vector(15 downto 0);
        acc_ld : in  std_logic;
        clk    : in  std_logic;
        accZ   : out std_logic;
        acc15  : out std_logic;
        B      : out std_logic_vector(15 downto 0)
    );
end ACC;

architecture test of ACC is
    signal B_reg     : std_logic_vector(15 downto 0) := (others => '0');
    signal accZ_reg  : std_logic := '0';
    signal acc15_reg : std_logic := '0';
begin
    B     <= B_reg;
    accZ  <= accZ_reg;
    acc15 <= acc15_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if acc_ld = '1' then
                B_reg     <= A;
                acc15_reg <= A(15);
                if A /= "0000000000000000" then
                    accZ_reg <= '1';
                else
                    accZ_reg <= '0';
                end if;
            end if;
        end if;
    end process;
end test;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity machine_etat is
    port(
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        accZ   : in  STD_LOGIC;
        acc15  : in  STD_LOGIC;
        opcode : in  STD_LOGIC_VECTOR(3 downto 0);
        selA   : out STD_LOGIC;
        selB   : out STD_LOGIC;
        pc_ld  : out STD_LOGIC;
        ir_ld  : out STD_LOGIC;
        acc_ld : out STD_LOGIC;
        acc_oe : out STD_LOGIC;
        alufs  : out STD_LOGIC_VECTOR(1 downto 0);
        RnW    : out STD_LOGIC
    );
end machine_etat;

architecture Behavioral of machine_etat is
    type state_type is (
        LOAD_INSTRUCTION,
        INCREMENT_PC,
        DECODE_OPCODE,
        EXECUTE_ALU_OPERATION,
        MEMORY_ACCESS,
        JUMP_CONDITIONAL,
        HALT_PROCESSOR
    );
    signal state, next_state : state_type;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            state <= LOAD_INSTRUCTION;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    process(state, opcode, accZ, acc15)
    begin
        case state is
            when LOAD_INSTRUCTION =>
                next_state <= INCREMENT_PC;

            when INCREMENT_PC =>
                next_state <= DECODE_OPCODE;

            when DECODE_OPCODE =>
                case opcode is
                    when "0000" =>
                        next_state <= MEMORY_ACCESS;
                    when "0001" =>
                        next_state <= MEMORY_ACCESS;
                    when "0010" | "0011" =>
                        next_state <= EXECUTE_ALU_OPERATION;
                    when "0100" =>
                        next_state <= JUMP_CONDITIONAL;
                    when "0101" =>
                        if acc15 = '0' then next_state <= JUMP_CONDITIONAL;
                        else                next_state <= LOAD_INSTRUCTION; end if;
                    when "0110" =>
                        -- FIX 2: jump when ACC != 0 (accZ='1'), not when ACC = 0
                        if accZ = '1' then next_state <= JUMP_CONDITIONAL;
                        else               next_state <= LOAD_INSTRUCTION; end if;
                    when "0111" =>
                        next_state <= HALT_PROCESSOR;
                    when others =>
                        next_state <= LOAD_INSTRUCTION;
                end case;

            when EXECUTE_ALU_OPERATION => next_state <= LOAD_INSTRUCTION;
            when MEMORY_ACCESS         => next_state <= LOAD_INSTRUCTION;
            when JUMP_CONDITIONAL      => next_state <= LOAD_INSTRUCTION;
            when HALT_PROCESSOR        => next_state <= HALT_PROCESSOR;
            when others                => next_state <= LOAD_INSTRUCTION;
        end case;
    end process;

    process(state, opcode)
    begin
        selA   <= '0';
        selB   <= '0';
        pc_ld  <= '0';
        ir_ld  <= '0';
        acc_ld <= '0';
        acc_oe <= '0';
        alufs  <= "00";
        RnW    <= '1';

        case state is
            when LOAD_INSTRUCTION =>
                ir_ld <= '1';

            when INCREMENT_PC =>
                pc_ld <= '1';
                alufs <= "11";

            when DECODE_OPCODE =>
                null;

            when EXECUTE_ALU_OPERATION =>
                selA   <= '1';
                selB   <= '1';
                acc_ld <= '1';
                case opcode is
                    when "0010" => alufs <= "10";
                    when "0011" => alufs <= "01";
                    when others => null;
                end case;

            when MEMORY_ACCESS =>
                selA <= '1';
                case opcode is
                    when "0000" =>      -- LDA: read from RAM into ACC
                        selB   <= '1';
                        acc_ld <= '1';
                    when "0001" =>      -- STO: write ACC to RAM
                        RnW    <= '0';
                        acc_oe <= '1';
                        -- FIX 3: acc_ld stays '0' — ACC must not be overwritten during a store
                    when others => null;
                end case;

            when JUMP_CONDITIONAL =>
                pc_ld <= '1';
                selA  <= '1';

            when HALT_PROCESSOR =>
                null;

            when others =>
                null;
        end case;
    end process;

end Behavioral;


-- FIX 4: removed dead 4-bit alufs signal. microproc now uses aluf (2-bit) directly.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity microproc is
    port(clk, reset : in std_logic);
end microproc;

architecture archmicproc of microproc is
    component mux_12to1
        port(A, B : in STD_LOGIC_VECTOR(11 downto 0); S0 : in STD_LOGIC; Z : out STD_LOGIC_VECTOR(11 downto 0));
    end component;
    component mux_16to1
        port(A, B : in STD_LOGIC_VECTOR(15 downto 0); S0 : in STD_LOGIC; Z : out STD_LOGIC_VECTOR(15 downto 0));
    end component;
    component buffer1
        port(a : in std_logic_vector(15 downto 0); enable : in std_logic; b : out std_logic_vector(15 downto 0));
    end component;
    component Async_RAM
        port(address : in std_logic_vector(11 downto 0); data : inout std_logic_vector(15 downto 0); we : in std_logic);
    end component;
    component UAL
        port(a, b : in std_logic_vector(15 downto 0); alufs : in std_logic_vector(1 downto 0);
             ualoorflag : out std_logic; s : out std_logic_vector(15 downto 0));
    end component;
    component PC
        port(clk : in std_logic; pc_ld : in std_logic; A : in std_logic_vector(15 downto 0); B : out std_logic_vector(11 downto 0));
    end component;
    component ACC
        port(A : in std_logic_vector(15 downto 0); acc_ld, clk : in std_logic;
             accZ, acc15 : out std_logic; B : out std_logic_vector(15 downto 0));
    end component;
    component IR
        port(clk : in std_logic; ir_ld : in std_logic; A : in std_logic_vector(15 downto 0);
             B : out std_logic_vector(11 downto 0); opcode : out std_logic_vector(3 downto 0));
    end component;
    component machine_etat
        port(clk, reset, accZ, acc15 : in STD_LOGIC; opcode : in STD_LOGIC_VECTOR(3 downto 0);
             selA, selB, pc_ld, ir_ld, acc_ld, acc_oe : out STD_LOGIC;
             alufs : out STD_LOGIC_VECTOR(1 downto 0); RnW : out STD_LOGIC);
    end component;

    signal opcod                         : std_logic_vector(3 downto 0);
    signal aluf                          : std_logic_vector(1 downto 0);
    signal accz, acc15                   : std_logic;
    signal RnW, selA, selB               : std_logic;
    signal pc_ld, ir_ld, acc_ld, acc_oe : std_logic;
    signal ualoorflag, we                : std_logic;
    signal data, s, b, a, addresse16    : std_logic_vector(15 downto 0);
    signal adresse, s1, s2              : std_logic_vector(11 downto 0);
begin
    addresse16 <= "0000" & adresse;
    we         <= not RnW;

    muxA    : mux_12to1 port map(s1, s2, selA, adresse);
    buffer2 : buffer1   port map(a, acc_oe, data);
    muxB    : mux_16to1 port map(addresse16, data, selB, b);
    IR1     : IR        port map(clk, ir_ld, data, s2, opcod);
    PC1     : PC        port map(clk, pc_ld, s, s1);
    ACC1    : ACC       port map(s, acc_ld, clk, accz, acc15, a);
    UAL1    : UAL       port map(a, b, aluf, ualoorflag, s);
    RAM     : Async_RAM port map(adresse, data, we);
    mach    : machine_etat port map(clk, reset, accz, acc15, opcod,
                                    selA, selB, pc_ld, ir_ld,
                                    acc_ld, acc_oe, aluf, RnW);
end archmicproc;
