#!/bin/bash

set -e

export WORKSPACE=$(dirname $(readlink -f "$0"))/..
export OMPI_SRC=hmpi
export UCX_SRC=hucx

usage(){
    echo "Usage: ./mpi_install.sh VERSION MODULE"
    echo "Example: ./mpi_install.sh debug all"
    echo "         mpi(ompi&ucx) is installed at ${WORKSPACE}/mpi_debug"
    echo "prerequisite:"
    echo "    1. ${WORKSPACE}/${OMPI_SRC} exists"
    echo "    2. ${WORKSPACE}/${UCX_SRC} exists"
    echo "    3. version could be debug or release(if it is not debug)"
    echo "    4. module could be all, ucx or ompi"
}

if [ ${#} -ne 2 ] ||
[ ! -d ${WORKSPACE}/${OMPI_SRC} ] ||
[ ! -d ${WORKSPACE}/${UCX_SRC} ];
then
    usage
    exit -1
fi

sudo apt-get install valgrind numactl libnuma-dev
export INSTALL_DIR=${WORKSPACE}/mpi_${1}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALL_DIR}/lib:${INSTALL_DIR}/lib64
mkdir -p ${INSTALL_DIR}
if [ "${1}" == "debug" ]; then
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

if [ "${2}" == "all" ] || [ "${2}" == "ucx" ]; then
    cd ${WORKSPACE}/${UCX_SRC}
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

if [ "${2}" == "all" ] || [ "${2}" == "ompi" ]; then
    cd ${WORKSPACE}/${OMPI_SRC}
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

