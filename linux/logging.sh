#!/usr/bin/env bash
# Logging library for autoconfig scripts
# Usage: source /path/to/logger.sh

# Log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3
LOG_LEVEL_FATAL=4

# Default log level
LOG_LEVEL=${LOG_LEVEL_INFO}

# Log file location
LOG_FILE="/var/log/autoconfig.log"
LOG_TO_FILE=true
LOG_TO_CONSOLE=true

# Colors for console output
COLOR_RESET='\033[0m'
COLOR_DEBUG='\033[0;36m'
COLOR_INFO='\033[0;32m'
COLOR_WARN='\033[0;33m'
COLOR_ERROR='\033[0;31m'
COLOR_FATAL='\033[0;35m'

# Initialize logging
function log_init() {
    local log_dir=$(dirname "$LOG_FILE")
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir" 2>/dev/null || LOG_TO_FILE=false
    fi

    # Create log file if it doesn't exist
    if [ "$LOG_TO_FILE" = true ] && [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || LOG_TO_FILE=false
    fi

    # Check if we can write to log file
    if [ "$LOG_TO_FILE" = true ] && [ ! -w "$LOG_FILE" ]; then
        LOG_TO_FILE=false
    fi
}

# Set log level
function log_set_level() {
    local level=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    case "$level" in
        debug) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        info)  LOG_LEVEL=$LOG_LEVEL_INFO ;;
        warn)  LOG_LEVEL=$LOG_LEVEL_WARN ;;
        error) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        fatal) LOG_LEVEL=$LOG_LEVEL_FATAL ;;
        *)     LOG_LEVEL=$LOG_LEVEL_INFO ;;
    esac
}

# Enable/disable file logging
function log_set_file_logging() {
    LOG_TO_FILE=$1
}

# Enable/disable console logging
function log_set_console_logging() {
    LOG_TO_CONSOLE=$1
}

# Set log file path
function log_set_file() {
    LOG_FILE=$1
    log_init
}

# Internal logging function
function _log() {
    local level=$1
    local level_name=$2
    local color=$3
    shift 3
    local message="$*"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local script_name=$(basename "$0")
    local log_entry="[${timestamp}] [${level_name}] [${script_name}] ${message}"

    # Console output
    if [ "$LOG_TO_CONSOLE" = true ] && [ $level -ge $LOG_LEVEL ]; then
        echo -e "${color}${log_entry}${COLOR_RESET}"
    fi

    # File output
    if [ "$LOG_TO_FILE" = true ] && [ $level -ge $LOG_LEVEL ]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

# Public logging functions
function log_debug() {
    _log $LOG_LEVEL_DEBUG "DEBUG" "$COLOR_DEBUG" "$@"
}

function log_info() {
    _log $LOG_LEVEL_INFO "INFO" "$COLOR_INFO" "$@"
}

function log_warn() {
    _log $LOG_LEVEL_WARN "WARN" "$COLOR_WARN" "$@"
}

function log_error() {
    _log $LOG_LEVEL_ERROR "ERROR" "$COLOR_ERROR" "$@"
}

function log_fatal() {
    _log $LOG_LEVEL_FATAL "FATAL" "$COLOR_FATAL" "$@"
    exit 1
}

# Log command execution
function log_exec() {
    local cmd="$@"
    log_debug "Executing: $cmd"
    eval "$cmd"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Command failed with exit code $exit_code: $cmd"
        return $exit_code
    fi
    return 0
}

# Initialize logging on source
log_init