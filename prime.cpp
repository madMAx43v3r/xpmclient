/*
 * prime.cpp
 *
 *  Created on: 03.05.2014
 *      Author: mad
 */



#include "prime.h"



const unsigned int nFractionalBits = 24;
unsigned int nTargetInitialLength = 7; // initial chain length target
unsigned int nTargetMinLength = 6; // minimum chain length target
static const unsigned int TARGET_FRACTIONAL_MASK = (1u<<nFractionalBits) - 1;
static const unsigned int TARGET_LENGTH_MASK = ~TARGET_FRACTIONAL_MASK;


unsigned int TargetGetLength(unsigned int nBits)
{
    return ((nBits & TARGET_LENGTH_MASK) >> nFractionalBits);
}

unsigned int TargetGetFractional(unsigned int nBits)
{
    return (nBits & TARGET_FRACTIONAL_MASK);
}

std::string TargetToString(unsigned int nBits)
{
    char tmp[20];
	sprintf(tmp, "%02x.%06x", TargetGetLength(nBits), TargetGetFractional(nBits));
	return std::string(tmp);
}

static void TargetIncrementLength(unsigned int& nBits)
{
    nBits += (1 << nFractionalBits);
}

static void TargetDecrementLength(unsigned int& nBits)
{
    if (TargetGetLength(nBits) > nTargetMinLength)
        nBits -= (1 << nFractionalBits);
}


static const mpz_class mpzTwo = 2;


// Check Fermat probable primality test (2-PRP): 2 ** (n-1) = 1 (mod n)
// true: n is probable prime
// false: n is composite; set fractional length in the nLength output
static bool FermatProbablePrimalityTestFast(const mpz_class& n, unsigned int& nLength, CPrimalityTestParams& testParams, bool fFastFail = false)
{
    mpz_class& mpzNMinusOne = testParams.mpzNMinusOne;
    mpz_class& mpzE = testParams.mpzE;
    mpz_class& mpzBase = testParams.mpzBase;
    mpz_class& mpzR = testParams.mpzR;
    mpz_class& mpzR2 = testParams.mpzR2;
    mpz_class& mpzFrac = testParams.mpzFrac;

    mpzNMinusOne = n - 1;
    unsigned int nTrailingZeros = mpz_scan1(mpzNMinusOne.get_mpz_t(), 0);
    if ((nTrailingZeros > 9))
        nTrailingZeros = 9;
    // Euler's criterion: 2 ** ((n-1)/2) needs to be either -1 or 1 (mod n)
    mpz_tdiv_q_2exp(mpzE.get_mpz_t(), mpzNMinusOne.get_mpz_t(), nTrailingZeros);
    unsigned int nShiftCount = (1U << (nTrailingZeros - 1)) - 1;
    mpzBase = mpzTwo << nShiftCount;
    mpz_powm(mpzR.get_mpz_t(), mpzBase.get_mpz_t(), mpzE.get_mpz_t(), n.get_mpz_t());
    if ((mpzR == 1 || mpzR == mpzNMinusOne))
        return true;
    if ((fFastFail))
        return false;
    // Failed test, calculate fractional length
    mpzR2 = mpzR * mpzR;
    mpzR = mpzR2 % n; // derive Fermat test remainder

    mpzFrac = n - mpzR;
    mpzFrac <<= nFractionalBits;
    mpzFrac /= n;
    unsigned int nFractionalLength = mpzFrac.get_ui();
    if ((nFractionalLength >= (1 << nFractionalBits)))
        return false;
    nLength = (nLength & TARGET_LENGTH_MASK) | nFractionalLength;
    return false;
}

// Test probable primality of n = 2p +/- 1 based on Euler, Lagrange and Lifchitz
// fSophieGermain:
// true: n = 2p+1, p prime, aka Cunningham Chain of first kind
// false: n = 2p-1, p prime, aka Cunningham Chain of second kind
// Return values
// true: n is probable prime
// false: n is composite; set fractional length in the nLength output
static bool EulerLagrangeLifchitzPrimalityTestFast(const mpz_class& n, bool fSophieGermain, unsigned int& nLength, CPrimalityTestParams& testParams, bool fFastFail = false)
{
    mpz_class& mpzNMinusOne = testParams.mpzNMinusOne;
    mpz_class& mpzE = testParams.mpzE;
    mpz_class& mpzBase = testParams.mpzBase;
    mpz_class& mpzR = testParams.mpzR;
    mpz_class& mpzR2 = testParams.mpzR2;
    mpz_class& mpzFrac = testParams.mpzFrac;

    mpzNMinusOne = n - 1;
    unsigned int nTrailingZeros = mpz_scan1(mpzNMinusOne.get_mpz_t(), 0);
    if ((nTrailingZeros > 9))
        nTrailingZeros = 9;
    mpz_tdiv_q_2exp(mpzE.get_mpz_t(), mpzNMinusOne.get_mpz_t(), nTrailingZeros);
    unsigned int nShiftCount = (1U << (nTrailingZeros - 1)) - 1;
    mpzBase = mpzTwo << nShiftCount;
    mpz_powm(mpzR.get_mpz_t(), mpzBase.get_mpz_t(), mpzE.get_mpz_t(), n.get_mpz_t());
    unsigned int nMod8 = n.get_ui() % 8;
    bool fPassedTest = false;
    if (fSophieGermain && nMod8 == 7) // Euler & Lagrange
        fPassedTest = (mpzR == 1);
    else if (fSophieGermain && nMod8 == 3) // Lifchitz
        fPassedTest = (mpzR == mpzNMinusOne);
    else if (!fSophieGermain && nMod8 == 5) // Lifchitz
        fPassedTest = (mpzR == mpzNMinusOne);
    else if (!fSophieGermain && nMod8 == 1) // LifChitz
        fPassedTest = (mpzR == 1);
    else
        return false;

    if ((fPassedTest))
        return true;
    if ((fFastFail))
        return false;

    // Failed test, calculate fractional length
    mpzR2 = mpzR * mpzR;
    mpzR = mpzR2 % n; // derive Fermat test remainder

    mpzFrac = n - mpzR;
    mpzFrac <<= nFractionalBits;
    mpzFrac /= n;
    unsigned int nFractionalLength = mpzFrac.get_ui();

    if ((nFractionalLength >= (1 << nFractionalBits)))
        return false;
    nLength = (nLength & TARGET_LENGTH_MASK) | nFractionalLength;
    return false;
}

