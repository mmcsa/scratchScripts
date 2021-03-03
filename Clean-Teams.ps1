#clean Teams Cache function
Function Clean-Teams {
    #stop Teams
    Write-Host "stopping Teams"
    $teamsProcesses = get-process | ?{$_.ProcessName -contains 'Teams'}
    foreach ($teamsProcess in $teamsProcesses)
        {
            $teamsProcess | Stop-Process -Force
        }
    #clean directories
    $appDataPath = $env:APPDATA
    $userName = $env:USERNAME
    $CacheLocationAll = @("$appDataPath\Microsoft\teams\application cache\cache","$appDataPath\Microsoft\teams\blob_storage","$appDataPath\Microsoft\teams\Cache","$appDataPath\Microsoft\teams\databases","$appDataPath\Microsoft\teams\GPUcache","$appDataPath\Microsoft\teams\Local Storage","$appDataPath\Microsoft\teams\tmp")
    foreach ($CacheLocation in $CacheLocationAll)
        {
            Get-ChildItem -Path $CacheLocation -Recurse | Remove-Item -Force
            write-host "cleaned $cacheLocation"
        }
    #update & restart Teams
    Write-Host "restarting Teams"
    $teamsPath = "C:\Users\$userName\AppData\Local\Microsoft\Teams"
    Set-Location -Path $teamsPath
    $cmdBlock = {.\update.exe --processStart `"Teams.exe`"}
    Invoke-Command -ScriptBlock $cmdBlock 
    Write-Host "Done!"
}