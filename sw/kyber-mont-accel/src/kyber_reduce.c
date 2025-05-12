/**
 * @file kyber_reduce.c
 * @brief Implementation of reduction functions
 */

#include "kyber_reduce.h"

#ifdef NEORV32

uint16 montgomery(uint32 x)
{
    NEORV32_CFS->REG[0] = x;

    return (uint16)NEORV32_CFS->REG[0];
}

// #else

sint16 montgomery_reduce(sint32 a)
{
    sint16 t = 0;

    // Step 1: Compute t = a * q^-1 mod 2^16
    t = (sint16)a * QINV;

    // Step 2: Compute (a - t*q) >> 16
    t = (sint16)((uint16)(((uint32)a - ((uint32)t * KYBER_Q)) >> 16));

    return t;
}

#endif