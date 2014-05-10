/*
 * fermat.cl
 *
 *  Created on: 26.12.2013
 *      Author: mad
 */





#define N 11				// Number of 32bit limbs (N*32 = maximum fermat bits)

#define SIZE 4096			// Size of local sieve array (must be multiple of 1024)
#define LSIZE 256			// Local worksize for sieve (don't change this)
#define STRIPES 420			// Number of sieve segments (you may tune this)
#define WIDTH 20			// Sieve width (includes extensions, you may tune this)
#define PCOUNT 40960		// Number of sieve primes (must be multiple of 256, you should tune this, 40960 is for 280X)
#define SCOUNT PCOUNT		// Don't change it
#define TARGET 10			// Target for s_sieve




typedef struct {
	
	uint index;
	uchar origin;
	uchar chainpos;
	uchar type;
	uchar hashid;
	
} fermat_t;


typedef struct {
	
	uint N_;
	uint SIZE_;
	uint STRIPES_;
	uint WIDTH_;
	uint PCOUNT_;
	uint TARGET_;
	
} config_t;



__kernel void getconfig(__global config_t* conf)
{
	config_t c;
	c.N_ = N;
	c.SIZE_ = SIZE;
	c.STRIPES_ = STRIPES;
	c.WIDTH_ = WIDTH;
	c.PCOUNT_ = PCOUNT;
	c.TARGET_ = TARGET;
	*conf = c;
}



/*void mad_211(uint* restrict c, const uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(uint i = 0; i < N; ++i){
		
		uint tmp = a[i] * b[0] + c[i];
		
		#pragma unroll
		for(uint k = 1; k < N; ++k){
			
			const uint ind = i+k;
			const uint tmp2 = a[i] * b[k] + c[ind] + (tmp < c[ind-1]);
			c[ind-1] = tmp;
			tmp = tmp2;
			
		}
		
		c[i+N] += (tmp < c[i+N-1]);
		c[i+N-1] = tmp;
		
		tmp = mul_hi(a[i], b[0]) + c[i+1];
		
		#pragma unroll
		for(uint k = 1; k < N; ++k){
			
			const uint ind = i+k+1;
			const uint tmp2 = mul_hi(a[i], b[k]) + c[ind] + (tmp < c[ind-1]);
			c[ind-1] = tmp;
			tmp = tmp2;
			
		}
		
		if(i+N+1 < 2*N)
			c[i+N+1] += (tmp < c[i+N]);
		
		c[i+N] = tmp;
		
	}
	
}*/


void mad_211(uint* restrict c, const uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(uint i = 0; i < N; ++i){
		
		bool carry = (c[i] + a[i] * b[0]) < c[i];
		c[i] += a[i] * b[0];
		
		#pragma unroll
		for(uint k = 1; k < N; ++k){
			
			const uint ind = i+k;
			bool carry2 = (c[ind] + a[i] * b[k] + carry) < c[ind];
			c[ind] = c[ind] + a[i] * b[k] + carry;
			carry = carry2;
			
		}
		
		c[i+N] += carry;
		
		carry = (c[i+1] + mul_hi(a[i], b[0])) < c[i+1];
		c[i+1] += mul_hi(a[i], b[0]);
		
		#pragma unroll
		for(uint k = 1; k < N; ++k){
			
			const uint ind = i+k+1;
			bool carry2 = (c[ind] + mul_hi(a[i], b[k]) + carry) < c[ind];
			c[ind] = c[ind] + mul_hi(a[i], b[k]) + carry;
			carry = carry2;
			
		}
		
		if(i+N+1 < 2*N)
			c[i+N+1] += carry;
		
	}
	
	
}


void add(uint* restrict c, const uint* restrict a, const uint* restrict b) {
	
	c[0] = a[0] + b[0];
	
	#pragma unroll
	for(uint i = 1; i < N; ++i)
		c[i] = a[i] + b[i] + (c[i-1] < a[i-1]);
	
}

