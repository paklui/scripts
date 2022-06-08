#!/bin/bash

DATE=$(date +%y%m%d_%H%M%S)
export INSTALL_DIR=$PWD
export ROCM_DIR=/opt/rocm
export GDR_DIR=$INSTALL_DIR/gdrcopy
export XPMEM_DIR=${INSTALL_DIR}/xpmem
export UCX_DIR=$INSTALL_DIR/ucx
export OMPI_DIR=$INSTALL_DIR/ompi
export LD_LIBRARY_PATH=$GDR_DIR/lib64:$LD_LIBRARY_PATH
export MPIRUN=$OMPI_DIR/bin/mpirun
LOG=log.setup-${DATE}.txt

# for OMPI and UCX
# sudo apt install -y automake autoconf libtool m4 flex libnuma-dev libpciaccess-dev vim git wget
# for XPMEM
# sudo apt install linux-source linux-hwe-5.13-source-5.13.0 linux-hwe-5.13-headers-5.13.0-35 linux-tools-$(uname -r)

SetupGDRcopy () {
    if [ "$1" = true ]; then
        echo "Cloning fresh copy of GDRcopy"
        rm -rf gdrcopy || return 1
                git clone https://github.com/NVIDIA/gdrcopy.git -b v1.3
                #git clone https://github.com/NVIDIA/gdrcopy.git # api issue
                cd gdrcopy || return 1
                mkdir -p $GDR_DIR/lib64 $GDR_DIR/include
                make PREFIX=$GDR_DIR lib install driver
        ./insmod.sh
        cd ..  || return 1
    fi
}

SetupXPMEM () {
    if [ "$1" = true ]; then
        echo "Cloning fresh copy of XPMEM"
        rm -rf xpmem || return 1
        git clone https://github.com/hjelmn/xpmem.git
    fi
    cd xpmem || return 1
    ./autogen.sh
    ./configure --prefix=${UCX_DIR}
    make -j
    make install
    sudo insmod ${UCX_DIR}/lib/modules/$(uname -r)/kernel/xpmem/xpmem.ko
    cd ..  || return 1
}


# Function to setup UCX (set input to true to do fresh clone from git)
SetupUCX () {
    if [ "$1" = true ]; then
        echo "Cloning fresh copy of UCX"
        rm -rf ucx || return 1
        git clone https://github.com/openucx/ucx.git -b v1.13.x || return 1
        cd ucx  || return 1
        ./autogen.sh 2>&1 | tee -a $LOG || return 1
        cd ..  || return 1
    fi

    cd ucx || return 1
    mkdir -p build  || return 1
    cd build  || return 1
    #../contrib/configure-release --prefix=${UCX_DIR} --with-rocm=$ROCM_DIR --with-gdrcopy=${GDR_DIR} --enable-gtest --enable-examples --with-mpi=${OMPI_DIR} --enable-mt 2>&1 | tee -a $LOG|| return 1
    #../contrib/configure-release --prefix=${UCX_DIR} --with-rocm=$ROCM_DIR --enable-gtest --enable-examples --with-mpi=${OMPI_DIR} --with-xpmem=${XPMEM_DIR} 2>&1 | tee -a $LOG|| return 1
    ../contrib/configure-release --prefix=${UCX_DIR} --with-rocm=$ROCM_DIR --enable-gtest --enable-examples --with-mpi=${OMPI_DIR} 2>&1 | tee -a $LOG|| return 1
    make -j 8  2>&1 | tee -a $LOG || return 1
    make install 2>&1 | tee -a $LOG || return 1
    cd ../..  || return 1
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

    cd ompi || return 1
    mkdir build || return 1
    cd build || return 1
    ../configure --prefix=$OMPI_DIR --with-ucx=$UCX_DIR --enable-mca-no-build=btl-uct || return 1
    make -j 8 || return 1
    make install || return 1
    cd ../..
}

