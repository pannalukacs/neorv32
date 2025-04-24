// ================================================================================ //
// The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              //
// Copyright (c) NEORV32 contributors.                                              //
// Copyright (c) 2020 - 2025 Stephan Nolting. All rights reserved.                  //
// Licensed under the BSD-3-Clause license, see LICENSE for details.                //
// SPDX-License-Identifier: BSD-3-Clause                                            //
// ================================================================================ //

/**
 * @file neorv32_adder.h
 * @brief Custom Functions Subsystem (ADDER) HW driver header file.
 *
 * @warning There are no "real" ADDER driver functions available here, because these functions are defined by the actual hardware.
 * @warning The ADDER designer has to provide the actual driver functions.
 */

#ifndef NEORV32_ADDER_H
#define NEORV32_ADDER_H

#include <stdint.h>


/**********************************************************************//**
 * @name IO Device: Custom Functions Subsystem (ADDER)
 **************************************************************************/
/**@{*/
/** ADDER module prototype */
typedef volatile struct __attribute__((packed,aligned(4))) {
  uint32_t REG[(64*1024)/4]; /**< ADDER registers, user-defined */
} neorv32_adder_t;

/** ADDER module hardware handle (#neorv32_adder_t) */
#define NEORV32_ADDER ((neorv32_adder_t*) (NEORV32_ADDER_BASE))
/**@}*/


/**********************************************************************//**
 * @name Prototypes
 **************************************************************************/
/**@{*/
int neorv32_adder_available(void);
uint32_t neorv32_adder_add(uint32_t a, uint32_t b);
/**@}*/


#endif // NEORV32_ADDER_H
