//============================================================================
// Name        : baseclient.cpp
// Author      : madMAx
// Version     :
// Copyright   : Your copyright notice
// Description : Hello World in C, Ansi-style
//============================================================================


#include "baseclient.h"
#include "sysinfo.h"

#include "xpmclient.h"
#include "prime.h"

#include <iostream>




std::string gClientName;
unsigned gClientID;
unsigned gInstanceID;
const unsigned gClientVersion = 11;
const unsigned gClientTarget = 10;

zctx_t* gCtx = 0;
static void* gFrontend = 0;
static void* gServer = 0;
static void* gSignals = 0;
static void* gWorkers = 0;

std::string gAddr = "";
proto::Block gBlock;
proto::ServerInfo gServerInfo;

static unsigned gNextReqID = 0;
static Timer gRequestTimer;
static unsigned gLatency = 0;
static bool gHeartBeat = true;
static bool gExit = false;

static std::map<unsigned, int> gSharesSent;
static std::map<unsigned, share_t> gShares;





static double GetPrimeDifficulty(unsigned int nBits)
{
    return ((double) nBits / (double) (1 << nFractionalBits));
}



static bool ConnectBitcoin() {
	
	const proto::ServerInfo& sinfo = gServerInfo;
	printf("Connecting to bitcoin: %s:%d ...\n", sinfo.host().c_str(), sinfo.router());
	
	zsocket_destroy(gCtx, gServer);
	gServer = zsocket_new(gCtx, ZMQ_DEALER);
	int err = zsocket_connect(gServer, "tcp://%s:%d", sinfo.host().c_str(), sinfo.router());
	if(err){
		printf("ERROR: invalid hostname and/or port.\n");
		return false;
	}
	
	return true;
}

static bool ConnectSignals() {
	
	const proto::ServerInfo& sinfo = gServerInfo;
	printf("Connecting to signals: %s:%d ...\n", sinfo.host().c_str(), sinfo.pub());
	
	zsocket_destroy(gCtx, gSignals);
	gSignals = zsocket_new(gCtx, ZMQ_SUB);
	int err = zsocket_connect(gSignals, "tcp://%s:%d", sinfo.host().c_str(), sinfo.pub());
	if(err){
		printf("ERROR: invalid hostname and/or port.\n");
		return false;
	}
	
	const char one[2] = {1, 0};
	zsocket_set_subscribe(gSignals, one);
	
	return true;
	
}

static void ReConnectSignals() {
	
	int err = 0;
	
	const proto::ServerInfo& sinfo = gServerInfo;
	err |= zsocket_disconnect(gSignals, "tcp://%s:%d", sinfo.host().c_str(), sinfo.pub());
	err |= zsocket_connect(gSignals, "tcp://%s:%d", sinfo.host().c_str(), sinfo.pub());
	
	const char one[2] = {1, 0};
	zsocket_set_subscribe(gSignals, one);
	
	if(err){
		printf("ReConnectSignals(): FAIL\n");
	}
	
}


inline void GetNewReqNonce(proto::Request& req) {
	
	uint32_t limbs[8];
	for(int i = 0; i < 8; ++i)
		limbs[i] = rand();
	
	uint32_t tmp = limbs[0];
	for(int i = 1; i < 7; ++i)
		tmp *= limbs[i];
	
	limbs[7] = -tmp;
	req.set_reqnonce(&limbs[0], sizeof(limbs));
	
}


static void RequestWork() {
	
	if(!gServer)
		return;
	
	//printf("Requesting new work...\n");
	
	proto::Request req;
	req.set_type(proto::Request::GETWORK);
	req.set_reqid(++gNextReqID);
	req.set_version(gClientVersion);
	req.set_height(gBlock.height());
	
	GetNewReqNonce(req);
	Send(req, gServer);
	
	gRequestTimer.reset();
	
}


static void HandleNewBlock(const proto::Block& block) {
	
	if(block.height() > gBlock.height()){
		
		//printf("New Block: height=%d\n", block.height());
		
		gBlock = block;
		gClient->NotifyBlock(block);
		
		RequestWork();
		
	}
	
}


static void HandleNewWork(const proto::Work& work) {
	
	float diff = gRequestTimer.diff();
	gLatency = diff * 1000.;
	
	printf("Work received: height=%d diff=%.8g latency=%dms\n",
			work.height(), GetPrimeDifficulty(work.bits()), gLatency);
	
	gClient->TakeWork(work);
	
}


static void SubmitShare(const proto::Share& share) {
	
	proto::Request req;
	req.set_type(proto::Request::SHARE);
	req.set_reqid(++gNextReqID);
	req.set_version(gClientVersion);
	req.set_height(share.height());
	req.mutable_share()->CopyFrom(share);
	
	GetNewReqNonce(req);
	Send(req, gServer);
	
	gSharesSent[req.reqid()] = share.length();
	
}


