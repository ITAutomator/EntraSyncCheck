# EntraSyncCheck.ps1  

<img src=https://raw.githubusercontent.com/ITAutomator/Assets/main/EntraSyncCheck/EntraSyncCheck.png alt="screenshot" width="400"/>  

For hybrid 365 environments, run this on the *Entra Connect* server as Administrator.  

## Overview

Run on your Entra sync server to check when next ADSync will happen and prompts user to start a manual delta sync.
    - Shows:  
        * Last sync time based on Event ID 6100 in Application log  
        * Next scheduled sync time (Get-EntraSyncScheduler)  
    - Prompts to start a sync now (Delta or Full)  
    - If sync is started, it polls Get-EntraSyncConnectorRunStatus and shows status  

## Usage
Copy these files to `C:\EntraSyncCheck` (or other appropriate folder)  
Right-click `EntraSyncCheck (as Admin).cmd` and run as admin.  

Press `D` to do a delta sync.  
Press `F` for a full sync - but limit this to occasional use only.  

# Powershell Command (Sample)
  
The script uses these commands 

```powershell
# Next scheduled sync time
Get-EntraSyncScheduler
 
# Checks if something is running
Get-EntraSyncConnectorRunStatus

# Runs a delta
Start-ADSyncSyncCycle -PolicyType Delta

# Runs a full
Start-ADSyncSyncCycle -PolicyType Initial
```
# Misc Information

Note:
Hybrid mode in M365 can be achieved using *Entra Connect Sync* or *Entra Connect Cloud*.   
*Entra Connect Sync* uses an on-prem server to talk to AD controllers and sync to the cloud.  This is the traditional method covered by this program.  
*Entra Connect Cloud* is installed directly on AD servers to sync to cloud.  This is the newer method (not covered by this program).  
  
Microsoft admin page to check health: [Microsoft Entra Connect Health](https://aka.ms/aadconnecthealth)  
Microsoft Entra Connect Sync Topics (for Hybrid) [Microsoft Entra Connect Sync Topics](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sync-whatis)  
Microsoft monitoring tools: [Microsoft Entra Connect Service Manager](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sync-service-manager-ui-connectors)





