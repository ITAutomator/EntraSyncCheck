# EntraSyncCheck.ps1  

<img src=EntraSyncCheck.png alt="screenshot" width="400"/>  

Run this on the *Entra Connect* server as Administrator.  

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

    



