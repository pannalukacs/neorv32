/**
 * @file test_montgomery.c
 * @brief Minimal test for Montgomery reduction
 */

#include "kyber_reduce.h"
#include "utility.h"
#ifdef NEORV32
#define BAUD_RATE 19200
#endif

int main(void)
{
#ifdef NEORV32
    neorv32_rte_setup();
    neorv32_uart0_setup(BAUD_RATE, 0);
#endif
    PRINT("Running Montgomery reduction tests\n");

    struct
    {
        sint32 in;
        sint16 exp;
    } tests[] = {
        {0, 0}, {1, 169}, {-1, -169}, {KYBER_Q, 0}, {-KYBER_Q, 0}, {2, 338}, {(sint32)1 << 16, 1}, {56088, 1209}};

    int failed = 0;
    char line[64];
    int n = sizeof(tests) / sizeof(tests[0]);

    for (int i = 0; i < n; i++)
    {
        sint16 out = montgomery_reduce(tests[i].in);
        if (out == tests[i].exp)
        {
            PRINT(".");
        }
        else
        {
            failed = 1;
            snprintf(line, sizeof(line),
                     "\nFAIL: test %d -> %d (expected %d)\n",
                     i, out, tests[i].exp);
            PRINT(line);
        }
    }

    if (!failed)
    {
        PRINT("\nAll tests passed.\n");
    }

    return failed;
}
