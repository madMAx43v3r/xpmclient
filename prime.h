/*
 * prime.h
 *
 *  Created on: 03.05.2014
 *      Author: mad
 */

#ifndef PRIME_H_
#define PRIME_H_



#include <gmp.h>
#include <gmpxx.h>
#include "uint256.h"



extern const unsigned int nFractionalBits;
extern unsigned int nTargetInitialLength;
extern unsigned int nTargetMinLength;


enum // prime chain type
{
    PRIME_CHAIN_CUNNINGHAM1 = 1u,
    PRIME_CHAIN_CUNNINGHAM2 = 2u,
    PRIME_CHAIN_BI_TWIN = 3u,
};


class CPrimalityTestParams
{
public:
    // GMP C++ variables
    mpz_class mpzHashFixedMult;
    mpz_class mpzChainOrigin;
    mpz_class mpzOriginMinusOne;
    mpz_class mpzOriginPlusOne;
    mpz_class mpzN;
    mpz_class mpzNMinusOne;
    mpz_class mpzBase;
    mpz_class mpzR;
    mpz_class mpzR2;
    mpz_class mpzE;
    mpz_class mpzFrac;

    // Values specific to a round
    unsigned int nBits;
    unsigned int nCandidateType;

    // Results
    unsigned int nChainLength;

    CPrimalityTestParams()
    {
        nBits = 0;
        nCandidateType = 0;
        nChainLength = 0;
    }
};


unsigned int TargetGetLength(unsigned int nBits);
unsigned int TargetGetFractional(unsigned int nBits);
std::string TargetToString(unsigned int nBits);


inline void mpz_set_uint256(mpz_t r, uint256& u)
{
    mpz_import(r, 32 / sizeof(unsigned long), -1, sizeof(unsigned long), -1, 0, &u);
}


bool ProbablePrimeChainTestFast(const mpz_class& mpzPrimeChainOrigin, CPrimalityTestParams& testParams);













#endif /* PRIME_H_ */