void add_ui(uint* a, uint b) {
	
	const uint tmp = a[0] + b;
	a[1] += (tmp < a[0]);
	a[0] = tmp;
	
}


void sub(uint* restrict c, const uint* restrict a, const uint* restrict b) {
	
	c[0] = a[0] - b[0];
	
	#pragma unroll
	for(uint i = 1; i < N; ++i)
		c[i] = a[i] - b[i] - (c[i-1] > a[i-1]);
		//c[i] = a[i] - b[i] - (a[i-1] < b[i-1]);
	
}

void sub_ui(uint* a, uint b) {
	
	a[1] -= (a[0] < b);
	a[0] -= b;
	
}


void shr(uint* a) {
	
	#pragma unroll
	for(uint i = 0; i < N-1; ++i)
		a[i] = (a[i] >> 1) | (a[i+1] << 31);
	
	a[N-1] = a[N-1] >> 1;
	
}

void shr2(uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(uint i = 0; i < N-1; ++i)
		a[i] = (b[i] >> 1) | (b[i+1] << 31);
	
	a[N-1] = b[N-1] >> 1;
	
}


void shl(uint* restrict a) {
	
	#pragma unroll
	for(int i = N-1; i > 0; --i)
		a[i] = (a[i] << 1) | (a[i-1] >> 31);
	
	a[0] = a[0] << 1;
	
}

void shl2(uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(int i = N-1; i > 0; --i)
		a[i] = (b[i] << 1) | (b[i-1] >> 31);
	
	a[0] = b[0] << 1;
	
}

void shlx(uint* restrict a, uint bits) {
	
	#pragma unroll
	for(int i = N-1; i > 0; --i)
		a[i] = (a[i] << bits) | (a[i-1] >> (32-bits));
	
	a[0] = a[0] << bits;
	
}


void xor(uint* restrict c, const uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(uint i = 0; i < N; ++i)
		c[i] = a[i] ^ b[i];
	
}


void and(uint* restrict c, const uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(uint i = 0; i < N; ++i)
		c[i] = a[i] & b[i];
	
}


void or(uint* restrict c, const uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(uint i = 0; i < N; ++i)
		c[i] = a[i] | b[i];
	
}


void mov(uint* restrict a, const uint* restrict b) {
	
	#pragma unroll
	for(uint i = 0; i < N; ++i)
		a[i] = b[i];
	
}


void xbinGCD(const uint* restrict a, const uint* restrict b, uint* restrict u, uint* restrict v) {
	
	u[0] = 1;
	for(uint i = 1; i < N; ++i)
		u[i] = 0;
	
	for(uint i = 0; i < N; ++i)
		v[i] = 0;
	
	uint t[N];
	
	for(uint i = 0; i < N*32; ++i){
		
		if((u[0] & 1) == 0){
			
			shr(u);
			shr(v);
			
		}else{
			
			add(t, u, b);
			shr2(u, t);
			
			shr2(t, v);
			add(v, t, a);
			
		}
		
	}
	
}


void modul(uint* restrict x, uint* restrict y, const uint* restrict z) {
	
	uint v[N];
	
	for(uint k = 0; k < N*32; ++k){
		
		const bool t = x[N-1] >> 31;
		
		shl(x);
		x[0] |= y[N-1] >> 31;
		shl(y);
		
		sub(v, x, z);
		const bool test = v[N-1] <= x[N-1];
		
		if(test || t){
			
			mov(x, v);
			add_ui(y, 1);
			
		}
		
	}
	
}

void modulz(uint* restrict x, /*uint* restrict y,*/ const uint* restrict z) {
	
	uint v[N];
	
	for(uint k = 0; k < N*32; ++k){
		
		const bool t = x[N-1] >> 31;
		
		shl(x);
		
		sub(v, x, z);
		const bool test = v[N-1] <= x[N-1];
		
		if(test || t){
			
			mov(x, v);
			
		}
		
	}
	
}


