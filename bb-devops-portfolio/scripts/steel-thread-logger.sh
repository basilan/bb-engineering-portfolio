#!/bin/bash
# Steel-Thread Execution Logger
# Generates timestamped execution trace matching architecture sequence diagrams

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/steel-thread-${TIMESTAMP}.log"
JSON_LOG="$LOG_DIR/steel-thread-${TIMESTAMP}.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create logs directory
mkdir -p "$LOG_DIR"

# Initialize JSON log structure
init_json_log() {
    cat > "$JSON_LOG" << EOF
{
  "execution": {
    "start_time": "$(date -Iseconds)",
    "session_id": "steel-thread-${TIMESTAMP}",
    "project": "bb-devops-portfolio",
    "version": "1.0.0",
    "phases": []
  }
}
EOF
}

# Logging functions with JSON support
log_phase_start() {
    local phase="$1"
    local description="$2"
    local timestamp=$(date -Iseconds)
    
    echo -e "${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC} - 🎯 PHASE START: ${BLUE}$phase${NC}" | tee -a "$LOG_FILE"
    echo -e "   ${description}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Add to JSON log
    local json_entry=$(cat << EOF
{
  "phase": "$phase",
  "description": "$description",
  "start_time": "$timestamp",
  "status": "in_progress",
  "steps": [],
  "metrics": {}
}
EOF
    )
    
    # Update JSON (simplified - in production would use jq)
    echo "  Phase: $phase started at $timestamp" >> "${JSON_LOG}.phases"
}

log_phase_end() {
    local phase="$1"
    local status="$2"  # success, warning, error
    local timestamp=$(date -Iseconds)
    
    case "$status" in
        "success")
            echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S')${NC} - ✅ PHASE COMPLETE: ${BLUE}$phase${NC}" | tee -a "$LOG_FILE"
            ;;
        "warning")
            echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC} - ⚠️  PHASE WARNING: ${BLUE}$phase${NC}" | tee -a "$LOG_FILE"
            ;;
        "error")
            echo -e "${RED}$(date '+%Y-%m-%d %H:%M:%S')${NC} - ❌ PHASE FAILED: ${BLUE}$phase${NC}" | tee -a "$LOG_FILE"
            ;;
    esac
    echo "" | tee -a "$LOG_FILE"
    
    echo "  Phase: $phase ended at $timestamp with status: $status" >> "${JSON_LOG}.phases"
}

log_step() {
    local component="$1"
    local action="$2"
    local details="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "   ${BLUE}→${NC} $component: $action" | tee -a "$LOG_FILE"
    if [ -n "$details" ]; then
        echo -e "     $details" | tee -a "$LOG_FILE"
    fi
    
    echo "    $timestamp - $component: $action" >> "${JSON_LOG}.steps"
}

log_result() {
    local component="$1"
    local status="$2"  # VALID, FAILED, SUCCESS, etc.
    local metric="$3"   # optional metric
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$status" in
        *"SUCCESS"*|*"VALID"*|*"COMPLETE"*|*"AUTHENTICATED"*)
            echo -e "   ${BLUE}→${NC} $component: ${GREEN}✅ $status${NC}" | tee -a "$LOG_FILE"
            ;;
        *"WARNING"*)
            echo -e "   ${BLUE}→${NC} $component: ${YELLOW}⚠️  $status${NC}" | tee -a "$LOG_FILE"
            ;;
        *"FAILED"*|*"ERROR"*)
            echo -e "   ${BLUE}→${NC} $component: ${RED}❌ $status${NC}" | tee -a "$LOG_FILE"
            ;;
        *)
            echo -e "   ${BLUE}→${NC} $component: $status" | tee -a "$LOG_FILE"
            ;;
    esac
    
    if [ -n "$metric" ]; then
        echo -e "     Metric: $metric" | tee -a "$LOG_FILE"
    fi
    
    echo "    $timestamp - $component: $status ($metric)" >> "${JSON_LOG}.metrics"
}

# Architecture sequence diagram logging
log_sequence() {
    local actor="$1"
    local target="$2"
    local action="$3"
    local response="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "   ${CYAN}📋${NC} SEQUENCE: ${BLUE}$actor${NC} → ${BLUE}$target${NC} : $action" | tee -a "$LOG_FILE"
    if [ -n "$response" ]; then
        echo -e "   ${CYAN}📋${NC} RESPONSE: ${BLUE}$target${NC} → ${BLUE}$actor${NC} : $response" | tee -a "$LOG_FILE"
    fi
    
    echo "    $timestamp - SEQ: $actor->$target: $action" >> "${JSON_LOG}.sequence"
}

# Cost tracking
log_cost() {
    local resource="$1"
    local cost="$2"
    local currency="${3:-USD}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "   ${YELLOW}💰${NC} COST: $resource = $cost $currency" | tee -a "$LOG_FILE"
    echo "    $timestamp - COST: $resource = $cost $currency" >> "${JSON_LOG}.costs"
}