static void PrintStats() {
	
	printf("(ST/INV/DUP):");
	for(std::map<unsigned, share_t>::const_iterator iter = gShares.begin(); iter != gShares.end(); ++iter){
		
		const share_t& share = iter->second;
		printf(" %dx %dch(%d/%d/%d)", share.accepted, iter->first, share.stale, share.invalid, share.duplicate);
		
	}
	
	if(!gShares.size())
		printf(" none");
		
	printf("\n");
	
}


static int HandleReply(zloop_t *wloop, zmq_pollitem_t *item, void *arg) {
	
	proto::Reply rep;
	Receive(rep, item->socket);
	
	//rep.PrintDebugString();
	
	if(rep.has_errstr())
		printf("Message from server: %s\n", rep.errstr().c_str());
	
	if(rep.has_block()){
		
		HandleNewBlock(rep.block());
		
	}
	
	if(rep.type() == proto::Request::GETWORK){
		
		if(rep.has_work()){
			
			HandleNewWork(rep.work());
			
		}
		
	}else if(rep.type() == proto::Request::SHARE){
		
		unsigned length = gSharesSent[rep.reqid()];
		gSharesSent.erase(rep.reqid());
		
		switch(rep.error()){
		case proto::Reply::NONE:
			printf("Share accepted.\n");
			gShares[length].accepted++;
			break;
		case proto::Reply::INVALID:
			printf("Invalid share.\n");
			gShares[length].invalid++;
			break;
		case proto::Reply::STALE:
			printf("Stale share.\n");
			gShares[length].stale++;
			ReConnectSignals();
			break;
		case proto::Reply_ErrType_DUPLICATE:
			printf("Duplicate share.\n");
			gShares[length].duplicate++;
			break;
		default: break;
		}
		
	}else if(rep.type() == proto::Request::STATS){
		
		if(rep.error() == proto::Reply::NONE)
			{}//printf("Statistics accepted.\n");
		else
			printf("Statistics rejected.\n");
		
	}else if(rep.type() == proto::Request::PING){
		
		//printf("Received heartbeat.\n");
		
	}
	
	gHeartBeat = true;
	
	return 0;
	
}


static int HandleSignal(zloop_t *wloop, zmq_pollitem_t *item, void *arg) {
	
	proto::Signal sig;
	ReceivePub(sig, item->socket);
	
	//sig.PrintDebugString();
	
	if(sig.type() == proto::Signal::NEWBLOCK){
		
		HandleNewBlock(sig.block());
		
	}else if(sig.type() == proto::Signal::SHUTDOWN){
		
		printf("Server is shutting down, reconnecting...\n");
		gExit = false;
		return -1;
		
	}
	
	return 0;
	
}


static int HandleWorkers(zloop_t *wloop, zmq_pollitem_t *item, void *arg) {
	
	proto::Share share;
	bool ret = Receive(share, item->socket);
	if(!ret)
		return 0;
	
	//share.PrintDebugString();
	SubmitShare(share);
	
	return 0;
	
}


static int HandleTimer(zloop_t *wloop, int timer_id, void *arg) {
	
	if(!gHeartBeat){
		
		printf("Connection lost, reconnecting...\n");
		gExit = false;
		return -1;
		
	}
	
	{
		proto::Request req;
		req.set_type(proto::Request::STATS);
		req.set_reqid(++gNextReqID);
		req.set_version(gClientVersion);
		req.set_height(gBlock.height());
		
		proto::ClientStats& stats = *req.mutable_stats();
		int ngpus = gClient->GetStats(stats);
		stats.set_addr(gAddr);
		stats.set_name(gClientName);
		stats.set_clientid(gClientID);
		stats.set_instanceid(gInstanceID);
		stats.set_version(gClientVersion);
		stats.set_latency(gLatency);
		stats.set_ngpus(ngpus);
		stats.set_height(gBlock.height());
		
		GetNewReqNonce(req);
		Send(req, gServer);
	}
	
	PrintStats();
	
	gHeartBeat = false;
	
	//ReConnectSignals();
	
	return 0;
	
}





