#ifndef UTILITY_H
#define UTILITY_H

#include "kyber_common.h"

#ifdef NEORV32

#include <neorv32.h>
#include <stdio.h> // for snprintf

static inline void PRINT(const char *msg)
{
    neorv32_uart0_puts(msg);
}

#else

#include <stdio.h>

static inline void PRINT(const char *msg)
{
    fputs(msg, stdout);
}

#endif

#endif // UTILITY_H
