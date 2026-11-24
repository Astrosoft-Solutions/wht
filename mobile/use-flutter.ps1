$env:Path = 'C:\flutter\bin;' + $env:Path
Write-Host 'Flutter ready:' (flutter --version | Select-Object -First 1)
