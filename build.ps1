# PIMS v2 Build Script

Write-Host "=== Building PIMS v2 ===" -ForegroundColor Cyan

# Build C# Extension
Write-Host "`nBuilding C# Extension DLL..." -ForegroundColor Yellow
Push-Location "PIMS-Ext"
try {
    dotnet publish -r win-x64 -c Release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Extension DLL built successfully!" -ForegroundColor Green
        $dllPath = "PIMS-Ext\bin\Release\net8.0\win-x64\publish\PIMS-Ext_x64.dll"
        if (Test-Path $dllPath) {
            Write-Host "DLL location: $dllPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Extension build FAILED!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
} finally {
    Pop-Location
}

# Note about PBO building
Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Copy PIMS-Ext_x64.dll to your Arma 3 directory" -ForegroundColor White
Write-Host "2. Build PIMS2 folder into PBO using your preferred tool:" -ForegroundColor White
Write-Host "   - Mikero's Tools: makePBO" -ForegroundColor Gray
Write-Host "   - HEMTT: hemtt build" -ForegroundColor Gray
Write-Host "   - PBO Manager, etc." -ForegroundColor Gray
Write-Host "3. Place PIMS2.pbo in your Arma 3 mod folder" -ForegroundColor White
Write-Host "4. Configure database settings in PIMS Init module" -ForegroundColor White

Write-Host "`n=== Build Complete! ===" -ForegroundColor Green

$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');