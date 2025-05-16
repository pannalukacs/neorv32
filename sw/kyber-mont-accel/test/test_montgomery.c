/**
 * @file test_montgomery.c
 * @brief Minimal test for Montgomery reduction
 */

#include "kyber_reduce.h"
#include "utility.h"
#ifdef NEORV32
#define BAUD_RATE 19200
#endif

int cfs_done = 0;

#ifdef NEORV32
void cfs_irq_handler(void) {
    neorv32_uart0_printf("CFS_FIRQ = %d\n", CFS_FIRQ_ENABLE);
    cfs_done = 1;
}
#endif


int main(void)
{
#ifdef NEORV32
    neorv32_rte_setup();
    neorv32_uart0_setup(BAUD_RATE, 0);
    neorv32_rte_handler_install(CFS_RTE_ID, cfs_irq_handler);
    neorv32_cpu_csr_set(CSR_MIE, 1 << CFS_FIRQ_ENABLE);
    neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE);
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
    uint32_t startTime, stopTime;

    // startTime = neorv32_cpu_csr_read(CSR_MCYCLE);
    // for (int i = 0; i < n; i++)
    // {
    //     sint16 out = montgomery_reduce(tests[i].in);
    //     if (out == tests[i].exp)
    //     {   
    //         PRINT(".");
    //     }
    //     else
    //     {
    //         failed = 1;
    //         snprintf(line, sizeof(line),
    //                  "\nFAIL: test %d -> %d (expected %d)\n",
    //                  i, out, tests[i].exp);
    //         PRINT(line);
    //     }
    // }
    // stopTime = neorv32_cpu_csr_read(CSR_MCYCLE);
    // neorv32_uart0_printf("\n Default execution: %d cyc\n", stopTime - startTime);

    // if (!failed)
    // {
    //     PRINT("\nAll tests passed.\n");
    // }

    startTime = neorv32_cpu_csr_read(CSR_MCYCLE);
    for (int i = 0; i < n; i++)
    {
        cfs_done = 0;
        // sint16 out = montgomery(tests[i].in);
        NEORV32_CFS->REG[0] = (uint32_t)tests[i].in;
        while (!cfs_done) {
            neorv32_uart0_printf("%d\n", cfs_done);
        };
        sint16 out = (sint16)(NEORV32_CFS->REG[0]);

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
    stopTime = neorv32_cpu_csr_read(CSR_MCYCLE);
    neorv32_uart0_printf("\n CFS execution (IRQ): %d cyc\n", stopTime - startTime);

    if (!failed)
    {
        PRINT("\nAll tests passed.\n");
    }

    return failed;
}
