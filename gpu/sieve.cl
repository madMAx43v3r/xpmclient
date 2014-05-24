/*
 * sieve.cl
 *
 *  Created on: 18.12.2013
 *      Author: mad
 */




/*
#define SIZE 4096
#define LSIZE 256
#define STRIPES 420
#define WIDTH 20
#define PCOUNT 40960
#define SCOUNT PCOUNT
#define TARGET 10
#define PRIMORIAL 13

typedef struct {
	
	uint index;
	uint origin;
	uint chainpos;
	uint type;
	uint hashid;
	
} fermat_t;*/




#define LSIZE 256
#define LSIZELOG2 8
#define S1COUNT 256
#define S1RUNS 17
#define NLIFO 6

__constant uint P[] =
	{	2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,
		151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,
		311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,461,463,467,
		479,487,491,499,503,509,521,523,541,547,557,563,569,571,577,587,593,599,601,607,613,617,619,631,641,643,647,653,
		659,661,673,677,683,691,701,709,719,727,733,739,743,751,757,761,769,773,787,797,809,811,821,823,827,829,839,853,
		857,859,863,877,881,883,887,907,911,919,929,937,941,947,953,967,971,977,983,991,997,1009,1013,1019,1021,1031,
		1033,1039,1049,1051,1061,1063,1069,1087,1091,1093,1097,1103,1109,1117,1123,1129,1151,1153,1163,1171,1181,1187,
		1193,1201,1213,1217,1223,1229,1231,1237,1249,1259,1277,1279,1283,1289,1291,1297,1301,1303,1307,1319,1321,1327,
		1361,1367,1373,1381,1399,1409,1423,1427,1429,1433,1439,1447,1451,1453,1459,1471,1481,1483,1487,1489,1493,1499,
		1511,1523,1531,1543,1549,1553,1559,1567,1571,1579,1583,1597,1601,1607,1609,1613,1619,1621,1627,1637,1657,1663,
		1667,1669,1693,1697,1699,1709,1721,1723,1733,1741,1747,1753,1759,1777,1783,1787,1789,1801,1811,1823,1831,1847,
		1861,1867,1871,1873,1877,1879,1889,1901,1907,1913,1931,1933,1949,1951,1973,1979,1987 };

__constant uint count_all[] = { 19, 12, 25, 20, 18, 25, 20, 16, 13, 11, 10,
								16, 13, 11, 9, 
								15, 12,
								18 };

/*__constant uint nps_all[] = { 1, 1, 2, 2, 2, 3, 3, 3, 3,
							  4, 4, 4, 
							  5, 5, 5,
							  6,
							  6, 6, 6, 6,
							  NLIFO	};*/

__constant uint nps_all[] = { 2, 2, 2, 2, 3, 3, 3, 3, 3, 3,
							  4, 4, 4, 4,
							  5, 5,
							  6 };


