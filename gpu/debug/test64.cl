

#define rol63(l) rotate(l, 63UL)
#define rol56(l) rotate(l, 56UL)
#define rol45(l) rotate(l, 45UL)
#define rol3(l) rotate(l, 3UL)
#define rol36(l) rotate(l, 36UL)
#define rol30(l) rotate(l, 30UL)
#define rol25(l) rotate(l, 25UL)
#define rol50(l) rotate(l, 50UL)
#define rol46(l) rotate(l, 46UL)
#define rol23(l) rotate(l, 23UL)



__kernel void test_32(__global const uint* asrc, __global uint* csrc) {
	
	const uint id = get_global_id(0);
	
	uint a = asrc[id];
	
	uint c = rotate(a, 3u);
	
	csrc[id] = c;
	
}

__kernel void test_64(__global const ulong* asrc, __global ulong* csrc) {
	
	const uint id = get_global_id(0);
	
	ulong a = asrc[id];
	
	ulong c = rol3(a);
	//ulong c = a >> 3;
	
	csrc[id] = c;
	
}


uint2 rot64(uint2 a, uint r){
	
	uint c = a.y;
	
	a.y = (a.y << r) | (a.x >> (32u-r));
	
	a.x = (a.x << r) | (c >> (32u-r));
	
	return a;
	
}

uint2 rotr64(uint2 a, uint r){
	
	uint c = a.x;
	
	a.x = (a.x >> r) | (a.y << (32u-r));
	
	a.y = (a.y >> r) | (c << (32u-r));
	
	return a;
	
}

uint2 shl64(uint2 a, uint r){
	
	a.y = (a.y << r) | (a.x >> (32u-r));
	
	a.x = (a.x << r);
	
	return a;
	
}

uint2 shl64_2(uint2 a, uint r){
	
	ulong b = as_ulong(a);
	b <<= r;
	
	return as_uint2(b);
	
}

uint2 shr64(uint2 a, uint r){
	
	a.x = (a.x >> r) | (a.y << (32u-r));
	
	a.y = (a.y >> r);
	
	return a;
	
}

uint2 shr64_2(uint2 a, uint r){
	
	ulong b = as_ulong(a);
	b >>= r;
	
	return as_uint2(b);
	
}

__kernel void test_64_2(__global const uint2* asrc, __global uint2* csrc) {
	
	const uint id = get_global_id(0);
	
	uint2 a = asrc[id];
	
	uint2 c = rotr64(a, 3);
	//uint2 c = shr64_2(a, 3);
	
	csrc[id] = c;
	
}


ulong rotlong(ulong a, uint r){
	
	uint2 b;
	b.x = a;
	b.y = a >> 32;
	
	uint2 c = rot64(b, r);
	
	ulong d = c.y;
	d <<= 32;
	d |= c.x;
	
	return d;
	
}

__kernel void test_64_3(__global const ulong* asrc, __global ulong* csrc) {
	
	const uint id = get_global_id(0);
	
	ulong a = asrc[id];
	
	ulong c = rotlong(a, 3);
	
	csrc[id] = c;
	
}


__kernel void test_64_4(__global const ulong* asrc, __global const ulong* bsrc, __global ulong* csrc) {
	
	const uint id = get_global_id(0);
	
	ulong a = asrc[id];
	ulong b = bsrc[id];
	
	ulong c = a+b;
	
	csrc[id] = c;
	
}




/*
Momentum PoW OpenCL implementation
by reorder, 2014
*/

#define KEYHASH_CAPACITY (1<<24)

#define SWAP32(a) (as_uint(as_uchar4(a).wzyx))

#define rol63(l) rotate(l, 63UL)
#define rol56(l) rotate(l, 56UL)
#define rol45(l) rotate(l, 45UL)
#define rol3(l) rotate(l, 3UL)
#define rol36(l) rotate(l, 36UL)
#define rol30(l) rotate(l, 30UL)
#define rol25(l) rotate(l, 25UL)
#define rol50(l) rotate(l, 50UL)
#define rol46(l) rotate(l, 46UL)
#define rol23(l) rotate(l, 23UL)