// Test Probable Cunningham Chain for: n
// fSophieGermain:
// true - Test for Cunningham Chain of first kind (n, 2n+1, 4n+3, ...)
// false - Test for Cunningham Chain of second kind (n, 2n-1, 4n-3, ...)
static void ProbableCunninghamChainTestFast(const mpz_class& n, bool fSophieGermain, unsigned int& nProbableChainLength, CPrimalityTestParams& testParams)
{
    nProbableChainLength = 0;

    // Fermat test for n first
    if (!FermatProbablePrimalityTestFast(n, nProbableChainLength, testParams, true))
        return;

    // Euler-Lagrange-Lifchitz test for the following numbers in chain
    mpz_class &N = testParams.mpzN;
    N = n;
    for (unsigned int nChainSeq = 1; true; nChainSeq++)
    {
        TargetIncrementLength(nProbableChainLength);
        N <<= 1;
        N += (fSophieGermain? 1 : (-1));
        bool fFastFail = nChainSeq < 4;
        if (!EulerLagrangeLifchitzPrimalityTestFast(N, fSophieGermain, nProbableChainLength, testParams, fFastFail))
            break;
    }
}

// Test Probable BiTwin Chain for: mpzOrigin
// Test the numbers in the optimal order for any given chain length
// Gives the correct length of a BiTwin chain even for short chains
static void ProbableBiTwinChainTestFast(const mpz_class& mpzOrigin, unsigned int& nProbableChainLength, CPrimalityTestParams& testParams)
{
    mpz_class& mpzOriginMinusOne = testParams.mpzOriginMinusOne;
    mpz_class& mpzOriginPlusOne = testParams.mpzOriginPlusOne;
    nProbableChainLength = 0;

    // Fermat test for origin-1 first
    mpzOriginMinusOne = mpzOrigin - 1;
    if (!FermatProbablePrimalityTestFast(mpzOriginMinusOne, nProbableChainLength, testParams, true))
        return;
    TargetIncrementLength(nProbableChainLength);

    // Fermat test for origin+1
    mpzOriginPlusOne = mpzOrigin + 1;
    if (!FermatProbablePrimalityTestFast(mpzOriginPlusOne, nProbableChainLength, testParams, true))
        return;
    TargetIncrementLength(nProbableChainLength);

    // Euler-Lagrange-Lifchitz test for the following numbers in chain
    for (unsigned int nChainSeq = 2; true; nChainSeq += 2)
    {
        mpzOriginMinusOne <<= 1;
        mpzOriginMinusOne++;
        bool fFastFail = nChainSeq < 4;
        if (!EulerLagrangeLifchitzPrimalityTestFast(mpzOriginMinusOne, true, nProbableChainLength, testParams, fFastFail))
            break;
        TargetIncrementLength(nProbableChainLength);

        mpzOriginPlusOne <<= 1;
        mpzOriginPlusOne--;
        if (!EulerLagrangeLifchitzPrimalityTestFast(mpzOriginPlusOne, false, nProbableChainLength, testParams, fFastFail))
            break;
        TargetIncrementLength(nProbableChainLength);
    }
}

// Test probable prime chain for: nOrigin
// Return value:
// true - Probable prime chain found (one of nChainLength meeting target)
// false - prime chain too short (none of nChainLength meeting target)
bool ProbablePrimeChainTestFast(const mpz_class& mpzPrimeChainOrigin, CPrimalityTestParams& testParams)
{
    const unsigned int nBits = testParams.nBits;
    const unsigned int nCandidateType = testParams.nCandidateType;
    mpz_class& mpzOriginMinusOne = testParams.mpzOriginMinusOne;
    mpz_class& mpzOriginPlusOne = testParams.mpzOriginPlusOne;
    unsigned int& nChainLength = testParams.nChainLength;
    nChainLength = 0;

    // Test for Cunningham Chain of first kind
    if (nCandidateType == 0)
    {
        mpzOriginMinusOne = mpzPrimeChainOrigin - 1;
        ProbableCunninghamChainTestFast(mpzOriginMinusOne, true, nChainLength, testParams);
    }
    else if (nCandidateType == 1)
    {
        // Test for Cunningham Chain of second kind
        mpzOriginPlusOne = mpzPrimeChainOrigin + 1;
        ProbableCunninghamChainTestFast(mpzOriginPlusOne, false, nChainLength, testParams);
    }
    else if (nCandidateType == 2)
    {
        ProbableBiTwinChainTestFast(mpzPrimeChainOrigin, nChainLength, testParams);
    }

    return (nChainLength >= nBits);
}