__attribute__((reqd_work_group_size(LSIZE, 1, 1)))
__kernel void sieve(	__global uint4* gsieve_all,
						__global const uint* offset_all,
						__global const uint2* primes )
{
	
	__local uint sieve[SIZE];
	
	const uint id = get_local_id(0);
	const uint stripe = get_group_id(0);
	const uint line = get_group_id(1);
	
	const uint entry = SIZE*32*(stripe+STRIPES/2);
	const float fentry = entry;
	
	__global const uint* offset = &offset_all[PCOUNT*line];
	
	for(uint i = 0; i < SIZE/LSIZE; ++i)
		sieve[i*LSIZE+id] = 0;
	
	barrier(CLK_LOCAL_MEM_FENCE);
	
	{
		uint lprime[2];
		float lfiprime[2];
		uint lpos[2];
		
		uint poff = 0;
		uint nps = nps_all[0];
		uint ip = id >> (LSIZELOG2-nps);
		
		lprime[0] = primes[poff+ip].x;
		lfiprime[0] = as_float(primes[poff+ip].y);
		lpos[0] = offset[poff+ip];
		
		#pragma unroll
		for(int b = 0; b < S1RUNS; ++b){
			
			const uint var = LSIZE >> nps;
			const uint lpoff = id & (var-1);
			
			if(b < S1RUNS-1){
				
				poff += 1 << nps;
				nps = nps_all[b+1];
				ip = id >> (LSIZELOG2-nps);
				
				lprime[(b+1)%2] = primes[poff+ip].x;
				lfiprime[(b+1)%2] = as_float(primes[poff+ip].y);
				lpos[(b+1)%2] = offset[poff+ip];
				
			}
			
			const uint prime = lprime[b%2];
			const float fiprime = lfiprime[b%2];
			uint pos = lpos[b%2];
			
			pos = mad24((uint)(fentry * fiprime), prime, pos) - entry;
			pos = mad24((uint)((int)pos < (int)0), prime, pos);
			pos = mad24(lpoff, prime, pos);
			
			/*uint index = pos >> 5;
			if(index < SIZE){
				
				#pragma unroll
				for(int i = 0; i < 8; ++i){
					atomic_or(&sieve[index], 1u << pos);
					pos = mad24(var, prime, pos);
					index = pos >> 5;
				}
				
				do{
					atomic_or(&sieve[index], 1u << pos);
					pos = mad24(var, prime, pos);
					index = pos >> 5;
				}while(index < SIZE);
				
			}*/
			
			while(true){
				const uint index = pos >> 5;
				if(index >= SIZE)
					break;
				atomic_or(&sieve[index], 1u << pos);
				pos = mad24(var, prime, pos);
			}
			
		}
	
	}
	
	__global const uint2* pprimes = &primes[id];
	__global const uint* poffset = &offset[id];
	
	uint plifo[NLIFO];
	uint fiplifo[NLIFO];
	uint olifo[NLIFO];
	
	for(int i = 0; i < NLIFO; ++i){
		
		pprimes += LSIZE;
		poffset += LSIZE;
		
		const uint2 tmp = *pprimes;
		plifo[i] = tmp.x;
		fiplifo[i] = tmp.y;
		olifo[i] = *poffset;
		
	}
	
	uint lpos = 0;
	#pragma unroll
	for(uint ip = 1; ip < SCOUNT/LSIZE; ++ip){
		
		const uint prime = plifo[lpos];
		const float fiprime = as_float(fiplifo[lpos]);
		uint pos = olifo[lpos];
		
		pos = mad24((uint)(fentry * fiprime), prime, pos) - entry;
		pos = mad24((uint)((int)pos < (int)0), prime, pos);
		
		uint index = pos >> 5;
		
		if(ip < 18){
			while(index < SIZE){
				atomic_or(&sieve[index], 1u << pos);
				pos += prime;
				index = pos >> 5;
			}
		}else if(ip < 26){
			if(index < SIZE){
				atomic_or(&sieve[index], 1u << pos);
				pos += prime;
				index = pos >> 5;
				if(index < SIZE){
					atomic_or(&sieve[index], 1u << pos);
					pos += prime;
					index = pos >> 5;
					if(index < SIZE){
						atomic_or(&sieve[index], 1u << pos);
					}
				}
			}
		}else if(ip < 48){
			if(index < SIZE){
				atomic_or(&sieve[index], 1u << pos);
				pos += prime;
				index = pos >> 5;
				if(index < SIZE){
					atomic_or(&sieve[index], 1u << pos);
				}
			}
		}else{
			if(index < SIZE){
				atomic_or(&sieve[index], 1u << pos);
			}
		}
		
		if(ip+NLIFO < SCOUNT/LSIZE){
			
			pprimes += LSIZE;
			poffset += LSIZE;
			
			const uint2 tmp = *pprimes;
			plifo[lpos] = tmp.x;
			fiplifo[lpos] = tmp.y;
			olifo[lpos] = *poffset;
			
		}
		
		lpos++;
		lpos = lpos % NLIFO;
		
	}
	
	barrier(CLK_LOCAL_MEM_FENCE);
	
	__global uint4* gsieve = &gsieve_all[SIZE*(STRIPES/2*line + stripe)/4];
	
	for(uint i = 0; i < SIZE/LSIZE/4; i++){
		
		uint4 tmp;
		tmp.x = sieve[4*(i*LSIZE+id)];
		tmp.y = sieve[4*(i*LSIZE+id)+1];
		tmp.z = sieve[4*(i*LSIZE+id)+2];
		tmp.w = sieve[4*(i*LSIZE+id)+3];
		gsieve[i*LSIZE+id] = tmp;
		
	}
	
}


