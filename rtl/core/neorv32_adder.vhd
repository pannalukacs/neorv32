-- ================================================================================ --
-- NEORV32 SoC - Custom Functions Subsystem (ADDER)                                   --
-- -------------------------------------------------------------------------------- --
-- Intended for tightly-coupled, application-specific custom co-processors. This    --
-- module provides up to 64x 32-bit memory-mapped interface registers, one CPU      --
-- interrupt request signal and custom IO conduits for processor-external or chip-  --
-- external interface.                                                              --
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

entity neorv32_adder is
  generic (
    ADDER_CONFIG   : std_ulogic_vector(31 downto 0); -- custom ADDER configuration generic
    ADDER_IN_SIZE  : natural; -- size of ADDER input conduit in bits
    ADDER_OUT_SIZE : natural  -- size of ADDER output conduit in bits
  );
  port (
    clk_i       : in  std_ulogic; -- global clock line
    rstn_i      : in  std_ulogic; -- global reset line, low-active, use as async
    bus_req_i   : in  bus_req_t; -- bus request
    bus_rsp_o   : out bus_rsp_t; -- bus response
    clkgen_en_o : out std_ulogic; -- enable clock generator
    clkgen_i    : in  std_ulogic_vector(7 downto 0); -- "clock" inputs
    irq_o       : out std_ulogic; -- interrupt request
    adder_in_i    : in  std_ulogic_vector(ADDER_IN_SIZE-1 downto 0); -- custom inputs
    adder_out_o   : out std_ulogic_vector(ADDER_OUT_SIZE-1 downto 0) -- custom outputs
  );
end neorv32_adder;

architecture neorv32_adder_rtl of neorv32_adder is

  -- default ADDER interface registers --
  type adder_regs_t is array (0 to 3) of std_ulogic_vector(31 downto 0); -- just implement 4 registers for this example
  signal adder_reg_wr : adder_regs_t; -- interface registers for WRITE accesses
  signal adder_reg_rd : adder_regs_t; -- interface registers for READ accesses

