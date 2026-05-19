-- microproc_str: top-level using the structural (boolean-equation) FSM.
-- Compile order:
--   vcom comportemental_fixed.vhd "structural state machine.vhd" structural_fixed.vhd
--
-- Original FSM bugs that were found and fixed in structural state machine.vhd:
--   ADD ("0010"): opcode bit remapping caused routing to wrong state.
--     Result: ACC = ACC - ACC = 0; old ACC written to RAM[operand].
--   STO ("0001"): wrong execution state had acc_ld=1 with selB=0.
--     Result: ACC overwritten with "0000" & IR_address instead of RAM data.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity microproc_str is
    port(clk, reset : in std_logic);
end microproc_str;

architecture archmicproc_str of microproc_str is

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
    component machine_etat_structurelle
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
    mach    : machine_etat_structurelle port map(clk, reset, accz, acc15, opcod,
                                                 selA, selB, pc_ld, ir_ld,
                                                 acc_ld, acc_oe, aluf, RnW);
end archmicproc_str;
