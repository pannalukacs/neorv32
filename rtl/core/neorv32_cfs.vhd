library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_cfs is
  generic (
    CFS_CONFIG   : std_ulogic_vector(31 downto 0);
    CFS_IN_SIZE  : natural;
    CFS_OUT_SIZE : natural
  );
  port (
    clk_i       : in  std_ulogic;
    rstn_i      : in  std_ulogic;
    bus_req_i   : in  bus_req_t;
    bus_rsp_o   : out bus_rsp_t;
    clkgen_en_o : out std_ulogic;
    clkgen_i    : in  std_ulogic_vector(7 downto 0);
    irq_o       : out std_ulogic;
    cfs_in_i    : in  std_ulogic_vector(CFS_IN_SIZE-1 downto 0);
    cfs_out_o   : out std_ulogic_vector(CFS_OUT_SIZE-1 downto 0)
  );
end neorv32_cfs;

architecture neorv32_cfs_rtl of neorv32_cfs is

  -- Interface registers
  type cfs_regs_t is array (0 to 3) of std_ulogic_vector(31 downto 0);
  signal cfs_reg_wr : cfs_regs_t := (others => (others => '0'));
  signal cfs_reg_rd : cfs_regs_t;

  -- Constants
  constant KYBER_Q : signed(15 downto 0) := to_signed(3329, 16);
  constant QINV    : signed(15 downto 0) := to_signed(-3327, 16);

  -- Pipeline registers
  signal a_reg         : signed(31 downto 0) := (others => '0');
  signal t0_stage      : signed(31 downto 0) := (others => '0');
  signal prod_stage    : signed(31 downto 0) := (others => '0');
  signal diff_unsigned : unsigned(31 downto 0) := (others => '0');
  signal result_stage  : std_logic_vector(15 downto 0) := (others => '0');

  -- Pipeline control
  signal stage_en      : std_logic_vector(2 downto 0) := (others => '0');
  signal irq_trigger   : std_logic := '0'; 

begin

  clkgen_en_o <= '0';
  -- irq_o       <= '0';
  cfs_out_o   <= (others => '0');

  -----------------------------------------------------------------------------
  -- Bus interface
  -----------------------------------------------------------------------------
  bus_access : process(clk_i, rstn_i)
  begin
    if rstn_i = '0' then
      cfs_reg_wr <= (others => (others => '0'));
      bus_rsp_o  <= rsp_terminate_c;
    elsif rising_edge(clk_i) then
      bus_rsp_o.ack  <= bus_req_i.stb;
      bus_rsp_o.err  <= '0';
      bus_rsp_o.data <= (others => '0');

      if bus_req_i.stb = '1' then
        if bus_req_i.rw = '1' then
          case bus_req_i.addr(15 downto 2) is
            when "00000000000000" => cfs_reg_wr(0) <= bus_req_i.data;
            when "00000000000001" => cfs_reg_wr(1) <= bus_req_i.data;
            when "00000000000010" => cfs_reg_wr(2) <= bus_req_i.data;
            when "00000000000011" => cfs_reg_wr(3) <= bus_req_i.data;
            when others           => null;
          end case;
        else
          case bus_req_i.addr(15 downto 2) is
            when "00000000000000" => bus_rsp_o.data <= cfs_reg_rd(0);
            when "00000000000001" => bus_rsp_o.data <= cfs_reg_rd(1);
            when "00000000000010" => bus_rsp_o.data <= cfs_reg_rd(2);
            when "00000000000011" => bus_rsp_o.data <= cfs_reg_rd(3);
            when others           => bus_rsp_o.data <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Pipelined Montgomery reduction logic
  -----------------------------------------------------------------------------
  process(clk_i, rstn_i)
    variable diff : signed(31 downto 0);
  begin
    if rstn_i = '0' then
      a_reg         <= (others => '0');
      t0_stage      <= (others => '0');
      prod_stage    <= (others => '0');
      diff_unsigned <= (others => '0');
      result_stage  <= (others => '0');
      stage_en      <= (others => '0');
    elsif rising_edge(clk_i) then
      -- Pipeline shift
      stage_en <= stage_en(1 downto 0) & '0';

      -- Stage 1: latch input
      if bus_req_i.stb = '1' and bus_req_i.rw = '1' and bus_req_i.addr(15 downto 2) = "00000000000000" then
        a_reg    <= signed(cfs_reg_wr(0));
        t0_stage <= resize(signed(unsigned(cfs_reg_wr(0)(15 downto 0))) * QINV, 32);
        stage_en(0) <= '1';
      end if;

      -- Stage 2: compute product
      if stage_en(0) = '1' then
        prod_stage <= resize(signed(t0_stage(15 downto 0)) * KYBER_Q, 32);
        -- stage_en(1) <= '1';
      end if;

      -- Stage 3: compute result
      if stage_en(1) = '1' then
        diff := a_reg - prod_stage;
        diff_unsigned <= unsigned(diff); -- Convert to unsigned before shifting
        result_stage <= std_logic_vector(diff_unsigned(31 downto 16)); -- Extract upper 16 bits
        irq_trigger <= '1'; -- Raise interrupt
      end if;

      if bus_req_i.stb = '1' and bus_req_i.rw = '0' and bus_req_i.addr(15 downto 2) = "00000000000000" then
        irq_trigger <= '0';
      end if;

    end if;
  end process;
  
  irq_o <= irq_trigger;
  -- Output result (lower 16 bits of REG[0] = result, upper 16 bits = zero)
  cfs_reg_rd(0) <= (31 downto 16 => '0') & result_stage;
  cfs_reg_rd(1) <= (others => '0');
  cfs_reg_rd(2) <= (others => '0');
  cfs_reg_rd(3) <= (others => '0');

end neorv32_cfs_rtl;
