# Run this script to create the database (no SSMS needed).
# Double-click "Run-Database-Setup.ps1" or in PowerShell: .\Run-Database-Setup.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$schemaPath = Join-Path $scriptDir "Database\Schema.sql"

if (-not (Test-Path $schemaPath)) {
    Write-Host "ERROR: Schema file not found at $schemaPath" -ForegroundColor Red
    exit 1
}

# Find sqlcmd (common locations)
$sqlcmd = $null
$paths = @(
    "sqlcmd",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE",
    "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE",
    "C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE"
)
foreach ($p in $paths) {
    if ($p -eq "sqlcmd") {
        $exe = Get-Command sqlcmd -ErrorAction SilentlyContinue
        if ($exe) { $sqlcmd = $exe.Source; break }
    } else {
        if (Test-Path $p) { $sqlcmd = $p; break }
    }
}

if (-not $sqlcmd) {
    Write-Host "ERROR: sqlcmd not found. Install SQL Server Express or add sqlcmd to PATH." -ForegroundColor Red
    Write-Host "Download: https://www.microsoft.com/en-us/sql-server/sql-server-downloads" -ForegroundColor Yellow
    exit 1
}

# Try default server first, then SQLEXPRESS
$servers = @("localhost", "localhost\SQLEXPRESS")
$ok = $false
foreach ($server in $servers) {
    Write-Host "Trying server: $server ..." -ForegroundColor Cyan
    & $sqlcmd -S $server -E -i "`"$schemaPath`"" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database created successfully using server: $server" -ForegroundColor Green
        $ok = $true
        break
    }
}

if (-not $ok) {
    Write-Host "Could not connect to SQL Server. Make sure SQL Server is installed and running." -ForegroundColor Red
    Write-Host "If you use a named instance, edit this script and set the server name." -ForegroundColor Yellow
    exit 1
}
