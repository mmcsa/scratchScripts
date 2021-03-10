<#
Author:		Mat Morgan - Microsoft Azure CXP FastTrack
GitHub:     @mmcsa
Date:		3/10/2021
Updated:    
Script:  	InstallMMAWithServiceMap.ps1
Version: 	1.0
Credits:    This script reuses code written by Daniel Orneling (GitHub @DanielOrneling)
Disclaimer: This script has been developed solely for demonstration purposes and is not intended for production deployment
#>

# Set the Workspace ID and Primary Key for the Log Analytics workspace.
param(
    [parameter(Mandatory=$true, HelpMessage="The ID of the Log Analytics workspace you want to connect the agent to.")]
    [ValidateNotNullOrEmpty()]
    [string]$WorkSpaceID,

    [parameter(Mandatory=$true, HelpMessage="The primary key of the Log Analytics workspace you want to connect the agent to.")]
    [ValidateNotNullOrEmpty()]
    [string]$WorkSpaceKey
)

# Setting variables
$setupFilePath = "C:\Temp"


# Setting variables specific for MMA
$MMAFileName = "MMASetup-AMD64.exe"
$ArgumentListMMA = '/C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 '+  "OPINSIGHTS_WORKSPACE_ID=$WorkspaceID " + "OPINSIGHTS_WORKSPACE_KEY=$WorkSpaceKey " +'AcceptEndUserLicenseAgreement=1"'
$URI_MMA = "https://aka.ms/MonitoringAgentWindows"

# Setting variables specific for DependencyAgent
$DependencyFileName = "InstallDependencyAgent-Windows.exe"
$argumentListDependency = '/C:"InstallDependencyAgent-Windows.exe /S /RebootMode=manual /AcceptEndUserLicenseAgreement:1"'
$URI_Dependency = "https://aka.ms/DependencyAgentWindows"

# Checking if temporary path exists otherwise create it
if(!(Test-Path $setupFilePath))
{
    Write-Output "Creating folder $setupFilePath since it does not exist ... "
    New-Item -path $setupFilePath -ItemType Directory
    Write-Output "Folder $setupFilePath created successfully."
}
# Start logging the actions
$timestamp = Get-Date -Format o | ForEach-Object { $_ -replace ":", "." }
$LogPath = "C:\Temp\MMA-DependencyInstallLog-" + $timestamp + ".txt"
Start-Transcript -Path $LogPath -NoClobber

#check to see if MMA Service is already running
#if running update workspace id & restart service
$MMAService = (Get-Service | Where-Object {$_.Name -eq "HealthService"})
if ($MMAService.Status -eq "Running")
    {
        Write-Host "MMA is running, updating workspaces"
        $AgentConfig = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
        $AgentConfig.AddCloudWorkspace($WorkspaceID, $WorkspaceKey)
        $AgentConfigOld = $AgentConfig.GetCloudWorkspaces()
        $WorkspaceCount = $AgentConfigOld.Length; $i = 0
            do
                {
                    Write-Host ("MMA workspace " + $i + ": " + ($AgentConfigOld.Item($i).workspaceId))
                    $i++
                }
            while ($i -lt $WorkspaceCount) 
        Write-Host "Restarting MMA Service"
        Restart-Service HealthService
    }
else 
    {
        # install MMA Agent if service isn't running
        # Check if folder exists, if not, create it
        Write-Host "MMA is not running, installing agent"

        # Change the location to the specified folder
        Set-Location $setupFilePath
        # Check if Microsoft Monitoring Agent file exists, if not, download it
        if (Test-Path $MMAFileName)
            {
                Write-Host "The file $MMAFileName already exists."
            }
        else
            {
                Write-Host "The file $MMAFileName does not exist, downloading..." -NoNewline
                Invoke-WebRequest -Uri $URI_MMA -OutFile $MMAFile | Out-Null
                Write-Host "done!" -ForegroundColor Green
            }
        # Install the Microsoft Monitoring Agent
        try 
            {
                Write-Host "Installing Microsoft Monitoring Agent.." -nonewline
                $MMAResult = Start-Process $MMAFileName -ArgumentList $ArgumentListMMA -ErrorAction Stop -Wait
                Write-Host "done!" -ForegroundColor Green        
            }
        catch   
            {
                Write-host "Error installing MMA Agent. Error response: " + $MMAResult
            }       
    }
# Check if Service Map Agent exists, if not, download it
 if (Test-Path $DependencyFileName)
    {
        Write-Host "The file $DependencyFileName already exists."
    }
 else
    {
        Write-Host "The file $DependencyFileName does not exist, downloading..." -NoNewline
        Invoke-WebRequest -Uri $URI_Dependency -OutFile $SMFile | Out-Null
        Write-Host "done!" -ForegroundColor Green
    } 
# Install the Service Map Agent
try 
    {
        Write-Host "Installing Service Map Agent.." -nonewline
        $DependencyResult = Start-Process $DependencyFileName -ArgumentList $argumentListDependency -ErrorAction Stop -Wait
        Write-Host "done!" -ForegroundColor Green
    }
catch 
    {
        Write-host "Error installing Dependency Agent. Error response: " + $DependencyResult
    }

Stop-Transcript