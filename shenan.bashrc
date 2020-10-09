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

function load_mpi() {
    MPI_NAME=${1}
    if [ "${MPI_NAME}" = "" ]; then
        echo "Usage: load_mpi name"
    fi
    if [ ! -d ${HOME}/mpi/${MPI_NAME} ]; then
        echo "MPI(${HOME}/mpi/${MPI_NAME}) is not installed!"
    fi
    export MPI_PATH=${HOME}/mpi/${MPI_NAME}
    export LD_LIBRARY_PATH=${MPI_PATH}/lib:${LD_LIBRARY_PATH}
    export PATH=${MPI_PATH}/bin:${PATH}
}

