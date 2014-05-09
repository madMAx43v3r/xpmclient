/*
 * baseclient.h
 *
 *  Created on: 30.04.2014
 *      Author: mad
 */

#ifndef BASECLIENT_H_
#define BASECLIENT_H_


#include <stdio.h>
#include <stdlib.h>
#include <string>

#include "protocol.pb.h"
using namespace pool;

#ifndef _WIN32
typedef int SOCKET;
#endif

#include <zmq.h>
#include <czmq.h>

#include <chrono>

#include <locale.h>
#include <config4cpp/Configuration.h>
using namespace config4cpp;




extern std::string gClientName;
extern unsigned gClientID;
extern const unsigned gClientVersion;

extern std::string gAddr;
extern proto::Block gBlock;




class Timer {
public:
    Timer() {
        reset();
    }
    void reset() {
        m_timestamp = std::chrono::high_resolution_clock::now();
    }
    float diff() {
        std::chrono::duration<float> fs = std::chrono::high_resolution_clock::now() - m_timestamp;
        return fs.count();
    }
private:
    std::chrono::high_resolution_clock::time_point m_timestamp;
};


struct share_t {
	
	share_t(){
		accepted = 0;
		invalid = 0;
		stale = 0;
		duplicate = 0;
	}
	
	unsigned accepted;
	unsigned invalid;
	unsigned stale;
	unsigned duplicate;
	
};




template<class C>
static bool Receive(C& rep, void* socket) {
	
	zmsg_t* msg = zmsg_recv(socket);
	if(!msg) return false;
	zframe_t* frame = zmsg_last(msg);
	size_t fsize = zframe_size(frame);
	const byte* fbytes = zframe_data(frame);
	
	rep.ParseFromArray(fbytes, fsize);
	zmsg_destroy(&msg);
	return true;
	
}

template<class C>
static bool ReceivePub(C& sig, void* socket) {
	
	zmsg_t* msg = zmsg_recv(socket);
	if(!msg) return false;
	zframe_t* frame = zmsg_next(msg);
	size_t fsize = zframe_size(frame);
	const byte* fbytes = zframe_data(frame);
	
	sig.ParseFromArray(fbytes+1, fsize-1);
	zmsg_destroy(&msg);
	return true;
	
}


template<class C>
static void Send(const C& req, void* socket) {
	
	zmsg_t* msg = zmsg_new();
	size_t fsize = req.ByteSize();
	zframe_t* frame = zframe_new(0, fsize);
	byte* data = zframe_data(frame);
	req.SerializeToArray(data, fsize);
	
	zmsg_append(msg, &frame);
	zmsg_send(&msg, socket);
	
}


template<class C>
static void SendPub(const C& sig, void* socket) {
	
	size_t fsize = sig.ByteSize()+1;
	zframe_t* frame = zframe_new(0, fsize);
	byte* data = zframe_data(frame);
	data[0] = 1;
	sig.SerializeToArray(data+1, fsize-1);
	
	zmsg_t* msg = zmsg_new();
	zmsg_append(msg, &frame);
	zmsg_send(&msg, socket);
	
}


















#endif /* BASECLIENT_H_ */
