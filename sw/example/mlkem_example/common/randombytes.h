#ifndef PQCLEAN_RANDOMBYTES_H
#define PQCLEAN_RANDOMBYTES_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stddef.h>

/*
 * Write `n` bytes of random bytes to `buf`
 */
#define randombytes PQCLEAN_randombytes
int PQCLEAN_randombytes(uint8_t *output, size_t n);

#ifdef __cplusplus
}
#endif

#endif /* PQCLEAN_RANDOMBYTES_H */
