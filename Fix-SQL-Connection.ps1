# SQL Server connection fix - try different server names
# Run: Right-click -> Run with PowerShell   OR   powershell -ExecutionPolicy Bypass -File "d:\SmartAcademicProjectHub\Fix-SQL-Connection.ps1"

$schemaPath = "d:\SmartAcademicProjectHub\Database\Schema.sql"
if (-not (Test-Path $schemaPath)) {
    Write-Host "Schema file not found." -ForegroundColor Red
    exit 1
}

# Try these server names (most common)
$servers = @(
    "localhost\SQLEXPRESS",   # SQL Server Express default
    ".\SQLEXPRESS",
    "localhost",
    "(localdb)\MSSQLLocalDB"  # LocalDB (lightweight)
)

$sqlcmd = $null
foreach ($p in @("sqlcmd", "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE", "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE")) {
    if ($p -eq "sqlcmd") {
        $exe = Get-Command sqlcmd -ErrorAction SilentlyContinue
        if ($exe) { $sqlcmd = $exe.Source; break }
    } elseif (Test-Path $p) { $sqlcmd = $p; break }
}

if (-not $sqlcmd) {
    Write-Host "sqlcmd not found. Install SQL Server Express first." -ForegroundColor Red
    Write-Host "Download: https://www.microsoft.com/en-us/sql-server/sql-server-downloads" -ForegroundColor Yellow
    Write-Host "Choose 'Express' -> Basic install." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nTrying to connect to SQL Server...`n" -ForegroundColor Cyan
$connected = $false
$workingServer = $null

foreach ($server in $servers) {
    Write-Host "  Trying: $server ... " -NoNewline
    $result = & $sqlcmd -S $server -E -Q "SELECT 1" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK" -ForegroundColor Green
        $workingServer = $server
        $connected = $true
        break
    } else {
        Write-Host "Failed" -ForegroundColor Red
    }
}

if (-not $connected) {
    Write-Host "`nCould not connect to any SQL Server. Try this:`n" -ForegroundColor Yellow
    Write-Host "1. Install SQL Server Express (if not installed):" -ForegroundColor White
    Write-Host "   https://www.microsoft.com/en-us/sql-server/sql-server-downloads" -ForegroundColor Gray
    Write-Host "   -> Download Express -> Run installer -> Choose 'Basic'`n" -ForegroundColor Gray
    Write-Host "2. Start SQL Server service:" -ForegroundColor White
    Write-Host "   - Press Win+R, type: services.msc, Enter" -ForegroundColor Gray
    Write-Host "   - Find 'SQL Server (SQLEXPRESS)' or 'SQL Server (MSSQLSERVER)'" -ForegroundColor Gray
    Write-Host "   - Right-click -> Start`n" -ForegroundColor Gray
    Write-Host "3. Then run this script again.`n" -ForegroundColor White
    exit 1
}

Write-Host "`nRunning database script on: $workingServer`n" -ForegroundColor Cyan
& $sqlcmd -S $workingServer -E -i "`"$schemaPath`""
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDatabase created successfully." -ForegroundColor Green
    Write-Host "`nIf your API uses default server (localhost), update appsettings.json:" -ForegroundColor Yellow
    if ($workingServer -like "*SQLEXPRESS*") {
        Write-Host "   Set: Server=localhost\\SQLEXPRESS; in Api\appsettings.json" -ForegroundColor Gray
    }
} else {
    Write-Host "`nScript had errors. Check message above." -ForegroundColor Red
    exit 1
}
