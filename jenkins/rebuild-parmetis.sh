#module use /opt/nvidia/hpc_sdk/modulefiles
#module load nvhpc
module use ${HOME}/modulefiles
module load gcc/11.2.0
module load ompi-4.1.x/ucx-1.10.x/gcc-11.2.0

#wget http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz
#tar xvfz parmetis-4.0.3.tar.gz
#export parmetis_path=$PWD/ParMetis-4.0.3_64Bit_gcc-9.3
export parmetis_path=$PWD/parmetis-4.0.3/install

cd parmetis-4.0.3
sed -i'' -e 's/define IDXTYPEWIDTH 32/define IDXTYPEWIDTH 64/' metis/include/metis.h
sed -i'' -e 's/define REALTYPEWIDTH 32/define REALTYPEWIDTH 64/' metis/include/metis.h
make config cc=mpicc cxx=mpic++ CFLAGS="-march=native -fPIC" CXXFLAGS="-march=native -fPIC" prefix=$parmetis_path \
&& make -j12 install \
&& cd metis \
&& make config cc=gcc cxx=g++ CFLAGS="-march=native -fPIC" CXXFLAGS="-march=native -fPIC" prefix=$parmetis_path \
&& make -j12 install