/*uint tdiv_ui(uint* y, uint z) {
	
	uint x[N];
	for(uint i = 0; i < N; ++i)
		x[i] = 0;
	
	for(uint k = 0; k < N*32; ++k){
		
		const bool t = x[N-1] >> 31;
		
		shl(x);
		x[0] |= y[N-1] >> 31;
		shl(y);
		
		const bool test = x[1] > 0 || x[0] >= z;
		
		if(test || t){
			
			sub_ui(x, z);
			add_ui(y, 1);
			
		}
		
	}
	
	return x[0];
	
}*/

uint tdiv_ui(const uint* y, uint z) {
	
	uint x = 0;
	
	#pragma unroll
	for(uint k = 0; k < N*32; ++k){
		
		x = x << 1;
		x |= (y[N-1-(k/32)] >> (31-(k%32))) & 1u;
		
		if(x >= z)
			x -= z;
		
	}
	
	return x;
	
}


void montymul(uint* restrict c, const uint* restrict a, const uint* restrict b, const uint* restrict m, const uint* restrict mp) {
	
	uint t[2*N];
	uint s[2*N];
	for(int i = 0; i < 2*N; ++i){
		t[i] = 0;
		s[i] = 0;
	}
	
	mad_211(t, a, b);
	mad_211(s, t, mp);
	mad_211(t, s, m);
	
	for(int i = 0; i < N; ++i)
		c[i] = t[N+i];
	
	sub(t, c, m);
	
	if(t[N-1] <= c[N-1])
		mov(c, t);
	
}


bool fermat(const uint* p) {
	
	uint t[N];
	
	uint mp[N];
	uint rinv[N];
	
	t[N-1] = 1u << 31;
	for(int i = 0; i < N-1; ++i)
		t[i] = 0;
	
	xbinGCD(t, p, rinv, mp);
	
	uint base[N];
	uint result[N];
	
	base[0] = 2;
	for(int i = 1; i < N; ++i)
		base[i] = 0;
	
	result[0] = 1;
	for(int i = 1; i < N; ++i)
		result[i] = 0;
	
	modulz(base, p);
	modulz(result, p);
	
	uint e[N];
	for(int i = 0; i < N; ++i)
		e[i] = p[i];
	
	e[0] -= 1;
	
	uint s[N];
	bool state = false;
	while(true){
		
		if(!state){
			
			bool test = false;
			for(int i = 0; i < N; ++i)
				test = test || (e[i] > 0);
			
			if(!test)
				break;
			
		}
		
		if(!state && (e[0] & 1)){
			
			mov(s, result);
			state = true;
			
		}else{
			
			mov(s, base);
			state = false;
			
		}
		
		montymul(t, s, base, p, mp);
		
		if(state){
			
			mov(result, t);
			
		}else{
			
			mov(base, t);
			shr(e);
			
		}
		
		
	}
	
	uint w[2*N];
	for(int i = 0; i < 2*N; ++i)
		w[i] = 0;
	
	mad_211(w, result, rinv);
	
	modul(&w[N], w, p);
	
	bool test = w[N] == 1;
	for(int i = 1; i < N; ++i)
		test = test && (w[N+i] == 0);
	
	return test;
	
}



uint int_invert(uint a, uint nPrime)
{
    // Extended Euclidean algorithm to calculate the inverse of a in finite field defined by nPrime
    int rem0 = nPrime, rem1 = a % nPrime, rem2;
    int aux0 = 0, aux1 = 1, aux2;
    int quotient, inverse;
    
    while (1)
    {
        if (rem1 <= 1)
        {
            inverse = aux1;
            break;
        }
        
        rem2 = rem0 % rem1;
        quotient = rem0 / rem1;
        aux2 = -quotient * aux1 + aux0;
        
        if (rem2 <= 1)
        {
            inverse = aux2;
            break;
        }
        
        rem0 = rem1 % rem2;
        quotient = rem1 / rem2;
        aux0 = -quotient * aux2 + aux1;
        
        if (rem0 <= 1)
        {
            inverse = aux0;
            break;
        }
        
        rem1 = rem2 % rem0;
        quotient = rem2 / rem0;
        aux1 = -quotient * aux0 + aux2;
    }
    
    return (inverse + nPrime) % nPrime;
}



