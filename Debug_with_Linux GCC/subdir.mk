################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../adl.cpp \
../baseclient.cpp \
../prime.cpp \
../primes.cpp \
../protocol.pb.cpp \
../sha256.cpp \
../xpmclient.cpp 

OBJS += \
./adl.o \
./baseclient.o \
./prime.o \
./primes.o \
./protocol.pb.o \
./sha256.o \
./xpmclient.o 

CPP_DEPS += \
./adl.d \
./baseclient.d \
./prime.d \
./primes.d \
./protocol.pb.d \
./sha256.d \
./xpmclient.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	g++ -I../../config4cpp/include -I/opt/AMDAPP/include/ -O0 -g3 -Wall -c -fmessage-length=0 -std=c++0x -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


