#ifndef PQCLEAN_MLKEM512_CLEAN_REDUCE_H
#define PQCLEAN_MLKEM512_CLEAN_REDUCE_H
#include "params.h"
#include <stdint.h>

#define MONT (-1044) // 2^16 mod q
#define QINV (-3327) // q^-1 mod 2^16


int16_t PQCLEAN_MLKEM512_CLEAN_barrett_reduce(int16_t a);
#ifdef NEORV32
uint16 PQCLEAN_MLKEM512_CLEAN_montgomery_reduce(uint32 a);
#else
int16_t PQCLEAN_MLKEM512_CLEAN_montgomery_reduce(int32_t a);
#endif
#endif
