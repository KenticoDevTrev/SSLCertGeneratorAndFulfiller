Get-ChildItem -Path "C:\certs\Responses" |
Rename-Item -NewName { $_.Name -replace "_","." }