# Performance metrics
log_duration() {
    local operation="$1"
    local start_time="$2"
    local end_time="$3"
    local duration=$((end_time - start_time))
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "   ${BLUE}⏱️${NC}  DURATION: $operation = ${duration}s" | tee -a "$LOG_FILE"
    echo "    $timestamp - DURATION: $operation = ${duration}s" >> "${JSON_LOG}.durations"
}

# Resource tracking
log_resource() {
    local resource_type="$1"
    local resource_id="$2"
    local action="$3"  # created, configured, destroyed
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$action" in
        "created")
            echo -e "   ${GREEN}🏗️${NC}  RESOURCE: $resource_type ($resource_id) → CREATED" | tee -a "$LOG_FILE"
            ;;
        "configured")
            echo -e "   ${BLUE}⚙️${NC}  RESOURCE: $resource_type ($resource_id) → CONFIGURED" | tee -a "$LOG_FILE"
            ;;
        "destroyed")
            echo -e "   ${RED}🗑️${NC}  RESOURCE: $resource_type ($resource_id) → DESTROYED" | tee -a "$LOG_FILE"
            ;;
    esac
    
    echo "    $timestamp - RESOURCE: $resource_type $resource_id $action" >> "${JSON_LOG}.resources"
}

# Initialize the logging session
initialize_logging() {
    echo -e "${CYAN}🚀 BB DevOps Portfolio - Steel-Thread Execution Log${NC}" | tee "$LOG_FILE"
    echo -e "${CYAN}===============================================${NC}" | tee -a "$LOG_FILE"
    echo -e "Session ID: steel-thread-${TIMESTAMP}" | tee -a "$LOG_FILE"
    echo -e "Start Time: $(date)" | tee -a "$LOG_FILE"
    echo -e "Log Files: " | tee -a "$LOG_FILE"
    echo -e "  - Detailed: $LOG_FILE" | tee -a "$LOG_FILE"
    echo -e "  - Structured: $JSON_LOG" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    init_json_log
}

# Finalize the logging session
finalize_logging() {
    local status="$1"
    local end_time=$(date -Iseconds)
    
    echo "" | tee -a "$LOG_FILE"
    echo -e "${CYAN}===============================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}🏁 Steel-Thread Execution Complete${NC}" | tee -a "$LOG_FILE"
    echo -e "End Time: $(date)" | tee -a "$LOG_FILE"
    echo -e "Status: $status" | tee -a "$LOG_FILE"
    echo -e "Session ID: steel-thread-${TIMESTAMP}" | tee -a "$LOG_FILE"
    
    # Update JSON with end time
    sed -i.bak "s/\"phases\": \[\]/\"end_time\": \"$end_time\", \"status\": \"$status\", \"phases\": []/" "$JSON_LOG"
    
    echo -e "${GREEN}📄 Execution logs saved:${NC}"
    echo -e "  - ${BLUE}$LOG_FILE${NC}"
    echo -e "  - ${BLUE}$JSON_LOG${NC}"
    
    # Create summary report
    create_summary_report
}

# Create execution summary report
create_summary_report() {
    local summary_file="$LOG_DIR/steel-thread-${TIMESTAMP}-summary.md"
    
    cat > "$summary_file" << EOF
# Steel-Thread Execution Summary

**Session ID:** steel-thread-${TIMESTAMP}  
**Date:** $(date)  
**Project:** BB DevOps Portfolio  

## Execution Overview

- **Start Time:** $(head -5 "$LOG_FILE" | grep "Start Time" | cut -d': ' -f2-)
- **End Time:** $(tail -10 "$LOG_FILE" | grep "End Time" | cut -d': ' -f2-)
- **Log Files:** 
  - Detailed: \`$LOG_FILE\`
  - Structured: \`$JSON_LOG\`
  - Summary: \`$summary_file\`

## Architecture Components Validated

$(grep "✅" "$LOG_FILE" | sed 's/^/- /')

## Resource Tracking

$(if [ -f "${JSON_LOG}.resources" ]; then cat "${JSON_LOG}.resources" | sed 's/^/- /'; else echo "- No resources tracked"; fi)

## Performance Metrics

$(if [ -f "${JSON_LOG}.durations" ]; then cat "${JSON_LOG}.durations" | sed 's/^/- /'; else echo "- No duration metrics captured"; fi)

## Cost Summary

$(if [ -f "${JSON_LOG}.costs" ]; then cat "${JSON_LOG}.costs" | sed 's/^/- /'; else echo "- No cost data captured"; fi)

---

*Generated by BB DevOps Portfolio Steel-Thread Logger*
EOF

    echo -e "  - ${BLUE}$summary_file${NC}"
}

# Export functions for use in Makefile
export -f log_phase_start log_phase_end log_step log_result log_sequence log_cost log_duration log_resource initialize_logging finalize_logging

# If script is run directly, initialize logging
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    initialize_logging
fi