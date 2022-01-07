#!/bin/bash

BASEDIR=${HOME}/install
#BASEDIR=/opt/singularity
mkdir $BASEDIR
cd $BASEDIR

#
# setup go
#

export VERSION=1.17.2 OS=linux ARCH=amd64
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
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

export VERSION=3.9.0-rc.3 && # adjust this as necessary \
wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz && \
tar -xzf singularity-ce-${VERSION}.tar.gz && \
cd singularity-ce-${VERSION}
#./mconfig && \
#./mconfig --prefix=/opt/singularity
./mconfig --prefix=$BASEDIR
make -C ./builddir && \
make -C ./builddir install

which go
which singularity
#/usr/local/bin/singularity
