#!/bin/bash

#MPC=mpc-0.8.2
MPC=mpc-1.2.1

#MPFR=mpfr-2.4.2
MPFR=mpfr-4.1.0

#GMP=gmp-5.0.2
GMP=gmp-6.2.0

ISL=isl-0.15

#GCC=gcc-8.3.0
GCC=gcc-11.2.0

DATE=$(date +%y%m%d_%H%M%S)

#BASE_DIR=${HOME}/gcc
#BASE_DIR=/usr/local/src
#BASE_DIR=/usr/local/pkgs
BASE_DIR=/opt/gcc
export            PATH=${BASE_DIR}/${MPC}/bin:${PATH}
export LD_LIBRARY_PATH=${BASE_DIR}/${MPC}/lib:${LD_LIBRARY_PATH}
export            PATH=${BASE_DIR}/${MPFR}/bin:${PATH}
export LD_LIBRARY_PATH=${BASE_DIR}/${MPFR}/lib:${LD_LIBRARY_PATH}
export            PATH=${BASE_DIR}/${GMP}/bin:${PATH}
export LD_LIBRARY_PATH=${BASE_DIR}/${GMP}/lib:${LD_LIBRARY_PATH}
export            PATH=${BASE_DIR}/${ISL}/bin:${PATH}
export LD_LIBRARY_PATH=${BASE_DIR}/${ISL}/lib:${LD_LIBRARY_PATH}
#export            PATH=${BASE_DIR}/${GCC}/bin:${PATH}
#export LD_LIBRARY_PATH=${BASE_DIR}/${GCC}/lib:${LD_LIBRARY_PATH}

wget -c https://ftp.gnu.org/gnu/gmp/${GMP}.tar.bz2
tar xf ${GMP}.tar.bz2
cd $GMP
LOG=log.${GMP}-${DATE}.txt
./configure --prefix=${BASE_DIR}/${GMP} 2>&1 | tee -a $LOG
make clean
make -j install 2>&1 | tee -a $LOG
cd ..

wget -c https://ftp.gnu.org/gnu/mpfr/${MPFR}.tar.gz
tar xf ${MPFR}.tar.gz
LOG=log.${MPFR}-${DATE}.txt
cd $MPFR
mkdir -p ${BASE_DIR}/${MPFR}
./configure --prefix=${BASE_DIR}/${MPFR} --with-gmp=${BASE_DIR}/${GMP} 2>&1 | tee -a $LOG
make clean
make -j install 2>&1 | tee -a $LOG
cd ..

wget -c https://ftp.gnu.org/gnu/mpc/${MPC}.tar.gz
tar xf ${MPC}.tar.gz
LOG=log.${MPC}-${DATE}.txt
cd $MPC
mkdir -p ${BASE_DIR}/${MPC}
./configure --prefix=${BASE_DIR}/${MPC} --with-gmp=${BASE_DIR}/${GMP} --with-mpfr=${BASE_DIR}/${MPFR} 2>&1 | tee -a $LOG
make clean
make -j install 2>&1 | tee -a $LOG
cd ..

wget -c https://gcc.gnu.org/pub/gcc/infrastructure/${ISL}.tar.bz2
tar xf ${ISL}.tar.bz2
LOG=log.${ISL}-${DATE}.txt
cd $ISL
rm -fr build; mkdir build; cd build
mkdir -p ${BASE_DIR}/${ISL}
../configure --prefix=${BASE_DIR}/${ISL} --with-gmp-prefix=${BASE_DIR}/${GMP} 2>&1 | tee -a $LOG
make -j install 2>&1 | tee -a $LOG
cd .. # from build
cd .. # back to base

wget -c https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/${GCC}.tar.gz
tar xf ${GCC}.tar.gz
LOG=log.${GCC}-${DATE}.txt
cd $GCC
mkdir -p ${BASE_DIR}/${GCC}
#echo ./configure --prefix=${BASE_DIR}/${GCC} --with-gmp=${BASE_DIR}/${GMP} --with-mpfr=${BASE_DIR}/${MPFR} --with-mpc=${BASE_DIR}/${MPC} --with-isl=${BASE_DIR}/${ISL} 2>&1 | tee -a $LOG
./configure --prefix=${BASE_DIR}/${GCC} --with-gmp=${BASE_DIR}/${GMP} --with-mpfr=${BASE_DIR}/${MPFR} --with-mpc=${BASE_DIR}/${MPC} --with-isl=${BASE_DIR}/${ISL} 2>&1 | tee -a $LOG
make -j 2>&1 | tee -a $LOG
make install 2>&1 | tee -a $LOG
cd ..
