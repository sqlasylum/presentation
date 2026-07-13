#!/bin/bash
# Script to add pg_stat_statements to postgresql.conf
# Usage: ./add_pg_stat_statements.sh [path_to_postgresql.conf]

CONFIG_PATH="$1"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to find postgresql.conf
find_postgresql_conf() {
    local common_paths=(
        "/etc/postgresql/*/main/postgresql.conf"
        "/var/lib/pgsql/data/postgresql.conf"
        "/usr/local/var/postgres/postgresql.conf"
        "/opt/postgresql/data/postgresql.conf"
    )
    
    for path_pattern in "${common_paths[@]}"; do
        for path in $path_pattern; do
            if [ -f "$path" ]; then
                echo "$path"
                return
            fi
        done
    done
}

# Get config file path
if [ -z "$CONFIG_PATH" ]; then
    echo -e "${YELLOW}No config path provided. Searching common locations...${NC}"
    CONFIG_PATH=$(find_postgresql_conf)
    if [ -z "$CONFIG_PATH" ]; then
        echo -e "${RED}ERROR: Could not find postgresql.conf${NC}"
        echo -e "${YELLOW}Please specify the path: ./add_pg_stat_statements.sh /path/to/postgresql.conf${NC}"
        exit 1
    fi
fi

# Verify file exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}ERROR: File not found: $CONFIG_PATH${NC}"
    exit 1
fi

echo -e "\n${CYAN}PostgreSQL Config: $CONFIG_PATH${NC}"

# Create backup
BACKUP_PATH="${CONFIG_PATH}.backup_$(date +%Y%m%d_%H%M%S)"
cp "$CONFIG_PATH" "$BACKUP_PATH"
echo -e "${GREEN}Backup created: $BACKUP_PATH${NC}"

# Check if pg_stat_statements is already configured
if grep -qE "^\s*shared_preload_libraries\s*=.*pg_stat_statements" "$CONFIG_PATH"; then
    echo -e "${GREEN}pg_stat_statements already in shared_preload_libraries${NC}"
    echo ""
    exit 0
fi

# Check if shared_preload_libraries exists (commented or not)
if grep -qE "^\s*#?\s*shared_preload_libraries\s*=" "$CONFIG_PATH"; then
    # Line exists, modify it
    sed -i.tmp -E "s/^(\s*#?\s*shared_preload_libraries\s*=\s*')([^']*)('.*)/shared_preload_libraries = '\2, pg_stat_statements'\3/" "$CONFIG_PATH"
    
    # Clean up empty values (in case it was empty before)
    sed -i.tmp "s/= ', pg_stat_statements'/= 'pg_stat_statements'/" "$CONFIG_PATH"
    sed -i.tmp "s/= ' , pg_stat_statements'/= 'pg_stat_statements'/" "$CONFIG_PATH"
    
    rm -f "${CONFIG_PATH}.tmp"
    echo -e "${YELLOW}Modified existing shared_preload_libraries setting${NC}"
else
    # Setting doesn't exist, add it
    echo "" >> "$CONFIG_PATH"
    echo "# Load pg_stat_statements extension" >> "$CONFIG_PATH"
    echo "shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)" >> "$CONFIG_PATH"
    echo "" >> "$CONFIG_PATH"
    echo -e "${YELLOW}Added shared_preload_libraries setting${NC}"
fi

echo -e "${GREEN}\nSUCCESS: postgresql.conf has been updated${NC}"
echo -e "${YELLOW}\nIMPORTANT: You must restart PostgreSQL for changes to take effect!${NC}"
echo -e "\n${CYAN}To restart PostgreSQL:${NC}"
echo -e "  ${NC}sudo systemctl restart postgresql${NC}"
echo -e "  ${NC}or: sudo pg_ctl restart -D <data-directory>${NC}"
echo ""
