#ifndef __ADL_H__
#define __ADL_H__
#define HAVE_ADL
#ifdef HAVE_ADL

#include "adl_sdk.h"
#include <ctime>

#define MAX_GPUDEVICES 16
#define MAX_DEVICES 4096


enum dev_enable {
	DEV_ENABLED,
	DEV_DISABLED,
	DEV_RECOVER,
};

enum dev_reason {
	REASON_THREAD_FAIL_INIT,
	REASON_THREAD_ZERO_HASH,
	REASON_THREAD_FAIL_QUEUE,
	REASON_DEV_SICK_IDLE_60,
	REASON_DEV_DEAD_IDLE_600,
	REASON_DEV_NOSTART,
	REASON_DEV_OVER_HEAT,
	REASON_DEV_THERMAL_CUTOFF,
	REASON_DEV_COMMS_ERROR,
	REASON_DEV_THROTTLE,
};

enum alive {
	LIFE_WELL,
	LIFE_SICK,
	LIFE_DEAD,
	LIFE_NOSTART,
	LIFE_INIT,
};

struct gpu_adl {
	ADLTemperature lpTemperature;
	int iAdapterIndex;
	int lpAdapterID;
	int iBusNumber;
	char strAdapterName[256];

	ADLPMActivity lpActivity;
	ADLODParameters lpOdParameters;
	ADLODPerformanceLevels *DefPerfLev;
	ADLFanSpeedInfo lpFanSpeedInfo;
	ADLFanSpeedValue lpFanSpeedValue;
	ADLFanSpeedValue DefFanSpeedValue;

	int iEngineClock;
	int iMemoryClock;
	int iVddc;
	int iPercentage;

	bool autofan;
	bool autoengine;
	bool managed; /* Were the values ever changed on this card */

	int lastengine;
	int lasttemp;
	int targetfan;
	int targettemp;
	int overtemp;
	int minspeed;
	int maxspeed;

	int gpu;
	bool has_fanspeed;
	struct gpu_adl *twin;
};

struct cgpu_info {
	int cgminer_id;
	//struct device_drv *drv;
	int device_id;
	char *name;
	char *device_path;
	void *device_data;
	enum dev_enable deven;
	int accepted;
	int rejected;
	int hw_errors;
	double rolling;
	double total_mhashes;
	double utility;
	enum alive status;
	char init[40];
	struct timeval last_message_tv;

	int threads;
	//struct thr_info **thr;

	//int64_t max_hashes;

	const char *kname;
	bool mapped;
	int virtual_gpu;
	int virtual_adl;
	int intensity;
	bool dynamic;

	//cl_uint vwidth;
	//size_t work_size;
	//enum cl_kernels kernel;
	//cl_ulong max_alloc;

	struct timeval tv_gpustart;
	int intervals;

	bool new_work;

	float temp;
	int cutofftemp;

#ifdef HAVE_ADL
	bool has_adl;
	struct gpu_adl adl;

	int gpu_engine;
	int min_engine;
	int gpu_fan;
	int min_fan;
	int gpu_memclock;
	int gpu_memdiff;
	int gpu_powertune;
	float gpu_vddc;
#endif
	int diff1;
	double diff_accepted;
	double diff_rejected;
	int last_share_pool;
	time_t last_share_pool_time;
	double last_share_diff;
	time_t last_device_valid_work;

	time_t device_last_well;
	time_t device_last_not_well;
	enum dev_reason device_not_well_reason;
	int thread_fail_init_count;
	int thread_zero_hash_count;
	int thread_fail_queue_count;
	int dev_sick_idle_60_count;
	int dev_dead_idle_600_count;
	int dev_nostart_count;
	int dev_over_heat_count;	// It's a warning but worth knowing
	int dev_thermal_cutoff_count;
	int dev_comms_error_count;
	int dev_throttle_count;

	//struct cgminer_stats cgminer_stats;

	//pthread_rwlock_t qlock;
	//struct work *queued_work;
	//struct work *unqueued_work;
	unsigned int queued_count;

	bool shutdown;

	struct timeval dev_start_tv;
};

extern struct cgpu_info gpus[MAX_GPUDEVICES];

extern bool adl_active;
extern bool opt_reorder;
extern int opt_hysteresis;
extern const int opt_targettemp;
extern const int opt_overheattemp;
extern const int opt_cutofftemp;

void init_adl(int nDevs);
float gpu_temp(int gpu);
int gpu_engineclock(int gpu);
int gpu_memclock(int gpu);
float gpu_vddc(int gpu);
int gpu_activity(int gpu);
int gpu_fanspeed(int gpu);
int gpu_fanpercent(int gpu);
int gpu_powertune(int gpu);
bool gpu_stats(int gpu, float *temp, int *engineclock, int *memclock, float *vddc,
	       int *activity, int *fanspeed, int *fanpercent, int *powertune);
void change_gpusettings(int gpu);
void gpu_autotune(int gpu, enum dev_enable *denable);
int set_fanspeed(int gpu, int iFanSpeed);
int set_engineclock(int gpu, int iEngineClock);
int set_memoryclock(int gpu, int iMemoryClock);
int set_vddc(int gpu, float fVddc);
void set_defaultfan(int gpu);
void set_defaultengine(int gpu);
int set_powertune(int gpu, int iPercentage);
void clear_adl(int nDevs);
#else /* HAVE_ADL */
#define adl_active (0)
static inline void init_adl(__maybe_unused int nDevs) {}
static inline void change_gpusettings(__maybe_unused int gpu) { }
static inline void clear_adl(__maybe_unused int nDevs) {}
#endif
#endif