int main(void) {
	
	gBlock.set_height(0);
	gClientName = sysinfo::GetClientName();
	gClientID = sysinfo::GetClientID();
	gInstanceID = gClientID * (unsigned)time(0);
	srand(gInstanceID);
	
	std::string frontHost;
	unsigned frontPort;
	
	Configuration* cfg = Configuration::create();
	try{
		cfg->parse("config.txt");
		frontHost = cfg->lookupString("", "server", "localhost");
		frontPort = cfg->lookupInt("", "port", 6666);
		gAddr = cfg->lookupString("", "address", "");
		gClientName = cfg->lookupString("", "name", gClientName.c_str());
	}catch(const ConfigurationException& ex){
		printf("ERROR: %s\n", ex.c_str());
		printf("hit return to exit...\n");
		std::string line;
		std::getline(std::cin, line);
		exit(EXIT_FAILURE);
	}
	
	if(!gClientName.size())
		gClientName = sysinfo::GetClientName();
	
	printf("madPrimeMiner-v%d.%d\n", gClientVersion/10, gClientVersion%10);
	printf("ClientName = '%s'  ClientID = %u  InstanceID = %u\n", gClientName.c_str(), gClientID, gInstanceID);
	printf("Address = '%s'\n", gAddr.c_str());
	
	if(!gAddr.size()){
		printf("ERROR: address not specified in config.txt\n");
		printf("hit return to exit...\n");
		std::string line;
		std::getline(std::cin, line);
		exit(EXIT_FAILURE);
	}
	
	gCtx = zctx_new();
	
	gWorkers = zsocket_new(gCtx, ZMQ_PULL);
	zsocket_bind(gWorkers, "inproc://shares");
	
	gClient = new XPMClient(gCtx);
	gExit = !gClient->Initialize(cfg);
	
	while(!gExit){
		
		printf("Connecting to frontend: %s:%d ...\n", frontHost.c_str(), frontPort);
		
		gBlock.Clear();
		proto::Reply rep;
		gExit = true;
		
		while(gExit){
			
			zsocket_destroy(gCtx, gFrontend);
			gFrontend = zsocket_new(gCtx, ZMQ_DEALER);
			
			int err = zsocket_connect(gFrontend, "tcp://%s:%d", frontHost.c_str(), frontPort);
			if(err){
				printf("ERROR: invalid hostname and/or port.\n");
				exit(EXIT_FAILURE);
			}
			
			proto::Request req;
			req.set_type(proto::Request::CONNECT);
			req.set_reqid(++gNextReqID);
			req.set_version(gClientVersion);
			req.set_height(0);
			
			GetNewReqNonce(req);
			Send(req, gFrontend);
			
			bool ready = zsocket_poll(gFrontend, 3*1000);
			
			if(zctx_interrupted)
				break;
			
			if(!ready)
				continue;
			
			Receive(rep, gFrontend);
			
			if(rep.error() != proto::Reply::NONE){
				printf("ERROR: %s\n", proto::Reply::ErrType_Name(rep.error()).c_str());
				if(rep.has_errstr())
					printf("Message from server: %s\n", rep.errstr().c_str());
			}
			
			if(!rep.has_sinfo())
				break;
			
			gServerInfo = rep.sinfo();
			
			bool ret = false;
			ret |= !ConnectBitcoin();
			ret |= !ConnectSignals();
			if(ret)
				break;
			
			gExit = false;
			
		}
		
		zsocket_disconnect(gFrontend, "tcp://%s:%d", frontHost.c_str(), frontPort);
		
		if(gExit)
			break;
		
		zloop_t* wloop = zloop_new();
		
		zmq_pollitem_t item_server = {gServer, 0, ZMQ_POLLIN, 0};
		int err = zloop_poller(wloop, &item_server, &HandleReply, 0);
		assert(!err);
		
		zmq_pollitem_t item_signals = {gSignals, 0, ZMQ_POLLIN, 0};
		err = zloop_poller(wloop, &item_signals, &HandleSignal, 0);
		assert(!err);
		
		zmq_pollitem_t item_workers = {gWorkers, 0, ZMQ_POLLIN, 0};
		err = zloop_poller(wloop, &item_workers, &HandleWorkers, 0);
		assert(!err);
		
		err = zloop_timer(wloop, 60*1000, 0, &HandleTimer, 0);
		assert(err >= 0);
		
		gHeartBeat = true;
		gExit = true;
		
		if(rep.has_block())
			HandleNewBlock(rep.block());
		else
			RequestWork();
		
		gClient->Toggle();
		zloop_start(wloop);
		
		gClient->Toggle();
		zloop_destroy(&wloop);
		
		zsocket_destroy(gCtx, gServer);
		zsocket_destroy(gCtx, gSignals);
		
		gServer = 0;
		gSignals = 0;
		
	}
	
	delete gClient;
	
	zsocket_destroy(gCtx, gWorkers);
	zsocket_destroy(gCtx, gFrontend);
	zctx_destroy(&gCtx);
	
	return EXIT_SUCCESS;
	
}













