/*
 * opencl.h
 *
 *  Created on: 01.05.2014
 *      Author: mad
 */

#ifndef OPENCL_H_
#define OPENCL_H_


#include <CL/cl.h>


extern cl_context gContext;



#define OCL(error) \
	if(cl_int err = error){ \
		printf("OpenCL error: %d at %s:%d\n", err, __FILE__, __LINE__); \
		return; \
	}

#define OCLR(error, ret) \
	if(cl_int err = error){ \
		printf("OpenCL error: %d at %s:%d\n", err, __FILE__, __LINE__); \
		return ret; \
	}

#define OCLE(error) \
	if(cl_int err = error){ \
		printf("OpenCL error: %d at %s:%d\n", err, __FILE__, __LINE__); \
		exit(err); \
	}





template<typename T>
class clBuffer {
public:
	
	clBuffer() {
		
		Size = 0;
		HostData = 0;
		DeviceData = 0;
		
	}
	
	~clBuffer() {
		
		if(HostData)
			delete [] HostData;
		
		if(DeviceData)
			clReleaseMemObject(DeviceData);
		
	}
	
	void init(int size, cl_mem_flags flags = 0) {
		
		Size = size;
		
		if(!(flags & CL_MEM_HOST_NO_ACCESS)){
			HostData = new T[Size];
			memset(HostData, 0, Size*sizeof(T));
		}else
			HostData = 0;
		
		//printf("clCreateBuffer: size = %d, %d bytes\n", Size, Size*sizeof(T));
		
		cl_int error;
		DeviceData = clCreateBuffer(gContext, flags, Size*sizeof(T), 0, &error);
		OCL(error);
		
	}
	
	void copyToDevice(cl_command_queue cq, bool blocking = true) {
		
		OCL(clEnqueueWriteBuffer(cq, DeviceData, blocking, 0, Size*sizeof(T), HostData, 0, 0, 0));
		
	}
	
	void copyToHost(cl_command_queue cq, bool blocking = true, unsigned size = 0) {
		
		if(size == 0)
			size = Size;
		
		OCL(clEnqueueReadBuffer(cq, DeviceData, blocking, 0, size*sizeof(T), HostData, 0, 0, 0));
		
	}
	
	T& get(int index) {
		return HostData[index];
	}
	
	T& operator[](int index) {
		return HostData[index];
	}
	
public:
	
	int Size;
	T* HostData;
	cl_mem DeviceData;
	
	
};








#endif /* OPENCL_H_ */
