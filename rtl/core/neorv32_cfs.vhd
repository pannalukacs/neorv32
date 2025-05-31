-- ================================================================================ --
-- NEORV32 SoC - Custom Functions Subsystem (CFS)                                   --
-- -------------------------------------------------------------------------------- --
-- Kyber Montgomery‑Reduce example                                                  --
-- Write operand 'a' (32 bit) to REG[0]; read REG[0] back to obtain                 --
-- montgomery_reduce(a) in the lower 16 bits (upper 16 bits are zero).             --
-- -------------------------------------------------------------------------------- --
-- The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              --
-- Copyright (c) NEORV32 contributors.                                              --
-- Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_cfs is
  generic (
    CFS_CONFIG   : std_ulogic_vector(31 downto 0); -- custom CFS configuration generic
    CFS_IN_SIZE  : natural;                        -- size of CFS input conduit in bits
    CFS_OUT_SIZE : natural                         -- size of CFS output conduit in bits
  );
  port (
    clk_i       : in  std_ulogic; -- global clock line
    rstn_i      : in  std_ulogic; -- global reset line, low‑active, use as async
    bus_req_i   : in  bus_req_t;  -- bus request
    bus_rsp_o   : out bus_rsp_t;  -- bus response
    clkgen_en_o : out std_ulogic; -- enable clock generator
    clkgen_i    : in  std_ulogic_vector(7 downto 0); -- derived clock enables
    irq_o       : out std_ulogic; -- interrupt request
    cfs_in_i    : in  std_ulogic_vector(CFS_IN_SIZE-1 downto 0); -- custom inputs
    cfs_out_o   : out std_ulogic_vector(CFS_OUT_SIZE-1 downto 0) -- custom outputs
  );
end neorv32_cfs;

-- ################################################################################################
architecture neorv32_cfs_rtl of neorv32_cfs is
-- ################################################################################################

  -- --------------------------------------------------------------------------
  -- Interface register file (WRITE side & READ side)
  -- --------------------------------------------------------------------------
  type cfs_regs_t is array (0 to 3) of std_ulogic_vector(31 downto 0);
  signal cfs_reg_wr : cfs_regs_t := (others => (others => '0'));
  signal cfs_reg_rd : cfs_regs_t;

  -- --------------------------------------------------------------------------
  -- Constants for Kyber q = 3329
  -- --------------------------------------------------------------------------
  constant KYBER_Q : signed(15 downto 0) := to_signed(3329, 16);
  constant QINV    : signed(15 downto 0) := to_signed(-3327, 16); -- 3329⁻¹ mod 2¹⁶

  -- --------------------------------------------------------------------------
  -- Pure combinational Montgomery‑reduce
  -- --------------------------------------------------------------------------
  function montgomery_reduce(a : signed(31 downto 0)) return signed is
    variable lo_u : unsigned(15 downto 0);
    variable t0   : signed(31 downto 0);
    variable prod : signed(31 downto 0);
    variable diff : signed(31 downto 0);
  begin
    -- Step 1: t0 = (a mod 2¹⁶) * q⁻¹
    lo_u := unsigned(a(15 downto 0));
    t0   := resize(signed(lo_u) * QINV, 32);

    -- Step 2: prod = (t0 mod 2¹⁶) * q
    prod := resize(signed(t0(15 downto 0)) * KYBER_Q, 32);

    -- Step 3: (a – t0*q) >> 16   (logical shift)
    diff := a - prod;
    return signed(shift_right(unsigned(diff), 16)); -- zero‑extended shift
  end function;

-- ################################################################################################
begin
-- ################################################################################################

  -- ----------------------------------------------------------------------------
  -- Static outputs (unused features)
  -- ----------------------------------------------------------------------------
  clkgen_en_o <= '0';                 -- no derived clocks required
  irq_o       <= '0';                 -- no interrupt generated
  cfs_out_o   <= (others => '0');     -- conduit unused in this example

  -- ----------------------------------------------------------------------------
  -- Bus interface : read / write handshake
  -- ----------------------------------------------------------------------------
  bus_access : process(clk_i, rstn_i)
  begin
    if rstn_i = '0' then                          -- asynchronous reset (low‑active)
      cfs_reg_wr <= (others => (others => '0'));
      bus_rsp_o  <= rsp_terminate_c;              -- default “not ready”
    elsif rising_edge(clk_i) then
      -- default response every cycle
      bus_rsp_o.ack  <= bus_req_i.stb;
      bus_rsp_o.err  <= '0';
      bus_rsp_o.data <= (others => '0');

      if bus_req_i.stb = '1' then                 -- valid transaction
        if bus_req_i.rw = '1' then                -- WRITE
          case bus_req_i.addr(15 downto 2) is
            when "00000000000000" => cfs_reg_wr(0) <= bus_req_i.data;
            when "00000000000001" => cfs_reg_wr(1) <= bus_req_i.data;
            when "00000000000010" => cfs_reg_wr(2) <= bus_req_i.data;
            when "00000000000011" => cfs_reg_wr(3) <= bus_req_i.data;
            when others           => null;
          end case;
        else                                       -- READ
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
  end process bus_access;

  -- ----------------------------------------------------------------------------
  -- CFS function core : Kyber Montgomery‑reduce in REG[0]
  -- ----------------------------------------------------------------------------
cfs_reg_rd(0) <= std_ulogic_vector(
                   to_unsigned(0, 16) & 
                   unsigned(montgomery_reduce(signed(cfs_reg_wr(0)))(15 downto 0))
                 );

  -- Remaining registers read as zero
  cfs_reg_rd(1) <= (others => '0');
  cfs_reg_rd(2) <= (others => '0');
  cfs_reg_rd(3) <= (others => '0');

end neorv32_cfs_rtl;
