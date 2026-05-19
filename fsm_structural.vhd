library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- State encoding:
--   LOAD     = "0000"   (reset state) fetch instruction
--   INCR     = "0001"   increment PC
--   DECODE   = "0010"   decode opcode, branch conditions evaluated here
--   ALU_EXEC = "0011"   execute ADD or SUB
--   MEM      = "0100"   execute LDA or STO
--   JUMP     = "0101"   load jump target into PC
--   HALT     = "0110"   STP, self-looping
--
-- ISA opcode encoding (bits 15:12 of instruction word):
--   LDA="0000"  STO="0001"  ADD="0010"  SUB="0011"
--   JMP="0100"  JGE="0101"  JNE="0110"  STP="0111"
--
-- Root cause of original bug: the original equations remapped opcode bits
-- (opcode0=opcode(2), opcode1=opcode(1), opcode2=opcode(0)), which caused ADD
-- to route to an incorrect execution state (acc=acc-acc=0, pc=0, ram write).
-- Fix: use opcode bits directly, re-derive all equations from truth table.

entity machine_etat_structurelle is
    Port (
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
end machine_etat_structurelle;

architecture Behavioralstructurelle of machine_etat_structurelle is

    signal state, next_state : std_logic_vector(3 downto 0);

    -- State bit aliases
    signal S3, S2, S1, S0 : std_logic;

    -- State predicates (combinational decode of current state)
    signal in_LOAD, in_INCR, in_DECODE : std_logic;
    signal in_ALU,  in_MEM,  in_JUMP   : std_logic;
    signal in_HALT                      : std_logic;

    -- Next-state bits
    signal NS3, NS2, NS1, NS0 : std_logic;

    -- Jump-taken predicate (meaningful only when in_DECODE=1)
    -- JMP always; JGE when acc15=0; JNE when accZ=1
    signal take_jump : std_logic;

begin

    -- ----------------------------------------------------------------
    -- State register
    -- ----------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            state <= "0000";   -- LOAD
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- ----------------------------------------------------------------
    -- State bit extraction
    -- ----------------------------------------------------------------
    S3 <= state(3);  S2 <= state(2);
    S1 <= state(1);  S0 <= state(0);


    -- State decode (S3 is always '0' in valid states)

    in_LOAD   <= not S3 and not S2 and not S1 and not S0;
    in_INCR   <= not S3 and not S2 and not S1 and     S0;
    in_DECODE <= not S3 and not S2 and     S1 and not S0;
    in_ALU    <= not S3 and not S2 and     S1 and     S0;
    in_MEM    <= not S3 and     S2 and not S1 and not S0;
    in_JUMP   <= not S3 and     S2 and not S1 and     S0;
    in_HALT   <= not S3 and     S2 and     S1 and not S0;


    -- Jump-taken predicate
    --   JMP "0100": opcode(2)=1, opcode(1)=0, opcode(0)=0  always jump
    --   JGE "0101": opcode(2)=1, opcode(1)=0, opcode(0)=1  jump if acc15=0
    --   JNE "0110": opcode(2)=1, opcode(1)=1, opcode(0)=0  jump if accZ=1

    take_jump <= (opcode(2) and not opcode(1) and not opcode(0))
              or (opcode(2) and not opcode(1) and     opcode(0) and not acc15)
              or (opcode(2) and     opcode(1) and not opcode(0) and     accZ);

    -- ----------------------------------------------------------------
    -- Next-state equations
    -- ----------------------------------------------------------------
    next_state <= NS3 & NS2 & NS1 & NS0;

    NS3 <= '0';   -- never used in this 7-state machine

    -- NS2=1 → next state is MEM(0100), JUMP(0101), or HALT(0110)
    NS2 <= (in_DECODE and not opcode(2) and not opcode(1))        -- LDA/STO  → MEM
        or (in_DECODE and take_jump)                               -- branch   → JUMP
        or (in_DECODE and opcode(2) and opcode(1) and opcode(0))  -- STP      → HALT
        or  in_HALT;                                               -- HALT self-loop

    -- NS1=1 → next state is DECODE(0010), ALU_EXEC(0011), or HALT(0110)
    NS1 <= in_INCR                                                 -- INCR     → DECODE
        or (in_DECODE and not opcode(2) and opcode(1))             -- ADD/SUB  → ALU_EXEC
        or (in_DECODE and opcode(2) and opcode(1) and opcode(0))  -- STP      → HALT
        or  in_HALT;                                               -- HALT self-loop

    -- NS0=1 → next state is INCR(0001), ALU_EXEC(0011), or JUMP(0101)
    NS0 <= in_LOAD                                                 -- LOAD     → INCR
        or (in_DECODE and not opcode(2) and opcode(1))             -- ADD/SUB  → ALU_EXEC
        or (in_DECODE and take_jump);                              -- branch   → JUMP

    -- ----------------------------------------------------------------
    -- Output equations
    -- ----------------------------------------------------------------

    -- Fetch instruction into IR
    ir_ld <= in_LOAD;

    -- Load PC: in INCR (PC+1) and JUMP (branch target)
    pc_ld <= in_INCR or in_JUMP;

    -- Address mux: use IR address field (not PC) during execution states
    selA <= in_ALU or in_MEM or in_JUMP;

    -- Data mux: use data bus (from RAM) during ALU_EXEC and LDA
    --   opcode(0)=0 → LDA; opcode(0)=1 → STO
    selB <= in_ALU or (in_MEM and not opcode(0));

    -- Load accumulator: ALU result or RAM data (LDA)
    acc_ld <= in_ALU or (in_MEM and not opcode(0));

    -- Drive data bus from ACC (STO only)
    acc_oe <= in_MEM and opcode(0);

    -- Write enable: low only during STO
    RnW <= not (in_MEM and opcode(0));

    -- ALU function:
    --   "00" = pass B      (LOAD, DECODE, MEM, JUMP — no arithmetic needed)
    --   "10" = ADD (A+B)   — ALU_EXEC with ADD "0010" (opcode(0)=0)
    --   "01" = SUB (A-B)   — ALU_EXEC with SUB "0011" (opcode(0)=1)
    --   "11" = B+1         — INCR (PC increment)
    alufs(1) <= in_INCR or (in_ALU and not opcode(0));   -- "1x": INCR or ADD
    alufs(0) <= in_INCR or (in_ALU and     opcode(0));   -- "x1": INCR or SUB

end Behavioralstructurelle;
