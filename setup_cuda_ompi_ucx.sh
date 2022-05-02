#!/bin/bash

#apt install m4 libtool automake autoconf flex build-essential libnuma-dev binutils libbinutils binutils-dev

DATE=$(date +%y%m%d_%H%M%S)
export INSTALL_DIR=$PWD
export MY_UCX_DIR=$INSTALL_DIR/ucx
export OMPI_DIR=$INSTALL_DIR/ompi
export GDR_DIR=$INSTALL_DIR/gdrcopy
export PATH=/usr/local/cuda/bin:${PATH}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=$GDR_DIR/lib64:$LD_LIBRARY_PATH
export MPIRUN=$OMPI_DIR/bin/mpirun
LOG=log.setup-${DATE}.txt
SetupGDRcopy () {
 if [ "$1" = true ]; then
 echo "Cloning fresh copy of GDRcopy"
 rm -rf gdrcopy || return 1
 sudo apt install -y build-essential devscripts debhelper check libsubunit-dev
 #git clone https://github.com/NVIDIA/gdrcopy.git -b v1.3
 git clone https://github.com/NVIDIA/gdrcopy.git
 cd gdrcopy || return 1
 mkdir -p $GDR_DIR/lib64 $GDR_DIR/include
 make PREFIX=$GDR_DIR lib install driver
 ./insmod.sh
 cd .. || return 1
 fi
}
# Function to setup UCX (set input to true to do fresh clone from git)
SetupUCX () {
 if [ "$1" = true ]; then
 echo "Cloning fresh copy of UCX"
 rm -rf ucx || return 1
 git clone https://github.com/openucx/ucx.git -b v1.10.x || return 1
 cd ucx || return 1
 ./autogen.sh 2>&1 | tee -a $LOG || return 1
 cd .. || return 1
 fi
cd ucx || return 1
 mkdir -p build || return 1
 cd build || return 1
 ../contrib/configure-release --prefix=${MY_UCX_DIR} --with-cuda=/usr/local/cuda --without-rocm --with-gdrcopy=${GDR_DIR} --enable-gtest --enable-examples --with-mpi=${OMPI_DIR} --enable-mt 2>&1 | tee -a $LOG|| return 1
 make -j 8 2>&1 | tee -a $LOG || return 1
 make install 2>&1 | tee -a $LOG || return 1
 cd ../.. || return 1
}
# Function to setup OpenMPI
SetupOpenMPI () {
 if [ "$1" = true ]; then
 echo "Cloning fresh copy of OpenMPI"
 rm -rf ./ompi
 git clone https://github.com/open-mpi/ompi.git -b v4.1.x || return 1
 cd ompi || return 1
 ./autogen.pl || return 1
 cd ..
 fi
pwd
 cd ompi || return 1
 mkdir build || return 1
 cd build || return 1
 CC=gcc CXX=g++ FC=gfortran F90=gfortran ../configure --enable-mpirun-prefix-by-default --prefix=$OMPI_DIR --with-ucx=$MY_UCX_DIR --with-cuda=/usr/local/cuda --enable-mca-no-build=btl-uct || return 1
 make -j 8 || return 1
 make install || return 1
 cd ../..
}
# Function to setup OSU benchmarks
SetupOSUBenchmarks () {
 if [ "$1" = true ]; then
 echo "Cloning fresh copy of OSU benchmarks"
 rm -rf osu
 wget http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.9.tar.gz
 tar xfz osu-micro-benchmarks-5.9.tar.gz
 mv osu-micro-benchmarks-5.9 osu
 fi
cd osu || return 1
 autoreconf -ivf || return 1
 NVCCFLAGS="-allow-unsupported-compiler" CC=${OMPI_DIR}/bin/mpicc CXX=${OMPI_DIR}/bin/mpicxx ./configure --enable-cuda --with-cuda=/usr/local/cuda --with-cuda-include=/usr/local/cuda/include --with-cuda-libpath=/usr/local/cuda/lib64 LDFLAGS="-L$OMPI_DIR/lib -lmpi -L/usr/local/cuda/lib64 -lcudart"
 make -j || return 1
 cd .. || return 1
}
# Function to run intranode (domestic) tests
RunDomesticTests () {
 #for TEST in osu_latency osu_bw; do
 for TEST in osu_latency osu_bw; do
 #for TEST in osu_latency ; do
 #for MEM1 in H ; do
 #for MEM2 in H ; do
 for MEM1 in D ; do
 for MEM2 in D ; do
 #for MEM1 in M ; do
 #for MEM2 in M ; do
 #for MEM1 in MH ; do
 #for MEM2 in MD ; do
 for DEVICE in cuda; do
 #for DEVICE in managed; do
 LOG=log.${TEST}-${MEM1}MEM1-${MEM2}MEM2-${HOSTNAME}-${DATE}.txt
 #CMD="$MPIRUN -np 2 --mca osc ucx --mca spml ucx -x LD_LIBRARY_PATH -x UCX_LOG_LEVEL=TRACE_DATA --allow-run-as-root -mca pml ucx osu/mpi/pt2pt/${TEST} -d cuda $MEM1 $MEM2 "
 CMD="$MPIRUN -np 2 --mca osc ucx --mca spml ucx -x LD_LIBRARY_PATH -x UCX_LOG_LEVEL=TRACE_DATA --allow-run-as-root -mca pml ucx osu/mpi/pt2pt/${TEST} -d $DEVICE $MEM1 $MEM2 "
 echo $CMD
 echo $CMD >> $LOG
 $CMD 2>&1 | tee -a $LOG || return 1
 done
 done
 done
 done
}
# Function to run internode (international) tests
RunInternationalTests () {
 $MPIRUN -np 2 -x UCX_IB_REG_METHODS=odp -x LD_LIBRARY_PATH=/usr/local/cuda/lib64 --host localhost,localhost --mca pml ucx -x UCX_LOG_LEVEL=TRACE -x UCX_TLS=rc,sm,cuda,cuda_copy,cuda_ipc,gdr_copy osu/mpi/pt2pt/osu_bw -d cuda D D || return 1
}
# Set parameter to true to do fresh clone from git, otherwise only recompiles
SetupGDRcopy $1 || { echo "[ERROR] Unable to install GDRcopy"; exit 1; }
SetupUCX $1 || { echo "[ERROR] Unable to install UCX"; exit 1; }
SetupOpenMPI $1 || { echo "[ERROR] Unable to install OpenMPI"; exit 1; }
SetupOSUBenchmarks $1 || { echo "[ERROR] Unable to install OSUbench"; exit 1; }

RunDomesticTests || { echo "[ERROR] Unable to run domestic tests"; exit 1; }
#RunInternationalTests || { echo "[ERROR] Unable to run international tests"; exit 1; }
