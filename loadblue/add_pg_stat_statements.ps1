# PowerShell script to add pg_stat_statements to postgresql.conf
# Usage: .\add_pg_stat_statements.ps1 -ConfigPath "C:\Program Files\PostgreSQL\18\data\postgresql.conf"

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath
)

# Function to find postgresql.conf if not provided
function Find-PostgresqlConf {
    $commonPaths = @(
        "C:\Program Files\PostgreSQL\18\data\postgresql.conf",
        "C:\Program Files\PostgreSQL\17\data\postgresql.conf",
        "C:\Program Files\PostgreSQL\16\data\postgresql.conf",
        "C:\Program Files\PostgreSQL\15\data\postgresql.conf",
        "C:\PostgreSQL\data\postgresql.conf"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# Get config file path
if (-not $ConfigPath) {
    Write-Host "No config path provided. Searching common locations..." -ForegroundColor Yellow
    $ConfigPath = Find-PostgresqlConf
    if (-not $ConfigPath) {
        Write-Host "ERROR: Could not find postgresql.conf" -ForegroundColor Red
        Write-Host "Please specify the path using: .\add_pg_stat_statements.ps1 -ConfigPath 'path\to\postgresql.conf'" -ForegroundColor Yellow
        exit 1
    }
}

# Verify file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Host "ERROR: File not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "`nPostgreSQL Config: $ConfigPath" -ForegroundColor Cyan

# Create backup
$backupPath = "$ConfigPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $ConfigPath $backupPath
Write-Host "Backup created: $backupPath" -ForegroundColor Green

# Read the file
$content = Get-Content $ConfigPath
$newContent = @()
$found = $false
$modified = $false

foreach ($line in $content) {
    # Check if this is the shared_preload_libraries line (active or commented)
    if ($line -match "^\s*#?\s*shared_preload_libraries\s*=") {
        $found = $true
        
        # Extract current value
        if ($line -match "shared_preload_libraries\s*=\s*'([^']*)'") {
            $currentValue = $Matches[1].Trim()
            
            # Check if pg_stat_statements is already there
            if ($currentValue -match "pg_stat_statements") {
                Write-Host "pg_stat_statements already in shared_preload_libraries" -ForegroundColor Green
                $newContent += $line
            } else {
                # Add pg_stat_statements
                if ($currentValue -eq "") {
                    $newValue = "pg_stat_statements"
                } else {
                    $newValue = "$currentValue, pg_stat_statements"
                }
                $newLine = "shared_preload_libraries = '$newValue'		# (change requires restart)"
                $newContent += $newLine
                $modified = $true
                Write-Host "Modified: shared_preload_libraries = '$newValue'" -ForegroundColor Yellow
            }
        } elseif ($line -match "^\s*#") {
            # Line is commented out, uncomment and set value
            $newLine = "shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)"
            $newContent += $newLine
            $modified = $true
            Write-Host "Uncommented and set: shared_preload_libraries = 'pg_stat_statements'" -ForegroundColor Yellow
        } else {
            # Malformed line, replace it
            $newLine = "shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)"
            $newContent += $newLine
            $modified = $true
            Write-Host "Replaced malformed line with: shared_preload_libraries = 'pg_stat_statements'" -ForegroundColor Yellow
        }
    } else {
        $newContent += $line
    }
}

# If shared_preload_libraries wasn't found, add it
if (-not $found) {
    Write-Host "shared_preload_libraries not found, adding it..." -ForegroundColor Yellow
    
    # Find a good place to insert (after RESOURCE USAGE or CONNECTION sections)
    $insertIndex = -1
    for ($i = 0; $i -lt $newContent.Count; $i++) {
        if ($newContent[$i] -match "^#.*RESOURCE USAGE" -or $newContent[$i] -match "^#.*CONNECTIONS AND AUTHENTICATION") {
            $insertIndex = $i + 1
            break
        }
    }
    
    if ($insertIndex -gt 0) {
        $newContent = $newContent[0..($insertIndex-1)] + 
                      "" + 
                      "# Load pg_stat_statements extension" +
                      "shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)" +
                      "" +
                      $newContent[$insertIndex..($newContent.Count-1)]
    } else {
        # Just add at the beginning
        $newContent = @(
            "# Load pg_stat_statements extension",
            "shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)",
            ""
        ) + $newContent
    }
    $modified = $true
}

# Write changes if modified
if ($modified) {
    $newContent | Set-Content $ConfigPath -Encoding UTF8
    Write-Host "`nSUCCESS: postgresql.conf has been updated" -ForegroundColor Green
    Write-Host "`nIMPORTANT: You must restart PostgreSQL for changes to take effect!" -ForegroundColor Yellow
    Write-Host "`nTo restart PostgreSQL:" -ForegroundColor Cyan
    Write-Host "  1. Find your service name: Get-Service | Where-Object {`$_.Name -like '*postgres*'}" -ForegroundColor White
    Write-Host "  2. Restart: Restart-Service <service-name>" -ForegroundColor White
    Write-Host "  Or use: pg_ctl restart -D `"<data-directory>`"" -ForegroundColor White
} else {
    Write-Host "`nNo changes needed - pg_stat_statements is already configured" -ForegroundColor Green
}

Write-Host ""
