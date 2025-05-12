/**
 * @file kyber_reduce.h
 * @brief Modular reduction functions for Kyber
 */

#ifndef KYBER_REDUCE_H
#define KYBER_REDUCE_H

#include "kyber_common.h"

#ifdef NEORV32

#include <neorv32.h>

uint16 montgomery(uint32 x);

// #else

/**
 * @brief Montgomery reduction
 *
 * Computes a 16-bit integer congruent to a * R^-1 mod q, where R=2^16
 *
 * @param a Input integer (range: -q*2^15 to q*2^15-1)
 * @return Integer in range (-q+1 to q-1)
 */
sint16 montgomery_reduce(sint32 a);

/* For backwards compatibility */
#define FsmSw_Kyber_montgomery_reduce montgomery_reduce

#endif /* KYBER_REDUCE_H */
#endif