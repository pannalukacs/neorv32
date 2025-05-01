/**
 * @file test_montgomery.c
 * @brief Minimal test for Montgomery reduction
 */

#include <stdio.h>
#include "kyber_reduce.h"

int main(void)
{
    struct
    {
        sint32 in;
        sint16 exp;
    } tests[] = {
        {0, 0},               // Zero input
        {1, 169},             // One (R^-1 mod q)
        {-1, -169},           // Negative one
        {KYBER_Q, 0},         // Modulus q
        {-KYBER_Q, 0},        // Negative modulus
        {2, 338},             // 2 * R^-1 mod q
        {(sint32)1 << 16, 1}, // R (R * R^-1 = 1 mod q)
        {56088, 1209},        // Example: 123 * 456
    };

    int n = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < n; i++)
    {
        sint16 out = montgomery_reduce(tests[i].in);
        printf("%10d -> %6d (exp %6d) [%s]\n",
               tests[i].in, out, tests[i].exp,
               (out == tests[i].exp) ? "OK" : "FAIL");
    }

    return 0;
}