begin

  -- ADDER Generics ---------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- In it's default version the ADDER provides three configuration generics:
  -- > ADDER_IN_SIZE  - configures the size (in bits) of the ADDER input conduit adder_in_i
  -- > ADDER_OUT_SIZE - configures the size (in bits) of the ADDER output conduit adder_out_o
  -- > ADDER_CONFIG   - is a blank 32-bit generic. It is intended as a "generic conduit" to propagate
  --                  custom configuration flags from the top entity down to this module.


  -- ADDER IOs --------------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- By default, the ADDER provides two IO signals (adder_in_i and adder_out_o) that are available at the processor's top entity.
  -- These are intended as "conduits" to propagate custom signals from this module and the processor top entity.
  --
  -- If the CFU output signals are to be used outside the chip, it is recommended to register these signals.

  adder_out_o <= (others => '0'); -- not used for this minimal example


  -- Reset System ---------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- The ADDER can be reset using the global rstn_i signal. This signal should be used as asynchronous reset and is active-low.
  -- Note that rstn_i can be asserted by a processor-external reset, the on-chip debugger and also by the watchdog.
  --
  -- Most default peripheral devices of the NEORV32 do NOT use a dedicated hardware reset at all. Instead, these units are
  -- reset by writing ZERO to a specific "control register" located right at the beginning of the device's address space
  -- (so this register is cleared at first). The crt0 start-up code writes ZERO to every single address in the processor's
  -- IO space - including the ADDER. Make sure that this initial clearing does not cause any unintended ADDER actions.


  -- Clock System ---------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- The processor top unit implements a clock generator providing 8 "derived clocks".
  -- Actually, these signals should not be used as direct clock signals, but as *clock enable* signals.
  -- clkgen_i is always synchronous to the main system clock (clk_i).
  --
  -- The following clock dividers are available:
  -- > clkgen_i(clk_div2_c)    -> MAIN_CLK/2
  -- > clkgen_i(clk_div4_c)    -> MAIN_CLK/4
  -- > clkgen_i(clk_div8_c)    -> MAIN_CLK/8
  -- > clkgen_i(clk_div64_c)   -> MAIN_CLK/64
  -- > clkgen_i(clk_div128_c)  -> MAIN_CLK/128
  -- > clkgen_i(clk_div1024_c) -> MAIN_CLK/1024
  -- > clkgen_i(clk_div2048_c) -> MAIN_CLK/2048
  -- > clkgen_i(clk_div4096_c) -> MAIN_CLK/4096
  --
  -- For instance, if you want to drive a clock process at MAIN_CLK/8 clock speed you can use the following construct:
  --
  --   if (rstn_i = '0') then -- async and low-active reset (if required at all)
  --   ...
  --   elsif rising_edge(clk_i) then -- always use the main clock for all clock processes
  --     if (clkgen_i(clk_div8_c) = '1') then -- the div8 "clock" is actually a clock enable
  --       ...
  --     end if;
  --   end if;
  --
  -- The clkgen_i input clocks are available when at least one IO/peripheral device (for example UART0) requires the clocks
  -- generated by the clock generator. The ADDER can enable the clock generator by itself by setting the clkgen_en_o signal high.
  -- The ADDER cannot ensure to deactivate the clock generator by setting the clkgen_en_o signal low as other peripherals might
  -- still keep the generator activated. Make sure to deactivate the ADDER's clkgen_en_o if no clocks are required in here to
  -- reduce dynamic power consumption.

  clkgen_en_o <= '0'; -- not used for this minimal example


  -- Interrupt ------------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- The ADDER features a single interrupt signal, which is connected to the CPU's "fast interrupt" channel 1 (FIRQ1).
  -- The according CPU interrupt becomes pending as long as <irq_o> is high.

  irq_o <= '0'; -- not used for this minimal example


  -- Read/Write Access ----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- Here we are reading/writing from/to the interface registers of the module and generate the CPU access handshake (bus response).
  --
  -- The ADDER provides up to 64kB of memory-mapped address space (16 address bits, byte-addressing) that can be used for custom
  -- memories and interface registers. If the complete 16-bit address space is not required, only the minimum LSBs required for
  -- address decoding can be used. In this case, however, the implemented registers are replicated (several times) across the ADDER
  -- address space.
  --
  -- Following the interface protocol, each read or write access has to be acknowledged in the following cycle using the ack_o
  -- signal (or even later if the module needs additional time). If no ACK is generated at all, the bus access will time out
  -- and cause a bus access fault exception. The current CPU privilege level is available via the 'priv_i' signal (0 = user mode,
  -- 1 = machine mode), which can be used to constrain access to certain registers or features to privileged software only.
  --
  -- This module also provides an optional ERROR signal to indicate a faulty access operation (for example when accessing an
  -- unused, read-only or "locked" ADDER register address). This signal may only be set when the module is actually accessed
  -- and is set INSTEAD of the ACK signal. Setting the ERR signal will raise a bus access exception with a "Device Error" qualifier
  -- that can be handled by the application software. Note that the current privilege level should not be exposed to software to
  -- maintain full virtualization. Hence, ADDER-based "privilege escalation" should trigger a bus access exception (e.g. by setting 'err_o').
  --
  -- Host access example: Read and write access to the interface registers + bus transfer acknowledge. This example only
  -- implements four physical r/w register (the four lowest ADDER registers). The remaining addresses of the ADDER are not associated
  -- with any physical registers - any access to those is simply ignored but still acknowledged. Only full-word write accesses are
  -- supported (and acknowledged) by this example. Sub-word write access will not alter any ADDER register state and will cause
  -- a "bus store access" exception (with a "Device Timeout" qualifier as not ACK is generated in that case).

  bus_access: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      adder_reg_wr(0) <= (others => '0');
      adder_reg_wr(1) <= (others => '0');
      adder_reg_wr(2) <= (others => '0');
      adder_reg_wr(3) <= (others => '0');
      bus_rsp_o       <= rsp_terminate_c;
    elsif rising_edge(clk_i) then -- synchronous interface for read and write accesses
      -- transfer/access acknowledge --
      bus_rsp_o.ack <= bus_req_i.stb;

      -- tie to zero if not explicitly used --
      bus_rsp_o.err <= '0';

      -- defaults --
      bus_rsp_o.data <= (others => '0'); -- the output HAS TO BE ZERO if there is no actual (read) access

      -- bus access --
      if (bus_req_i.stb = '1') then -- valid access cycle, STB is high for one cycle

        -- write access (word-wise) --
        if (bus_req_i.rw = '1') then
          if (bus_req_i.addr(15 downto 2) = "00000000000000") then -- 16-bit byte address = 14-bit word address
            adder_reg_wr(0) <= bus_req_i.data;
          end if;
          if (bus_req_i.addr(15 downto 2) = "00000000000001") then
            adder_reg_wr(1) <= bus_req_i.data;
          end if;
          if (bus_req_i.addr(15 downto 2) = "00000000000010") then
            adder_reg_wr(2) <= bus_req_i.data;
          end if;
          if (bus_req_i.addr(15 downto 2) = "00000000000011") then
            adder_reg_wr(3) <= bus_req_i.data;
          end if;

        -- read access (word-wise) --
        else
          case bus_req_i.addr(15 downto 2) is -- 16-bit byte address = 14-bit word address
            when "00000000000000" => bus_rsp_o.data <= adder_reg_rd(0);
            when "00000000000001" => bus_rsp_o.data <= adder_reg_rd(1);
            when "00000000000010" => bus_rsp_o.data <= adder_reg_rd(2);
            when "00000000000011" => bus_rsp_o.data <= adder_reg_rd(3);
            when others           => bus_rsp_o.data <= (others => '0');
          end case;
        end if;

      end if;
    end if;
  end process bus_access;


  -- ADDER Function Core ----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------

  -- This is where the actual functionality can be implemented.
  -- The logic below is just a very simple example that transforms data
  -- from an input register into data in an output register.

  adder_reg_rd(2) <= std_ulogic_vector(unsigned(adder_reg_wr(0)) + unsigned(adder_reg_wr(1)));
  adder_reg_rd(0) <= (others => '0');
  adder_reg_rd(1) <= (others => '0');
  adder_reg_rd(3) <= (others => '0');

end neorv32_adder_rtl;