# Function to setup OSU benchmarks
SetupOSUBenchmarks () {
    if [ "$1" = true ]; then
        echo "Cloning fresh copy of OSU benchmarks"
        rm -rf osu
        wget --no-check-certificate https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.9.tar.gz
        tar xvf osu-micro-benchmarks-5.9.tar.gz
        mv osu-micro-benchmarks-5.9 osu
    fi

    cd osu || return 1
        autoreconf -ivf || return 1
        ./configure --enable-rocm --with-rocm=$ROCM_DIR CC=$OMPI_DIR/bin/mpicc CXX=$OMPI_DIR/bin/mpicxx LDFLAGS="-L${OMPI_DIR}/lib/ -lmpi -L${ROCM_DIR}/lib/ -lamdhip64 -Wl,-rpath=${ROCM_DIR}/lib" CPPFLAGS="-std=c++11" || return 1
    make -j 8 || return 1
    cd .. || return 1
}

# Function to run intranode (domestic) tests
RunDomesticTests () {
    for TEST in osu_latency osu_bw; do
        for MEM1 in D ; do
        for MEM2 in D ; do
            LOG=log.${TEST}-${MEM1}MEM1-${MEM2}MEM2-${HOSTNAME}-${DATE}.txt
            OPTION="-x UCX_RNDV_PIPELINE_SEND_THRESH=256k -x UCX_RNDV_FRAG_SIZE=rocm:4m "
            #OPTION="-x UCX_RNDV_PIPELINE_SEND_THRESH=256k "
            #OPTION="-x UCX_RNDV_PIPELINE_SEND_THRESH=256k "
            OPTION+="-x UCX_RNDV_THRESH=128 "

            #CMD="$MPIRUN -np 2 -x UCX_RNDV_THRESH=8192 --mca osc ucx --mca spml ucx -x LD_LIBRARY_PATH -x UCX_LOG_LEVEL=TRACE_DATA --allow-run-as-root -mca pml ucx -x UCX_TLS=sm,self,rocm_copy,rocm_ipc,rocm_gdr osu/mpi/pt2pt/${TEST} -d rocm $MEM1 $MEM2 0 1"
            CMD="$MPIRUN -np 2 $OPTION --mca osc ucx --mca spml ucx -x LD_LIBRARY_PATH -x UCX_LOG_LEVEL=TRACE_DATA --allow-run-as-root -mca pml ucx -x UCX_TLS=sm,self,rocm_copy,rocm_ipc osu/mpi/pt2pt/${TEST} -d rocm $MEM1 $MEM2 "
            echo $CMD
            echo $CMD >> $LOG
                 $CMD 2>&1 | tee -a $LOG || return 1
        done
        done
    done
}

# Function to run internode (international) tests
RunInternationalTests () {
    $MPIRUN -np 2 -x UCX_IB_REG_METHODS=odp -x LD_LIBRARY_PATH=${ROCM_DIR}/lib --host localhost,localhost --mca pml ucx -x UCX_LOG_LEVEL=TRACE -x UCX_TLS=rc,sm,rocm_copy,rocm_ipc osu/mpi/pt2pt/osu_bw -d rocm D D 0 1 || return 1
}

# Set parameter to true to do fresh clone from git, otherwise only recompiles
#SetupGDRcopy       $1 || { echo "[ERROR] Unable to install GDRcopy";  exit 1; }
#SetupXPMEM         $1 || { echo "[ERROR] Unable to install XPMEM"     exit 1; }
SetupUCX           $1 || { echo "[ERROR] Unable to install UCX";      exit 1; }
SetupOpenMPI       $1 || { echo "[ERROR] Unable to install OpenMPI";  exit 1; }
SetupOSUBenchmarks $1 || { echo "[ERROR] Unable to install OSUbench"; exit 1; }

RunDomesticTests      || { echo "[ERROR] Unable to run domestic tests";      exit 1; }
#RunInternationalTests || { echo "[ERROR] Unable to run international tests"; exit 1; }
