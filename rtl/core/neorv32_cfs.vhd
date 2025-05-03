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

  -- default CFS interface registers
  type cfs_regs_t is array (0 to 3) of std_ulogic_vector(31 downto 0);
  signal cfs_reg_wr : cfs_regs_t;
  signal cfs_reg_rd : cfs_regs_t;

  -- Constants for Kyber Montgomery reduction
  constant KYBER_Q : signed(15 downto 0) := to_signed(3329, 16);
  constant QINV    : signed(15 downto 0) := to_signed(-3327, 16);

  -- Pure-combinational Montgomery reduction function
  function montgomery_reduce(a : signed(31 downto 0))
    return signed is
    variable lo   : signed(15 downto 0);
    variable t0   : signed(15 downto 0);
    variable prod : signed(31 downto 0);
    variable diff : signed(31 downto 0);
  begin
    lo   := a(15 downto 0);
    t0   := lo * QINV;
    prod := resize(t0 * KYBER_Q, 32);
    diff := a - prod;
    return sra(diff, 16);
  end function;

begin

  -- Clock & IRQ outputs unused
  clkgen_en_o <= '0';
  irq_o       <= '0';
  cfs_out_o   <= (others => '0');

  -- Bus access process (unchanged)
  bus_access: process(rstn_i, clk_i)
  begin
    if rstn_i = '0' then
      cfs_reg_wr <= (others => (others => '0'));
      bus_rsp_o  <= rsp_terminate_c;
    elsif rising_edge(clk_i) then
      bus_rsp_o.ack  <= bus_req_i.stb;
      bus_rsp_o.err  <= '0';
      bus_rsp_o.data <= (others => '0');

      if bus_req_i.stb = '1' then
        if bus_req_i.rw = '1' then  -- write
          case bus_req_i.addr(15 downto 2) is
            when "00000000000000" => cfs_reg_wr(0) <= bus_req_i.data;
            when "00000000000001" => cfs_reg_wr(1) <= bus_req_i.data;
            when "00000000000010" => cfs_reg_wr(2) <= bus_req_i.data;
            when "00000000000011" => cfs_reg_wr(3) <= bus_req_i.data;
            when others           => null;
          end case;
        else                        -- read
          case bus_req_i.addr(15 downto 2) is
            when "00000000000000" => bus_rsp_o.data <= cfs_reg_rd(0);
            when "00000000000001" => bus_rsp_o.data <= cfs_reg_rd(1);
            when "00000000000010" => bus_rsp_o.data <= cfs_reg_rd(2);
            when "00000000000011" => bus_rsp_o.data <= cfs_reg_rd(3);
            when others           => null;
          end case;
        end if;
      end if;
    end if;
  end process;

  -- Custom function core: substitute original example with Montgomery reduce
  cfs_reg_rd(0) <= std_logic_vector(
                     montgomery_reduce(
                       signed(cfs_reg_wr(0))
                     )
                   );

  -- Unused CFS registers
  cfs_reg_rd(1) <= (others => '0');
  cfs_reg_rd(2) <= (others => '0');
  cfs_reg_rd(3) <= (others => '0');

end architecture neorv32_cfs_rtl;
