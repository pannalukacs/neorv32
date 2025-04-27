// SPDX-License-Identifier: MIT
// Compatible randombytes() implementation for NEORV32
// Based on TRNG hardware, adapted to match PQClean expectations.

#include "randombytes.h"
#include <neorv32.h>

#ifndef PQCLEAN_randombytes
#define PQCLEAN_randombytes PQCLEAN_randombytes
#endif

/**
 * @brief Fills the buffer `output` with `n` random bytes using NEORV32 TRNG.
 *
 * @param[out] output Destination buffer.
 * @param[in] n Number of bytes to generate.
 * @return 0 on success, -1 on error (e.g., if TRNG is not available).
 */
int PQCLEAN_randombytes(uint8_t *output, size_t n) {
    if (output == NULL) {
        return -1;
    }

    if (neorv32_trng_available() == 0) {
        return -1; // TRNG not synthesized
    }

    // Enable TRNG (if not already)
    neorv32_trng_enable();
    neorv32_trng_fifo_clear(); // discard old data

    for (size_t i = 0; i < n; i++) {
        // Wait until new random byte is available
        while (neorv32_trng_get(&output[i]) != 0) {
            // spinlock wait
        }
    }

    return 0;
}