__kernel void setup_sieve(	__global uint* offset1,
							__global uint* offset2,
							__global const uint* vPrimes,
							__constant uint* hash,
							uint hashid )
{
	
	const uint id = get_global_id(0);
	const uint nPrime = vPrimes[id];
	
	uint tmp[N];
	for(int i = 0; i < N; ++i)
		tmp[i] = hash[hashid*N + i];
	
	const uint nFixedFactorMod = tdiv_ui(tmp, nPrime);
	if(nFixedFactorMod == 0){
		
		for(uint line = 0; line < WIDTH; ++line){
			//offset1[PCOUNT*line + id] = -1;
			//offset2[PCOUNT*line + id] = -1;
			offset1[PCOUNT*line + id] = 1u << 31;
			offset2[PCOUNT*line + id] = 1u << 31;
		}
		return;
		
	}
	
	uint nFixedInverse = int_invert(nFixedFactorMod, nPrime);
	const uint nTwoInverse = (nPrime + 1) / 2;
	
	// Check whether 32-bit arithmetic can be used for nFixedInverse
	const bool fUse32BArithmetic = (UINT_MAX / nTwoInverse) >= nPrime;
	
	if(fUse32BArithmetic){
		
		for(uint line = 0; line < WIDTH; ++line){
			
			offset1[PCOUNT*line + id] = nFixedInverse;
			offset2[PCOUNT*line + id] = nPrime - nFixedInverse;
			
			nFixedInverse = nFixedInverse * nTwoInverse % nPrime;
			
		}
		
	}else{
		
		for(uint line = 0; line < WIDTH; ++line){
			
			offset1[PCOUNT*line + id] = nFixedInverse;
			offset2[PCOUNT*line + id] = nPrime - nFixedInverse;
			
			nFixedInverse = (ulong)nFixedInverse * nTwoInverse % nPrime;
			
		}
		
	}
	
}



__kernel void setup_fermat(	__global uint* fprimes,
							__global const fermat_t* info_all,
							__constant uint* hash )
{
	
	const uint id = get_global_id(0);
	const fermat_t info = info_all[id];
	
	uint h[N];
	uint m[N];
	uint r[2*N];
	
	for(int i = 0; i < N; ++i){
		h[i] = hash[info.hashid*N + i];
		m[i] = 0;
		r[i] = 0;
	}
	
	uint line = info.origin;
	if(info.type < 2)
		line += info.chainpos;
	else
		line += info.chainpos/2;
	
	const ulong multi = (ulong)info.index << line;
	
	m[0] = multi;
	m[1] = multi >> 32;
	
	mad_211(r, h, m);
	
	if(info.type == 1 || (info.type == 2 && (info.chainpos & 1)))
		add_ui(r, 1);
	else
		sub_ui(r, 1);
	
	for(int i = 0; i < N; ++i)
		fprimes[id*N+i] = r[i];
	
}



__attribute__((reqd_work_group_size(64, 1, 1)))
__kernel void fermat_kernel(__global uchar* result,
							__global const uint* fprimes )
{
	
	const uint id = get_global_id(0);
	
	uint p[N];
	
	for(int i = 0; i < N; ++i)
		p[i] = fprimes[id*N+i];
	
	result[id] = fermat(p);
	
}