#define S0(x) (rol63(x) ^ rol56(x) ^ (x >> 7))
#define S1(x) (rol45(x) ^ rol3(x) ^ (x >> 6))

#define S2(x) (rol36(x) ^ rol30(x) ^ rol25(x))
#define S3(x) (rol50(x) ^ rol46(x) ^ rol23(x))

#define F0(y, x, z) bitselect(z, y, z ^ x)
#define F1(x, y, z) bitselect(z, y, x)

#define P(a,b,c,d,e,f,g,h,x,K) \
{ \
temp1 = h + S3(e) + F1(e,f,g) + K + x; \
d += temp1; h = temp1 + S2(a) + F0(a,b,c); \
}

#define R0 (W0 = S1(W14) + W9 + S0(W1) + W0)
#define R1 (W1 = S1(W15) + W10 + S0(W2) + W1)
#define R2 (W2 = S1(W0) + W11 + S0(W3) + W2)
#define R3 (W3 = S1(W1) + W12 + S0(W4) + W3)
#define R4 (W4 = S1(W2) + W13 + S0(W5) + W4)
#define R5 (W5 = S1(W3) + W14 + S0(W6) + W5)
#define R6 (W6 = S1(W4) + W15 + S0(W7) + W6)
#define R7 (W7 = S1(W5) + W0 + S0(W8) + W7)
#define R8 (W8 = S1(W6) + W1 + S0(W9) + W8)
#define R9 (W9 = S1(W7) + W2 + S0(W10) + W9)
#define R10 (W10 = S1(W8) + W3 + S0(W11) + W10)
#define R11 (W11 = S1(W9) + W4 + S0(W12) + W11)
#define R12 (W12 = S1(W10) + W5 + S0(W13) + W12)
#define R13 (W13 = S1(W11) + W6 + S0(W14) + W13)
#define R14 (W14 = S1(W12) + W7 + S0(W15) + W14)
#define R15 (W15 = S1(W13) + W8 + S0(W0) + W15)

#define R0_16 (W0 = S0(W1) + W0)
#define R1_17 (W1 = 0x24000000000904UL + S0(W2) + W1)
#define R2_18 (W2 = S1(W0) + S0(W3) + W2)
#define R3_19 (W3 = S1(W1) + S0(W4) + W3)
#define R4_20 (W4 = S1(W2) + W4)
#define R5_21 (W5 = S1(W3))
#define R6_22 (W6 = S1(W4) + 0x120UL)
#define R7_23 (W7 = S1(W5) + W0)
#define R8_24 (W8 = S1(W6) + W1)
#define R9_25 (W9 = S1(W7) + W2)
#define R10_26 (W10 = S1(W8) + W3)
#define R11_27 (W11 = S1(W9) + W4)
#define R12_28 (W12 = S1(W10) + W5)
#define R13_29 (W13 = S1(W11) + W6)
#define R14_30 (W14 = S1(W12) + W7 + 0x2000000000000093UL)

#define RD14 (S1(W12) + W7 + S0(W15) + W14)
#define RD15 (S1(W13) + W8 + S0(W0) + W15)

