#ifndef UTILITY_H
#define UTILITY_H

#ifdef NEORV32
#include <neorv32.h>

static inline void print(const char *fmt, ...)
{
    char buf[128];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    neorv32_uart0_puts(buf);
}

#else
#include <stdio.h>
#include <stdarg.h>

static inline void print(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
}

#endif

#endif // UTILITY_H