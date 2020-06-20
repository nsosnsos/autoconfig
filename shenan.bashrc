# shenan.bashrc

# Source global definitions
#if [ -f /etc/bashrc ]; then
#        . /etc/bashrc
#fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="$COLOR_RED[\u@\h \t] \w$ $COLOR_NULL"

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ls='ls --color=auto'
alias ll='ls --color=auto -laF'

export TZ='Asia/HongKong'
export HOME=/home/shenan
export GCC_PATH=${HOME}/gcc/9.3
export MPI_PATH=${HOME}/mpi/ompi
export LD_LIBRARY_PATH=${GCC_PATH}/lib:${GCC_PATH}/lib64:${MPI_PATH}/lib
export PATH=${GCC_PATH}/bin:${MPI_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/ibutils/bin

function load_mpi() {
    MPI_NAME=${1}
    if [ "${MPI_NAME}" = "" ]; then
        echo "Usage: load_hmpi name"
    fi
    if [ ! -d ${HOME}/mpi/${MPI_NAME} ]; then
        echo "hmpi(${HOME}/mpi/${MPI_NAME}) is not installed!"
    fi
    export MPI_PATH=${HOME}/mpi/${MPI_NAME}
    export LD_LIBRARY_PATH=${GCC_PATH}/lib:${GCC_PATH}/lib64:${MPI_PATH}/lib
    export PATH=${GCC_PATH}/bin:${MPI_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/ibutils/bin
}