inline ulong8 sha512(const uint nonce, const uint data0, const uint data1, const uint data2, const uint data3,
                     const uint data4, const uint data5, const uint data6, const uint data7)
{
    ulong v0 = 0x6A09E667F3BCC908UL;
    ulong v1 = 0xBB67AE8584CAA73BUL;
    ulong v2 = 0x3C6EF372FE94F82BUL;
    ulong v3 = 0xA54FF53A5F1D36F1UL;
    ulong v4 = 0x510E527FADE682D1UL;
    ulong v5 = 0x9B05688C2B3E6C1FUL;
    ulong v6 = 0x1F83D9ABFB41BD6BUL;
    ulong v7 = 0x5BE0CD19137E2179UL;
    ulong temp1;

    ulong W0 = as_ulong((uint2)(data0, SWAP32(nonce)));
    ulong W1 = as_ulong((uint2)(data2, data1));
    ulong W2 = as_ulong((uint2)(data4, data3));
    ulong W3 = as_ulong((uint2)(data6, data5));
    ulong W4 = as_ulong((uint2)(0x80000000, data7));
    ulong W5 = 0, W6 = 0, W7 = 0, W8 = 0, W9 = 0, W10 = 0, W11 = 0, W12 = 0, W13 = 0, W14 = 0;
    ulong W15 = 0x120UL;

    P( v0, v1, v2, v3, v4, v5, v6, v7, W0, 0x428A2F98D728AE22UL );
    P( v7, v0, v1, v2, v3, v4, v5, v6, W1, 0x7137449123EF65CDUL );
    P( v6, v7, v0, v1, v2, v3, v4, v5, W2, 0xB5C0FBCFEC4D3B2FUL );
    P( v5, v6, v7, v0, v1, v2, v3, v4, W3, 0xE9B5DBA58189DBBCUL );
    P( v4, v5, v6, v7, v0, v1, v2, v3, W4, 0x3956C25BF348B538UL );
    P( v3, v4, v5, v6, v7, v0, v1, v2, 0, 0x59F111F1B605D019UL );
    P( v2, v3, v4, v5, v6, v7, v0, v1, 0, 0x923F82A4AF194F9BUL );
    P( v1, v2, v3, v4, v5, v6, v7, v0, 0, 0xAB1C5ED5DA6D8118UL );

    P( v0, v1, v2, v3, v4, v5, v6, v7, 0, 0xD807AA98A3030242UL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, 0, 0x12835B0145706FBEUL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, 0, 0x243185BE4EE4B28CUL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, 0, 0x550C7DC3D5FFB4E2UL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, 0, 0x72BE5D74F27B896FUL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, 0, 0x80DEB1FE3B1696B1UL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, 0, 0x9BDC06A725C71235UL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, 0x120UL, 0xC19BF174CF692694UL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R0_16, 0xE49B69C19EF14AD2UL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R1_17, 0xEFBE4786384F25E3UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R2_18, 0x0FC19DC68B8CD5B5UL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R3_19, 0x240CA1CC77AC9C65UL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R4_20, 0x2DE92C6F592B0275UL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R5_21, 0x4A7484AA6EA6E483UL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, R6_22, 0x5CB0A9DCBD41FBD4UL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, R7_23, 0x76F988DA831153B5UL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R8_24, 0x983E5152EE66DFABUL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R9_25, 0xA831C66D2DB43210UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R10_26, 0xB00327C898FB213FUL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R11_27, 0xBF597FC7BEEF0EE4UL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R12_28, 0xC6E00BF33DA88FC2UL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R13_29, 0xD5A79147930AA725UL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, R14_30, 0x06CA6351E003826FUL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, R15, 0x142929670A0E6E70UL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R0, 0x27B70A8546D22FFCUL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R1, 0x2E1B21385C26C926UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R2, 0x4D2C6DFC5AC42AEDUL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R3, 0x53380D139D95B3DFUL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R4, 0x650A73548BAF63DEUL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R5, 0x766A0ABB3C77B2A8UL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, R6, 0x81C2C92E47EDAEE6UL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, R7, 0x92722C851482353BUL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R8, 0xA2BFE8A14CF10364UL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R9, 0xA81A664BBC423001UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R10, 0xC24B8B70D0F89791UL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R11, 0xC76C51A30654BE30UL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R12, 0xD192E819D6EF5218UL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R13, 0xD69906245565A910UL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, R14, 0xF40E35855771202AUL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, R15, 0x106AA07032BBD1B8UL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R0, 0x19A4C116B8D2D0C8UL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R1, 0x1E376C085141AB53UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R2, 0x2748774CDF8EEB99UL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R3, 0x34B0BCB5E19B48A8UL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R4, 0x391C0CB3C5C95A63UL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R5, 0x4ED8AA4AE3418ACBUL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, R6, 0x5B9CCA4F7763E373UL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, R7, 0x682E6FF3D6B2B8A3UL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R8, 0x748F82EE5DEFB2FCUL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R9, 0x78A5636F43172F60UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R10, 0x84C87814A1F0AB72UL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R11, 0x8CC702081A6439ECUL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R12, 0x90BEFFFA23631E28UL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R13, 0xA4506CEBDE82BDE9UL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, R14, 0xBEF9A3F7B2C67915UL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, R15, 0xC67178F2E372532BUL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R0, 0xCA273ECEEA26619CUL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R1, 0xD186B8C721C0C207UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R2, 0xEADA7DD6CDE0EB1EUL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R3, 0xF57D4F7FEE6ED178UL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R4, 0x06F067AA72176FBAUL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R5, 0x0A637DC5A2C898A6UL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, R6, 0x113F9804BEF90DAEUL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, R7, 0x1B710B35131C471BUL);

    P( v0, v1, v2, v3, v4, v5, v6, v7, R8, 0x28DB77F523047D84UL);
    P( v7, v0, v1, v2, v3, v4, v5, v6, R9, 0x32CAAB7B40C72493UL);
    P( v6, v7, v0, v1, v2, v3, v4, v5, R10, 0x3C9EBE0A15C9BEBCUL);
    P( v5, v6, v7, v0, v1, v2, v3, v4, R11, 0x431D67C49C100D4CUL);
    P( v4, v5, v6, v7, v0, v1, v2, v3, R12, 0x4CC5D4BECB3E42B6UL);
    P( v3, v4, v5, v6, v7, v0, v1, v2, R13, 0x597F299CFC657E2AUL);
    P( v2, v3, v4, v5, v6, v7, v0, v1, RD14, 0x5FCB6FAB3AD6FAECUL);
    P( v1, v2, v3, v4, v5, v6, v7, v0, RD15, 0x6C44198C4A475817UL);

    v0 += 0x6A09E667F3BCC908UL;
    v1 += 0xBB67AE8584CAA73BUL;
    v2 += 0x3C6EF372FE94F82BUL;
    v3 += 0xA54FF53A5F1D36F1UL;
    v4 += 0x510E527FADE682D1UL;
    v5 += 0x9B05688C2B3E6C1FUL;
    v6 += 0x1F83D9ABFB41BD6BUL;
    v7 += 0x5BE0CD19137E2179UL;
    return (ulong8)(v0, v1, v2, v3, v4, v5, v6, v7);
}

