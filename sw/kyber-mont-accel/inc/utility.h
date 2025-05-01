#ifndef UTILITY_H
#define UTILITY_H

#ifdef NEORV32

#include <neorv32.h>
#include <stdint.h>

// Helper to print signed 32-bit integer
static void print_sint32(int32_t val)
{
    char buf[12]; // enough for -2,147,483,648
    int i = 0;

    if (val < 0)
    {
        neorv32_uart0_putc('-');
        val = -val;
    }

    // Convert number to string in reverse
    do
    {
        buf[i++] = '0' + (val % 10);
        val /= 10;
    } while (val && i < (int)sizeof(buf));

    // Print in correct order
    while (i--)
    {
        neorv32_uart0_putc(buf[i]);
    }
}

// Test print: input, output, expected, status
static inline void print_result(int32_t in, int16_t out, int16_t exp)
{
    print_sint32(in);
    neorv32_uart0_puts(" -> ");
    print_sint32(out);
    neorv32_uart0_puts(" (exp ");
    print_sint32(exp);
    neorv32_uart0_puts(") [");
    neorv32_uart0_puts((out == exp) ? "OK" : "FAIL");
    neorv32_uart0_puts("]\n");
}

#else

#include <stdio.h>
#include <stdarg.h>

#define print_result(in, out, exp) \
    printf("%10d -> %6d (exp %6d) [%s]\n", (in), (out), (exp), ((out) == (exp) ? "OK" : "FAIL"))

#endif

#endif // UTILITY_H
