#include <neorv32.h>
#include <string.h>
#include "mlkem/api.h"

#define CRYPTO_PUBLICKEYBYTES PQCLEAN_MLKEM512_CLEAN_CRYPTO_PUBLICKEYBYTES
#define CRYPTO_SECRETKEYBYTES PQCLEAN_MLKEM512_CLEAN_CRYPTO_SECRETKEYBYTES
#define CRYPTO_CIPHERTEXTBYTES PQCLEAN_MLKEM512_CLEAN_CRYPTO_CIPHERTEXTBYTES
#define CRYPTO_BYTES PQCLEAN_MLKEM512_CLEAN_CRYPTO_BYTES

#define crypto_kem_keypair PQCLEAN_MLKEM512_CLEAN_crypto_kem_keypair
#define crypto_kem_enc PQCLEAN_MLKEM512_CLEAN_crypto_kem_enc
#define crypto_kem_dec PQCLEAN_MLKEM512_CLEAN_crypto_kem_dec

#define BAUD_RATE 19200

int main(void)
{
    neorv32_rte_setup();              
    neorv32_uart0_setup(BAUD_RATE, 0); 

    neorv32_uart0_puts("Starting ML-KEM Kyber512 test...\n");

    uint8_t pk[CRYPTO_PUBLICKEYBYTES];
    uint8_t sk[CRYPTO_SECRETKEYBYTES];
    uint8_t ct[CRYPTO_CIPHERTEXTBYTES];
    uint8_t ss[CRYPTO_BYTES];
    uint8_t ss_recovered[CRYPTO_BYTES];

    neorv32_uart0_puts("Mem allocated\n");

    crypto_kem_keypair(pk, sk);
    neorv32_uart0_puts("Keypair done\n");

    crypto_kem_enc(ct, ss, pk);
    neorv32_uart0_puts("Enc done\n");

    crypto_kem_dec(ss_recovered, ct, sk);
    neorv32_uart0_puts("Dec done\n");

    if (memcmp(ss, ss_recovered, CRYPTO_BYTES) == 0)
    {
        neorv32_uart0_puts("ML-KEM Kyber512: SUCCESS!\n");
    }
    else
    {
        neorv32_uart0_puts("ML-KEM Kyber512: FAILURE!\n");
    }

    return 0;
}
