#!/bin/bash

# create directory called ${HOME}/singularity, or /opt/singularity, and have this script to execute in that directory
#BASEDIR=${HOME}/singularity/install
BASEDIR=/opt/singularity
mkdir $BASEDIR
cd $BASEDIR

#
# setup go
#

export VERSION=1.17.2 OS=linux ARCH=amd64
wget -c https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
tar -C $BASEDIR -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
rm go$VERSION.$OS-$ARCH.tar.gz

echo "export BASEDIR=${BASEDIR}" >> ${BASEDIR}/env.bashrc
echo "export GOPATH=${BASEDIR}/go" >> ${BASEDIR}/env.bashrc
echo 'export PATH=${BASEDIR}/go/bin:${PATH}:${BASEDIR}/bin' >> ${BASEDIR}/env.bashrc
chmod a+x ${BASEDIR}/env.bashrc
source ${BASEDIR}/env.bashrc

#
# setup singularity
#

#wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz && \
#tar -xzvf singularity-ce-${VERSION}.tar.gz && \

export VERSION=3.9.9 && # adjust this as necessary \
git clone git@github.com:sylabs/singularity.git -b v${VERSION} singularity-ce-${VERSION} \
cd singularity-ce-${VERSION}
#./mconfig && \
#./mconfig --prefix=/opt/singularity
./mconfig --prefix=$BASEDIR --without-suid
make -C ./builddir && \
make -C ./builddir install

which go
which singularity