__kernel void sieveL2(	__global uint* gsieve_all,
						__global const uint* offset_all,
						__global const uint* primes )
{
	const uint id = get_global_id(0);
	const uint line = get_global_id(1);
	
	const uint entry = SIZE*32*STRIPES/2;
	
	__global uint* gsieve = &gsieve_all[SIZE*STRIPES/2*line];
	__global const uint* offset = &offset_all[PCOUNT*line];
	
	const uint prime = primes[SCOUNT + id];
	
	uint pos = offset[SCOUNT + id];
	pos = mad24((uint)((float)(entry)/(float)(prime)), prime, pos) - entry;
	pos = mad24((uint)((int)pos < (int)0), prime, pos);
	
	uint index = pos >> 5;
	
	while(index < STRIPES*SIZE){
		
		atomic_or(&gsieve[index], 1u << pos);
		
		pos += prime;
		index = pos >> 5;
		
	}
	
}



__kernel void search_sieve_0(	__global const uint* gsieve,
								__global fermat_t* found,
								__global uint* fcount,
								uint hashid,
								uint type )
{
	
	const uint id = get_global_id(0);
	
	uint mask = 0;
	for(int line = 0; line < TARGET; ++line)
		mask |= gsieve[SIZE*STRIPES/2*line + id];
	
	if(mask != 0xFFFFFFFF)
		for(int bit = 0; bit < 32; ++bit)
			if((~mask & (1 << bit))){
				
				const uint addr = atomic_inc(fcount);
				
				fermat_t info;
				info.index = SIZE*32*STRIPES/2 + id*32 + bit;
				info.origin = 0;
				info.chainpos = 0;
				info.type = type;
				info.hashid = hashid;
				
				found[addr] = info;
				return;
				
			}
	
}


__kernel void search_sieve(	__global const uint* gsieve,
							__global fermat_t* found,
							__global uint* fcount,
							uint hashid,
							uint type )
{
	
	const uint id = get_global_id(0);
	
	uint tmp[WIDTH];
	for(int i = 0; i < WIDTH; ++i)
		tmp[i] = gsieve[SIZE*STRIPES/2*i + id];
	
	for(int start = 0; start <= WIDTH-TARGET; ++start){
		
		uint mask = 0;
		for(int line = 0; line < TARGET; ++line)
			mask |= tmp[start+line];
		
		if(mask != 0xFFFFFFFF)
			for(int bit = 0; bit < 32; ++bit)
				if((~mask & (1 << bit))){
					
					const uint addr = atomic_inc(fcount);
					
					fermat_t info;
					info.index = SIZE*32*STRIPES/2 + id*32 + bit;
					info.origin = start;
					info.chainpos = 0;
					info.type = type;
					info.hashid = hashid;
					
					found[addr] = info;
					
					break;
					//return;
					
				}
		
	}
	
}


__kernel void search_sieve_bi_0(	__global const uint* gsieve1,
									__global const uint* gsieve2,
									__global fermat_t* found,
									__global uint* fcount,
									uint hashid )
{
	
	const uint id = get_global_id(0);
	
	uint mask = 0;
	for(int line = 0; line < TARGET/2; ++line)
		mask |= gsieve1[SIZE*STRIPES/2*line + id] | gsieve2[SIZE*STRIPES/2*line + id];
	
	if(mask != 0xFFFFFFFF)
		for(int bit = 0; bit < 32; ++bit)
			if((~mask & (1 << bit))){
				
				const uint addr = atomic_inc(fcount);
				
				fermat_t info;
				info.index = SIZE*32*STRIPES/2 + id*32 + bit;
				info.origin = 0;
				info.chainpos = 0;
				info.type = 2;
				info.hashid = hashid;
				
				found[addr] = info;
				return;
				
			}
	
}


