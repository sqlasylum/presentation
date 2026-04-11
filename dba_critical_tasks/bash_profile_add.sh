# -----------------------------------------------------------------------
# DBA Critical Task Aliases
# -----------------------------------------------------------------------
DBA_SCRIPT="$HOME/code/presentation/run_dba_task.sh"
DBA_FLAGS="-h localhost -d bluebox -p 5432 -U postgres"

alias acc="$DBA_SCRIPT $DBA_FLAGS -f check_activity"
alias appcount="$DBA_SCRIPT $DBA_FLAGS -f check_application_count"
alias conn="$DBA_SCRIPT $DBA_FLAGS -f Check_connections"
alias locks="$DBA_SCRIPT $DBA_FLAGS -f check_locks"
alias repl="$DBA_SCRIPT $DBA_FLAGS -f Check_replication_slots"
alias stats="$DBA_SCRIPT $DBA_FLAGS -f check_stats"
alias vacuum="$DBA_SCRIPT $DBA_FLAGS -f check_vacuum_tables_needed"
alias waits="$DBA_SCRIPT $DBA_FLAGS -f check_wait_events"
alias topfilms="$DBA_SCRIPT $DBA_FLAGS -f Analyze_Query_toprentedmovies"
