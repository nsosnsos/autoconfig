#!/bin/bash

set -e

export SOURCE_DIR=$(dirname $(readlink -f "$0"))
export GMP_SRC=gmp-6.2.0
export MPFR_SRC=mpfr-4.0.2
export MPC_SRC=mpc-1.1.0
export ISL_SRC=isl-0.18
export VALGRIND_SRC=valgrind-3.15.0
export NUMA_SRC=numactl-2.0.13

usage(){
    echo "Usage: ./gcc_install.sh X.X"
    echo "Example: ./gcc_install.sh 7.4"
    echo "         gcc-7.4.0 is installed at ${HOME}/gcc/7.4"
    echo "prerequisite:"
    echo "    1. ${SOURCE_DIR}${GMP_SRC}.tar.bz2 exists"
    echo "    2. ${SOURCE_DIR}${MPFR_SRC}.tar.bz2 exists"
    echo "    3. ${SOURCE_DIR}${MPC_SRC}.tar.gz exists"
    echo "    4. ${SOURCE_DIR}${ISL_SRC}.tar.bz2 exists"
    echo "    5. ${SOURCE_DIR}gcc-X.X.0.tar.gz exists"
    echo "    6. ${SOURCE_DIR}${VALGRIND_SRC}.tar.bz2 exists"
    echo "    7. ${SOURCE_DIR}${NUMA_SRC}.tar.gz exists"
}

if [ ${#} -ne 1 ] ||
[ ! -f ${SOURCE_DIR}/${GMP_SRC}.tar.bz2 ] ||
[ ! -f ${SOURCE_DIR}/${MPFR_SRC}.tar.bz2 ] ||
[ ! -f ${SOURCE_DIR}/${MPC_SRC}.tar.gz ] ||
[ ! -f ${SOURCE_DIR}/${ISL_SRC}.tar.bz2 ] ||
[ ! -f ${SOURCE_DIR}/gcc-${1}.0.tar.gz ] ||
[ ! -f ${SOURCE_DIR}/${VALGRIND_SRC}.tar.bz2 ] ||
[ ! -f ${SOURCE_DIR}/${NUMA_SRC}.tar.gz ];
then
    usage
    exit -1
fi

export INSTALL_DIR=${HOME}/gcc/${1}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${INSTALL_DIR}/lib:${INSTALL_DIR}/lib64
echo "Installing gcc-${1}.0 at ${INSTALL_DIR}"

mkdir -p ${INSTALL_DIR}
cd ${SOURCE_DIR}/

arch=$(uname -m)
if [ ${arch} == "X86_6489" ]; then
    export GLIBCHDR=/home/glibc-2.30/build/install/include
    export KERNELHDR=/usr/src/kernels/$(uname -r)/include/uapi
    export C_INCLUDE_PATH=${C_INCLUDE_PATH}:${GLIBCHDR}:${KERNELHDR}:${INSTALL_DIR}/include
    export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:${GLIBCHDR}:${KERNELHDR}:${INSTALL_DIR}/include
    if [ ! -d ${KERNELHDR}/asm ];then
        ln -s ${KERNELHDR}/asm-generic ${KERNELHDR}/asm
    fi
fi

tar -xjvf ${GMP_SRC}.tar.bz2
cd ${GMP_SRC}/
./configure --prefix=${INSTALL_DIR}
make
if [ ! ${?} -eq 0 ]; then
    echo "Building failed for error in ${GMP_SRC}!"
    exit -1
fi
make install
cd ..

tar -xjvf ${MPFR_SRC}.tar.bz2
cd ${MPFR_SRC}/
./configure --prefix=${INSTALL_DIR} --with-gmp-include=${INSTALL_DIR}/include --with-gmp-lib=${INSTALL_DIR}/lib
make
if [ ! ${?} -eq 0 ]; then
    echo "Building failed for error in ${MPFR_SRC}!"
    exit -1
fi
make install
cd ..

tar -zxvf ${MPC_SRC}.tar.gz
cd ${MPC_SRC}/
./configure --prefix=${INSTALL_DIR} --with-gmp-include=${INSTALL_DIR}/include --with-gmp-lib=${INSTALL_DIR}/lib
make
if [ ! ${?} -eq 0 ]; then
    echo "Building failed for error in ${MPC_SRC}!"
    exit -1
fi
make install
cd ..

tar -xjvf ${ISL_SRC}.tar.bz2
cd ${ISL_SRC}/
./configure --prefix=${INSTALL_DIR} --with-gmp-prefix=${INSTALL_DIR}
make
if [ ! ${?} -eq 0 ]; then
    echo "Building failed for error in ${ISL_SRC}!"
    exit -1
fi
make install
cd ..

tar -zxvf gcc-${1}.0.tar.gz
cd gcc-${1}.0/
if [ ${arch} == "X86_6489" ]; then
    INCLUDE_DIRS="-I${SOURCE_DIR}/gcc-${1}.0/libstdc++-v3/include -I${SOURCE_DIR}/gcc-${1}.0/libstdc++-v3/include/bits -I${SOURCE_DIR}/gcc-${1}.0/libstdc++-v3/include/std -I${SOURCE_DIR}/gcc-${1}.0/libstdc++-v3/libsupc++"
    ./configure --prefix=${INSTALL_DIR}  --with-gmp=${INSTALL_DIR} --with-mpfr=${INSTALL_DIR} --with-mpc=${INSTALL_DIR} --with-isl=${INSTALL_DIR} --enable-languages=c,c++,fortran --disable-multilib --disable-static --enable-shared --enable-checking=release --enable-bootstrap CFLAGS="${INCLUDE_DIRS}" CPPFLAGS="${INCLUDE_DIRS}" CXXFLAGS="${INCLUDE_DIRS}"
    #./configure --prefix=${INSTALL_DIR}  --with-gmp=${INSTALL_DIR} --with-mpfr=${INSTALL_DIR} --with-mpc=${INSTALL_DIR} --with-isl=${INSTALL_DIR} --enable-languages=c,c++,fortran --disable-multilib --disable-static --enable-shared --enable-checking=release --enable-bootstrap
else
    ./configure --prefix=${INSTALL_DIR}  --with-gmp=${INSTALL_DIR} --with-mpfr=${INSTALL_DIR} --with-mpc=${INSTALL_DIR} --with-isl=${INSTALL_DIR} --enable-languages=c,c++,fortran --disable-multilib --disable-static --enable-shared --enable-checking=release --enable-bootstrap
fi
make -j$(nproc)
if [ ! ${?} -eq 0 ]; then
    echo "Building failed for error in gcc-${1}.0!"
    exit -1
fi
make install
cd ..

cd ${SOURCE_DIR}/
tar -xjvf ${VALGRIND_SRC}.tar.bz2
cd ${VALGRIND_SRC}/
./configure --prefix=/usr
make -j$(nproc) && make install
cd ..

tar -zxvf ${NUMA_SRC}.tar.gz
cd ${NUMA_SRC}/
./configure --prefix=/usr
make -j$(nproc)
if [ ! ${?} -eq 0 ]; then
    echo "Building failed for error in ${VALGRIND_SRC}!"
    exit -1
fi
make install
cd ..
