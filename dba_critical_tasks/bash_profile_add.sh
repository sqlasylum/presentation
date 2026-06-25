# -----------------------------------------------------------------------
# DBA Critical Task Aliases
# -----------------------------------------------------------------------
DBA_SCRIPT="$HOME/code/presentation/run_dba_task.sh"
export DBA_FLAGS="-h localhost -d bluebox -p 5432 -U postgres"
DBA_LOG_SCRIPT="$HOME/code/presentation/dba_critical_tasks/tail_pg_log.sh"
export DB_DOCKER_CONTAINER="bluebox-17"

alias acc="$DBA_SCRIPT $DBA_FLAGS -f check_activity"
alias appcount="$DBA_SCRIPT $DBA_FLAGS -f check_application_count"
alias conn="$DBA_SCRIPT $DBA_FLAGS -f Check_connections"
alias locks="$DBA_SCRIPT $DBA_FLAGS -f check_locks"
alias repl="$DBA_SCRIPT $DBA_FLAGS -f Check_replication_slots"
alias stats="$DBA_SCRIPT $DBA_FLAGS -f check_stats"
alias vacuum="$DBA_SCRIPT $DBA_FLAGS -f check_vacuum_tables_needed"
alias waits="$DBA_SCRIPT $DBA_FLAGS -f check_wait_events"
alias topfilms="$DBA_SCRIPT $DBA_FLAGS -f Analyze_Query_toprentedmovies"
alias dblogs="$DBA_LOG_SCRIPT $DBA_FLAGS"
alias tail_docker_log="$DBA_LOG_SCRIPT --docker"
