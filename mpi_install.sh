#!/bin/bash

set -e

export SOURCE_DIR=$(dirname $(readlink -f "$0"))
export OMPI_SRC=ompi-master
export UCX_SRC=ucx-master

usage(){
    echo "Usage: ./mpi_install.sh X.X VERSION_NAME VERSION MODULE"
    echo "Example: ./mpi_install.sh 7.4 dev debug all"
    echo "         mpi(ompi&ucx) is installed at ${HOME}/mpi/dev"
    echo "prerequisite:"
    echo "    1. ${SOURCE_DIR}${VERSION_NAME}/${OMPI_SRC}.tar.gz exists"
    echo "    2. ${SOURCE_DIR}${VERSION_NAME}/${UCX_SRC}.tar.gz exists"
    echo "    3. gcc is installed at ${HOME}/gcc/X.X"
    echo "    4. version could be debug or release(if it is not debug)"
    echo "    5. module could be all, ucx or ompi"
}

if [ ${#} -ne 4 ] ||
[ ! -d ${HOME}/gcc/${1} ] ||
[ ! -f ${SOURCE_DIR}/${2}/${OMPI_SRC}.tar.gz ] ||
[ ! -f ${SOURCE_DIR}/${2}/${UCX_SRC}.tar.gz ];
then
    usage
    exit -1
fi

export GCC_DIR=${HOME}/gcc/${1}
export INSTALL_DIR=${HOME}/mpi/${2}
export PATH=${GCC_DIR}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/ibutils/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALL_DIR}/lib:${INSTALL_DIR}/lib64
if [ "$3" == "debug" ]; then
    UCX_CONFIG_OPT="configure-devel"
    UCX_DEBUG_OPT="--enable-debug --enable-experimental-api"
    OMPI_DEBUG_OPT="--disable-picky --enable-debug --enable-mpi1-compatibility"
    SEC_CFLAGS="-std=gnu99"
    SEC_CXXFLAGS="-std=gnu++11"
    SEC_OPT="CFLAGS=\"${SEC_CFLAGS}\" CXXFLAGS=\"${SEC_CXXFLAGS}\""
else
    UCX_CONFIG_OPT="configure-opt"
    UCX_DEBUG_OPT=""
    OMPI_DEBUG_OPT="--with-platform=contrib/platform/mellanox/optimized --enable-mpi1-compatibility"
    SEC_CFLAGS="-fstack-protector-strong -fPIE -pie"
    SEC_LDFLAGS="-Wl,-z,relro,-z,now,-z,noexecstack,-s"
    SEC_OPT="--with-pic CFLAGS=\"${SEC_CFLAGS}\" CXXFLAGS=\"${SEC_CFLAGS}\" LDFLAGS=${SEC_LDFLAGS}"
fi
echo "Installing MPI(ompi&ucx) on ${INSTALL_DIR}"

mkdir -p ${INSTALL_DIR}
cd ${SOURCE_DIR}/${2}

if [ "$4" == "all"] || [ "$4" == "ucx" ]; then
    if [ ! -d ${UCX_SRC} ]; then
        tar -zxvf ${UCX_SRC}.tar.gz
    fi
    cd ${UCX_SRC}/
    ./autogen.sh
    eval ./contrib/${UCX_CONFIG_OPT} --prefix=${INSTALL_DIR} ${UCX_DEBUG_OPT} ${SEC_OPT}
    make -j$(nproc)
    if [ ! ${?} -eq 0 ]; then
        echo "Building failed for error in ${UCX_SRC}!"
        exit -1
    fi
    make install
    cd ..
fi

if [ "$4" == "all"] || [ "$4" == "ompi" ]; then
    if [ ! -d ${OMPI_SRC} ]; then
        tar -zxvf ${OMPI_SRC}.tar.gz
    fi
    cd ${OMPI_SRC}/
    ./autogen.pl
    eval ./configure --prefix=${INSTALL_DIR} --with-ucx=${INSTALL_DIR} ${OMPI_DEBUG_OPT} ${SEC_OPT}
    make -j$(nproc)
    if [ ! ${?} -eq 0 ]; then
        echo "Building failed for error in ${OMPI_SRC}!"
        exit -1
    fi
    make install
    cd ..
fi
