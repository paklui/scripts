#!/bin/bash

#BASEDIR=${HOME}/install
BASEDIR=/opt/singularity
mkdir $BASEDIR
cd $BASEDIR

export VERSION=1.16.4 OS=linux ARCH=amd64
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
tar -C $BASEDIR -xzvf go$VERSION.$OS-$ARCH.tar.gz
rm go$VERSION.$OS-$ARCH.tar.gz

echo "export GOPATH=${BASEDIR}/go" >> ${BASEDIR}/env.bashrc
echo 'export PATH=${BASEDIR}/go/bin:${PATH}:${BASEDIR}/bin' >> ${BASEDIR}/env.bashrc
chmod a+x ${BASEDIR}/env.bashrc
source ${BASEDIR}/env.bashrc
which go
#/usr/bin/go

export VERSION=3.7.3 && # adjust this as necessary
    mkdir -p $GOPATH/src/github.com/sylabs &&
    cd $GOPATH/src/github.com/sylabs &&
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz &&
    tar -xzf singularity-${VERSION}.tar.gz &&
    cd ./singularity &&
    #./mconfig --without-suid --prefix=$BASEDIR &&
    ./mconfig --prefix=$BASEDIR &&
    make -C ./builddir &&
    make -C ./builddir install

which singularity
#/usr/local/bin/singularity