__kernel void pts_sha512_fill(const uint data0, const uint data1, const uint data2, const uint data3,
                              const uint data4, const uint data5, const uint data6, const uint data7,
                              __global ulong* hashes,
                              __global uint* keyhash)
{
    uint base = get_global_id(0);
    uint nonce = base << 3;
    ulong8 hashbe = sha512(nonce, data0, data1, data2, data3, data4, data5, data6, data7);
    hashbe &= 0x00C0FFFFFFFFFFFFUL;
    vstore8(hashbe, base, hashes);

    hashbe %= KEYHASH_CAPACITY;

    keyhash[hashbe.s0] = nonce++;
    keyhash[hashbe.s1] = nonce++;
    keyhash[hashbe.s2] = nonce++;
    keyhash[hashbe.s3] = nonce++;
    keyhash[hashbe.s4] = nonce++;
    keyhash[hashbe.s5] = nonce++;
    keyhash[hashbe.s6] = nonce++;
    keyhash[hashbe.s7] = nonce;
}

__kernel void search_ht(__global ulong* hashes,
                        __global uint* keyhash,
                        __global ulong* output)
{
    uint key = get_global_id(0);
    ulong hash = hashes[key];
    uint key2 = keyhash[hash % KEYHASH_CAPACITY];
    if (key != key2 && hashes[key2] == hash)
        output[output[0xFF]++] = as_ulong((uint2)(key, key2));
}









