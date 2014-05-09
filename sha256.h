/*
 * sha256.h
 *
 *  Created on: 11.01.2014
 *      Author: mad
 */


#ifndef SHA256_H
#define SHA256_H

#include <string>
#include <inttypes.h>
 


class SHA_256
{
public:
    typedef uint8_t uint8;
    typedef uint32_t uint32;
    typedef uint64_t uint64;
 
    const static uint32 sha256_k[];
    static const unsigned int SHA224_256_BLOCK_SIZE = (512/8);
public:
    void init();
    void update(const unsigned char *message, unsigned int len);
    void final(unsigned char *digest);
    static const unsigned int DIGEST_SIZE = ( 256 / 8);
 
public:
    void transform(const unsigned char *message, unsigned int block_nb);
    unsigned int m_tot_len;
    unsigned int m_len;
    unsigned char m_block[2*SHA224_256_BLOCK_SIZE];
    uint32 m_h[8];
};
 
std::string sha256_str(std::string input);
 
#define SHA2_SHFR(x, n)    (x >> n)
#define SHA2_ROTR(x, n)   ((x >> n) | (x << ((sizeof(x) << 3) - n)))
#define SHA2_ROTL(x, n)   ((x << n) | (x >> ((sizeof(x) << 3) - n)))
#define SHA2_CH(x, y, z)  ((x & y) ^ (~x & z))
#define SHA2_MAJ(x, y, z) ((x & y) ^ (x & z) ^ (y & z))
#define SHA256_F1(x) (SHA2_ROTR(x,  2) ^ SHA2_ROTR(x, 13) ^ SHA2_ROTR(x, 22))
#define SHA256_F2(x) (SHA2_ROTR(x,  6) ^ SHA2_ROTR(x, 11) ^ SHA2_ROTR(x, 25))
#define SHA256_F3(x) (SHA2_ROTR(x,  7) ^ SHA2_ROTR(x, 18) ^ SHA2_SHFR(x,  3))
#define SHA256_F4(x) (SHA2_ROTR(x, 17) ^ SHA2_ROTR(x, 19) ^ SHA2_SHFR(x, 10))
#define SHA2_UNPACK32(x, str)                 \
{                                             \
    *(((unsigned char*)(str)) + 3) = (SHA_256::uint8) ((x)      );       \
    *(((unsigned char*)(str)) + 2) = (SHA_256::uint8) ((x) >>  8);       \
    *(((unsigned char*)(str)) + 1) = (SHA_256::uint8) ((x) >> 16);       \
    *(((unsigned char*)(str)) + 0) = (SHA_256::uint8) ((x) >> 24);       \
}
#define SHA2_PACK32(str, x)                   \
{                                             \
    *(x) =   ((SHA_256::uint32) *(((unsigned char*)(str)) + 3)      )    \
           | ((SHA_256::uint32) *(((unsigned char*)(str)) + 2) <<  8)    \
           | ((SHA_256::uint32) *(((unsigned char*)(str)) + 1) << 16)    \
           | ((SHA_256::uint32) *(((unsigned char*)(str)) + 0) << 24);   \
}






#endif /* SHA256_H_ */
