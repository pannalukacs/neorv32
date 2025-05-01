/**
 * @file kyber_common.h
 * @brief Common types and parameters for Kyber Montgomery reduction
 */

#ifndef KYBER_COMMON_H
#define KYBER_COMMON_H

#include <stdint.h>

/* Types used in Montgomery reduction */
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef int16_t sint16;
typedef int32_t sint32;
typedef int64_t sint64;

/* Parameters needed for Montgomery reduction */
#define KYBER_Q 3329u

/* Constants for reduction */
#define QINV (-3327) /* q^-1 mod 2^16 */

#endif /* KYBER_COMMON_H */