__kernel void check_fermat(	__global fermat_t* info_out,
							__global uint* count,
							__global fermat_t* info_fin_out,
							__global uint* count_fin,
							__global const uchar* results,
							__global const fermat_t* info_in,
							uint depth )
{
	
	const uint id = get_global_id(0);
	
	if(results[id] == 1){
		
		fermat_t info = info_in[id];
		info.chainpos++;
		
		if(info.chainpos < depth){
			
			const uint i = atomic_inc(count);
			info_out[i] = info;
			
		}else{
			
			const uint i = atomic_inc(count_fin);
			info_fin_out[i] = info;
			
		}
		
	}
	
}






/*
__attribute__((reqd_work_group_size(256, 1, 1)))
__kernel void test_monty(__global const uint* asrc, __global const uint* bsrc, __global const uint* csrc, __global const uint* dsrc, __global uint* esrc) {
	
	const uint id = get_global_id(0);
	
	uint a[N];
	uint b[N];
	uint c[N];
	uint d[N];
	uint e[N];
	
	for(int i = 0; i < N; ++i){
		a[i] = asrc[id*N+i];
		b[i] = bsrc[id*N+i];
		c[i] = csrc[id*N+i];
		d[i] = dsrc[id*N+i];
	}
	
	montymul(e, a, b, c, d);
	
	for(int i = 0; i < N; ++i){
		esrc[id*(N)+i] = e[i];
	}
	
}



__attribute__((reqd_work_group_size(64, 1, 1)))
__kernel void test_fermat(__global const uint* psrc, __global uint* dest) {
	
	const uint id = get_global_id(0);
	
	uint p[N];
	for(int i = 0; i < N; ++i){
		p[i] = psrc[id*N+i];
	}
	
	dest[id] = fermat(p);
	
}


__attribute__((reqd_work_group_size(256, 1, 1)))
__kernel void test_1(__global const uint* asrc, __global const uint* bsrc, __global uint* csrc, __global uint* dsrc) {
	
	const uint id = get_global_id(0);
	
	uint a[N];
	uint b[N];
	uint c[N];
	uint d[N];
	
	for(int i = 0; i < N; ++i){
		a[i] = asrc[id*N+i];
		b[i] = bsrc[id*N+i];
		c[i] = 0;
	}
	
	c[0] = int_invert(a[0], b[0]);
	
	for(int i = 0; i < N; ++i){
		csrc[id*(N)+i] = c[i];
		//dsrc[id*(N)+i] = d[i];
	}
	
}*/


__kernel void test_2(__global const uint* asrc, __global const uint* bsrc, __global uint* csrc) {
	
	const uint id = get_global_id(0);
	
	uint a[N];
	uint b[N];
	uint c[2*N];
	
	for(int i = 0; i < N; ++i){
		a[i] = asrc[id*N+i];
		b[i] = bsrc[id*N+i];
	}
	
	for(int i = 0; i < 2*N; ++i){
		//c[i] = 0;
		c[i] = csrc[id*(2*N)+i];
	}
	
	mad_211(c, a, b);
	
	for(int i = 0; i < 2*N; ++i)
		csrc[id*(2*N)+i] = c[i];
	
}


__kernel void test_3(__global const ulong* asrc, __global const ulong* bsrc, __global ulong* csrc) {
	
	const uint id = get_global_id(0);
	
	ulong a[N];
	ulong b[N];
	ulong c[2*N];
	
	for(int i = 0; i < N; ++i){
		a[i] = asrc[id*N+i];
		b[i] = bsrc[id*N+i];
	}
	
	for(int i = 0; i < 2*N; ++i){
		//c[i] = 0;
		c[i] = csrc[id*(2*N)+i];
	}
	
	ulong lo = a[0] * b[0];
	ulong hi = mul_hi(a[0], b[0]);
	
	c[0] += lo;
	c[1] += hi;
	
	
	for(int i = 0; i < 2*N; ++i)
		csrc[id*(2*N)+i] = c[i];
	
}












