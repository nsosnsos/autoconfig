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
export HOME=/home/$(whoami)
export BASE_PATH=${PATH}
export BASE_LD_LIBRARY_PATH=/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH}
export GCC_PATH=${BASE_PATH}
export GCC_LD_LIBRARY_PATH=${BASE_LD_LIBRARY_PATH}

function load_gcc() {
    GCC_NAME=${1}
    if [ "${GCC_NAME}" = "" ]; then
        echo "Usage: load_gcc name"
        return -1
    fi
    if [ ! -d ${HOME}/gcc/${GCC_NAME} ]; then
        echo "GCC(${HOME}/gcc/${GCC_NAME}) is not installed!"
        return -1
    fi
    export GCC_PREFIX=${HOME}/gcc/${GCC_NAME}
    export GCC_PATH=${GCC_PREFIX}/bin:${BASE_PATH}
    export GCC_LD_LIBRARY_PATH=${GCC_PREFIX}/lib:${GCC_PREFIX}/lib64:${BASE_LD_LIBRARY_PATH}
    export PATH=${GCC_PATH}
    export LD_LIBRARY_PATH=${GCC_LD_LIBRARY_PATH}
}

function load_mpi() {
    MPI_NAME=${1}
    if [ "${MPI_NAME}" = "" ]; then
        echo "Usage: load_mpi name"
        return -1
    fi
    if [ ! -d ${HOME}/mpi/${MPI_NAME} ]; then
        echo "MPI(${HOME}/mpi/${MPI_NAME}) is not installed!"
        return -1
    fi
    export OPAL_PREFIX=${HOME}/mpi/${MPI_NAME}
    export LD_LIBRARY_PATH=${OPAL_PREFIX}/lib:${GCC_LD_LIBRARY_PATH}
    export PATH=${OPAL_PREFIX}/bin:${GCC_PATH}
}