__kernel void search_sieve_bi(	__global const uint* gsieve1,
								__global const uint* gsieve2,
								__global fermat_t* found,
								__global uint* fcount,
								uint hashid )
{
	
	const uint id = get_global_id(0);
	
	uint tmp1[WIDTH];
	uint tmp2[WIDTH];
	for(int i = 0; i < WIDTH; ++i){
		tmp1[i] = gsieve1[SIZE*STRIPES/2*i + id];
		tmp2[i] = gsieve2[SIZE*STRIPES/2*i + id];
	}
	
	for(int start = 0; start <= WIDTH-TARGET/2; ++start){
		
		uint mask = 0;
		for(int line = 0; line < TARGET/2; ++line)
			mask |= tmp1[start+line] | tmp2[start+line];
		
		if(mask != 0xFFFFFFFF)
			for(int bit = 0; bit < 32; ++bit)
				if((~mask & (1 << bit))){
					
					const uint addr = atomic_inc(fcount);
					
					fermat_t info;
					info.index = SIZE*32*STRIPES/2 + id*32 + bit;
					info.origin = start;
					info.chainpos = 0;
					info.type = 2;
					info.hashid = hashid;
					
					found[addr] = info;
					
					break;
					//return;
					
				}
		
	}
	
}


__kernel void s_sieve(	__global const uint* gsieve1,
						__global const uint* gsieve2,
						__global fermat_t* found,
						__global uint* fcount,
						uint hashid )
{
	
	const uint id = get_global_id(0);
	
	uint tmp1[WIDTH];
	for(int i = 0; i < WIDTH; ++i)
		tmp1[i] = gsieve1[SIZE*STRIPES/2*i + id];
	
	for(int start = 0; start <= WIDTH-TARGET; ++start){
		
		uint mask = 0;
		for(int line = 0; line < TARGET; ++line)
			mask |= tmp1[start+line];
		
		if(mask != 0xFFFFFFFF)
			for(int bit = 0; bit < 32; ++bit)
				if((~mask & (1 << bit))){
					
					const uint addr = atomic_inc(fcount);
					
					fermat_t info;
					info.index = SIZE*32*STRIPES/2 + id*32 + bit;
					info.origin = start;
					info.chainpos = 0;
					info.type = 0;
					info.hashid = hashid;
					
					found[addr] = info;
					
					break;
					//return;
					
				}
		
	}
	
	uint tmp2[WIDTH];
	for(int i = 0; i < WIDTH; ++i)
		tmp2[i] = gsieve2[SIZE*STRIPES/2*i + id];
	
	for(int start = 0; start <= WIDTH-TARGET; ++start){
		
		uint mask = 0;
		for(int line = 0; line < TARGET; ++line)
			mask |= tmp2[start+line];
		
		if(mask != 0xFFFFFFFF)
			for(int bit = 0; bit < 32; ++bit)
				if((~mask & (1 << bit))){
					
					const uint addr = atomic_inc(fcount);
					
					fermat_t info;
					info.index = SIZE*32*STRIPES/2 + id*32 + bit;
					info.origin = start;
					info.chainpos = 0;
					info.type = 1;
					info.hashid = hashid;
					
					found[addr] = info;
					
					break;
					//return;
					
				}
		
	}
	
	for(int start = 0; start <= WIDTH-(TARGET+1)/2; ++start){
		
		uint mask = 0;
		for(int line = 0; line < TARGET/2; ++line)
			mask |= tmp1[start+line] | tmp2[start+line];
		
		if(TARGET & 1u)
			mask |= tmp1[start+TARGET/2];
		
		if(mask != 0xFFFFFFFF)
			for(int bit = 0; bit < 32; ++bit)
				if((~mask & (1 << bit))){
					
					const uint addr = atomic_inc(fcount);
					
					fermat_t info;
					info.index = SIZE*32*STRIPES/2 + id*32 + bit;
					info.origin = start;
					info.chainpos = 0;
					info.type = 2;
					info.hashid = hashid;
					
					found[addr] = info;
					
					break;
					//return;
					
				}
		
	}
	
}



















