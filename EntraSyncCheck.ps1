<#
    Simple Entra Connect / ADSync watcher
    - Shows:
        * Last sync time (based on Event ID 6100 in Application log)
        * Next scheduled sync time (Get-ADSyncScheduler) in LOCAL time
    - Prompts to start a sync now (Delta or Full)
    - If sync is started, it polls Get-ADSyncConnectorRunStatus and shows status
#>

function Get-LastSyncTime {
    try {
        $lastEvent = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 6100 } -MaxEvents 1 -ErrorAction Stop
        return $lastEvent.TimeCreated
    } catch {
        return $null
    }
}

function Get-NextSyncLocalTime {
    try {
        $sched = Get-ADSyncScheduler
        $utc = $sched.NextSyncCycleStartTimeInUTC
        if (-not $utc) { return $null }

        # Convert to DateTime and then to local time
        $dt = [datetime]$utc
        if ($dt.Kind -ne [System.DateTimeKind]::Utc) {
            $dt = [System.DateTime]::SpecifyKind($dt, [System.DateTimeKind]::Utc)
        }
        return $dt.ToLocalTime()
    } catch {
        return $null
    }
}

function Show-SyncTimes {
    $statuses = Get-ADSyncConnectorRunStatus
    if ($statuses) {
        Write-Host "Current Status      : $($statuses.ConnectorName -join ", ")"
    }
    else {
        Write-Host "Current Status      : [Idle]"
    }

    $lastSync = Get-LastSyncTime
    $nextSync = Get-NextSyncLocalTime
    if ($lastSync) {
        Write-Host ("Last sync completed : {0}" -f $lastSync)
    } else {
        Write-Host "Last sync completed : (not found / no events yet)"
    }

    if ($nextSync) {
        Write-Host ("Next scheduled sync : {0}" -f $nextSync)
    } else {
        Write-Host "Next scheduled sync : (unknown)"
    }
    Write-Host "SyncCycleEnabled    : $((Get-ADSyncScheduler).SyncCycleEnabled) [$((Get-ADSyncScheduler).NextSyncCyclePolicyType)]"
    Write-Host "====================================================="
}

function MonitorRunningSync {
    Write-Host ""
    $checking_Status = ""
    $checking_Statuslast = ""
    $minSecs = 5
    Write-Host "Monitoring sync status [for up to $($minSecs)s of settled status]" -ForegroundColor Cyan
    Write-Host "Get-ADSyncConnectorRunStatus" -ForegroundColor Blue
    $startTime = Get-Date # reset start timer
    $keeplooping = $true
    do {
        $statuses = Get-ADSyncConnectorRunStatus
        if ($statuses) {
            $checking_Status = "Syncing"
            Write-Host "Syncing: $($statuses.ConnectorName -join ", ")"
            $startTime = Get-Date # reset start timer if there is any status
        }
        else {
            $checking_Status = "Idle"
        }
        Start-Sleep -Seconds 1
        if ($checking_Status -ne $checking_Statuslast)
        { # status change
            Write-Host "Status changed from [$($checking_Statuslast)] to [$($checking_Status)]" -ForegroundColor Yellow
            $checking_Statuslast = $checking_Status
            $startTime = Get-Date # reset start timer if there is a change
        } # status change
        # check if keep looping
        $elapsed = (Get-Date) - $startTime
        $elapsedsecs = [int]$elapsed.TotalSeconds
        $keeplooping = ($elapsedsecs -lt $minSecs) # too long
        if (-not $keeplooping) {
            Write-Host "Done checking" -ForegroundColor Green
        }
    } while ($keeplooping)
}
# =======================
# Main loop
# =======================
Write-Host "====================================================="
Write-Host "          Entra Connect Check and Sync Tool"
Write-Host "====================================================="
# Ensure ADSync module is available
try {
    Import-Module ADSync -ErrorAction Stop
} catch {
    Write-Host "ERROR: ADSync module not found. Run this on the Entra Connect server." -ForegroundColor Yellow
    Start-Sleep 3
    exit
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Not running as Administrator" -ForegroundColor Yellow
    Start-Sleep 3
    exit
}

while ($true) {
    Show-SyncTimes
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  [D]  Start Delta sync"
    Write-Host "  [F]  Start Full sync"
    Write-Host "  [R]  Refresh"
    Write-Host "  [X]  Exit"
    Write-Host ""
    $choice = Read-Host "Choose an option (Enter to refresh)"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        Write-Host "Refreshing..." -ForegroundColor Yellow
        continue
    }

    switch -Regex ($choice.Trim()) {
        '^[dD]$' {
            Write-Host "Starting DELTA sync..." -ForegroundColor Yellow
            Write-Host "Start-ADSyncSyncCycle -PolicyType Delta" -ForegroundColor Blue
            try {
                Start-ADSyncSyncCycle -PolicyType Delta | Out-Null
                MonitorRunningSync
            } catch {
                Write-Host "Error starting Delta sync: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep 3
            }
        }
        '^[fF]$' {
            Write-Host "Starting FULL sync..." -ForegroundColor Yellow
            Write-Host "Start-ADSyncSyncCycle -PolicyType Initial" -ForegroundColor Blue
            try {
                Start-ADSyncSyncCycle -PolicyType Initial | Out-Null
                MonitorRunningSync
            } catch {
                Write-Host "Error starting Full sync: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep 3
            }
        }
        '^[xX]$' {
            Write-Host "Exiting..." -ForegroundColor Yellow
            Start-Sleep 1
            Exit
        }
        '^[rR]$' {
            Write-Host "Refreshing..." -ForegroundColor Yellow
            Start-Sleep 1
        }
        Default {
            Write-Host "Unrecognized choice." -ForegroundColor Red
            Start-Sleep 2
        }
    }
}
