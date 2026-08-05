<#
.SYNOPSIS
Falcon AI Native Windows Launcher

.DESCRIPTION
Intelligent startup manager for the Falcon AI platform. 
Validates dependencies, automatically discovers project components,
starts the backend, performs health checks, and launches the Flutter Windows UI.
#>
param(
    [ValidateSet("Development", "Release")]
    [string]$Mode = "Development"
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogsDir = Join-Path $ScriptDir "logs"

# Ensure logs directory exists
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

$LogFile = Join-Path $LogsDir "launcher.log"
$BackendLogFile = Join-Path $LogsDir "backend.log"
$FlutterLogFile = Join-Path $LogsDir "flutter.log"
$StartupLogFile = Join-Path $LogsDir "startup.log"
$ConfigPath = Join-Path $ScriptDir ".falcon_launcher.json"

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Write to console
    if ($Level -eq "ERROR" -or $Level -eq "FAILURE") {
        Write-Host $LogMessage -ForegroundColor Red
    } elseif ($Level -eq "WARN" -or $Level -eq "RECOVERY") {
        Write-Host $LogMessage -ForegroundColor Yellow
    } elseif ($Level -eq "SUCCESS") {
        Write-Host $LogMessage -ForegroundColor Green
    } elseif ($Level -eq "STARTUP") {
        Write-Host $LogMessage -ForegroundColor Cyan
    } else {
        Write-Host $LogMessage -ForegroundColor Gray
    }
    
    # Write to log file
    Add-Content -Path $LogFile -Value $LogMessage
    
    if ($Level -eq "STARTUP" -or $Level -eq "ERROR" -or $Level -eq "FAILURE") {
        Add-Content -Path $StartupLogFile -Value $LogMessage
    }
}

function Show-Error {
    param([string]$Message, [string]$Recovery = "")
    Write-Log $Message "FAILURE"
    if ($Recovery) {
        Write-Log $Recovery "RECOVERY"
    }
    
    $FullMsg = "$Message"
    if ($Recovery) {
        $FullMsg += "`n`n$Recovery"
    }
    
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($FullMsg, "Falcon Launcher Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

try {
    Write-Log "Starting Falcon AI Launcher in $Mode mode..." "STARTUP"

    # ---------------------------------------------------------
    # 1. Discover Backend
    # ---------------------------------------------------------
    Write-Log "Searching for Backend project..." "INFO"
    $BackendProjects = Get-ChildItem -Path $ScriptDir -Filter "app.py" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq "api" }
    $BackendDir = $null

    if ($BackendProjects.Count -eq 0) {
        Show-Error -Message "Backend entry point (api\app.py) not found." -Recovery "Ensure the backend 'api' folder exists within the Falcon project."
    } else {
        $BackendDir = $BackendProjects[0].Directory.Parent.FullName
        Write-Log "Found Backend project at: $BackendDir" "SUCCESS"
    }

    # ---------------------------------------------------------
    # 2. Discover Flutter
    # ---------------------------------------------------------
    Write-Log "Searching for Flutter project..." "INFO"
    $FlutterDir = $null
    
    # Check saved config first
    if (Test-Path $ConfigPath) {
        $Config = Get-Content $ConfigPath | ConvertFrom-Json
        if ($Config.FlutterPath -and (Test-Path (Join-Path $Config.FlutterPath "pubspec.yaml"))) {
            $FlutterDir = $Config.FlutterPath
            Write-Log "Loaded Flutter path from config: $FlutterDir" "SUCCESS"
        }
    }

    if (-not $FlutterDir) {
        $FlutterProjects = Get-ChildItem -Path $ScriptDir -Filter "pubspec.yaml" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "\\\.pub-cache\\" }
        
        if ($FlutterProjects.Count -eq 0) {
            Show-Error -Message "Flutter project not found. No pubspec.yaml was detected in the project root or subdirectories." -Recovery "Please initialize the Flutter project inside the Falcon directory."
        } elseif ($FlutterProjects.Count -eq 1) {
            $FlutterDir = $FlutterProjects[0].Directory.FullName
            Write-Log "Found exactly one Flutter project at: $FlutterDir" "SUCCESS"
        } else {
            Write-Host "`nMultiple Flutter projects detected:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $FlutterProjects.Count; $i++) {
                Write-Host "  [$i] $($FlutterProjects[$i].Directory.FullName)" -ForegroundColor Cyan
            }
            Write-Host ""
            
            $Selection = Read-Host "Select the index of the Flutter project to use for Falcon"
            $idx = $Selection -as [int]
            
            if ($null -ne $idx -and $idx -ge 0 -and $idx -lt $FlutterProjects.Count) {
                $FlutterDir = $FlutterProjects[$idx].Directory.FullName
                @{"FlutterPath"=$FlutterDir} | ConvertTo-Json | Set-Content $ConfigPath
                Write-Log "Selected and saved Flutter path: $FlutterDir" "SUCCESS"
            } else {
                Show-Error -Message "Invalid selection." -Recovery "Run the launcher again and select a valid index."
            }
        }
    }

    # ---------------------------------------------------------
    # 3. Discover Python Environment
    # ---------------------------------------------------------
    Write-Log "Discovering Python environment..." "INFO"
    $PythonCmd = $null
    $EnvType = $null

    # Priority 1: Activated Environment
    if ($env:VIRTUAL_ENV) {
        $PythonCmd = Join-Path $env:VIRTUAL_ENV "Scripts\python.exe"
        $EnvType = "Activated Virtual Environment"
    } else {
        # Priority 2: Project Virtual Environment
        $VenvDirs = @(".venv", "venv", "env")
        foreach ($v in $VenvDirs) {
            $VenvPythonScriptDir = Join-Path $ScriptDir "$v\Scripts\python.exe"
            $VenvPythonBackendDir = Join-Path $BackendDir "$v\Scripts\python.exe"
            
            if (Test-Path $VenvPythonScriptDir) {
                $PythonCmd = $VenvPythonScriptDir
                $EnvType = "Project Virtual Environment"
                break
            } elseif (Test-Path $VenvPythonBackendDir) {
                $PythonCmd = $VenvPythonBackendDir
                $EnvType = "Project Virtual Environment"
                break
            }
        }
    }

    # Priority 3: System Python (Fallback)
    if (-not $PythonCmd) {
        $PythonCmd = "python"
        $EnvType = "System Python"
    }

    # Validate Python Interpreter
    try {
        $pythonVersion = & $PythonCmd --version 2>&1
        $pythonVersion = ("$pythonVersion").Trim()
    } catch {
        if ($PythonCmd -eq "python") {
            try {
                $PythonCmd = "py"
                $pythonVersion = & $PythonCmd --version 2>&1
                $pythonVersion = ("$pythonVersion").Trim()
            } catch {
                Show-Error -Message "Python environment missing or not in PATH." -Recovery "Install Python and add it to your PATH."
            }
        } else {
            Show-Error -Message "Python environment missing at: $PythonCmd" -Recovery "Recreate the virtual environment."
        }
    }

    # ---------------------------------------------------------
    # 4. Dependency Validation
    # ---------------------------------------------------------
    Write-Log "Verifying Python dependencies..." "INFO"
    $Deps = @("fastapi", "uvicorn", "pydantic", "requests")
    foreach ($dep in $Deps) {
        $depCheck = & $PythonCmd -c "import $dep" 2>&1
        if ($LASTEXITCODE -ne 0) {
            $InstallCmd = "& '$PythonCmd' -m pip install -r requirements.txt"
            if ($dep -eq "requests") {
                $InstallCmd = "& '$PythonCmd' -m pip install requests"
            }
            Show-Error -Message "Missing dependency:`n$dep" -Recovery "Install using:`n$InstallCmd"
        }
    }
    Write-Log "Dependencies verified successfully." "SUCCESS"

    # Verify Flutter SDK
    Write-Log "Verifying Flutter SDK..." "INFO"
    try {
        $flutterVersion = flutter --version 2>&1
        $flutterVersionStr = ($flutterVersion | Select-Object -First 1)
        Write-Log "Flutter found: $flutterVersionStr" "SUCCESS"
    } catch {
        Show-Error -Message "Flutter SDK not found or not in PATH." -Recovery "Install Flutter and add it to your PATH."
    }

    # ---------------------------------------------------------
    # 5. Config Check
    # ---------------------------------------------------------
    $EnvFile = Join-Path $BackendDir ".env"
    if (-not (Test-Path $EnvFile)) {
        $EnvExample = Join-Path $BackendDir ".env.example"
        if (Test-Path $EnvExample) {
            Copy-Item -Path $EnvExample -Destination $EnvFile
            Write-Log "Created .env from .env.example" "WARN"
        }
    }

    $ApiPort = 8000
    if (Test-Path $EnvFile) {
        $EnvContent = Get-Content $EnvFile
        $PortMatch = $EnvContent | Select-String -Pattern "^API_PORT\s*=\s*(\d+)"
        if ($PortMatch) {
            $ApiPort = $PortMatch.Matches.Groups[1].Value
        }
    }
    $HealthUrl = "http://127.0.0.1:$ApiPort/api/v1/health"

    # ---------------------------------------------------------
    # 6. Startup Diagnostics Print
    # ---------------------------------------------------------
    $DiagMsg = @"

--- Falcon Startup Diagnostics ---
Project Root:          $ScriptDir
Detected Backend Path: $BackendDir
Detected Flutter Path: $FlutterDir
Selected Python:       $PythonCmd
Python Version:        $pythonVersion
Environment Type:      $EnvType
Backend URL:           http://127.0.0.1:$ApiPort
Health Endpoint:       $HealthUrl
----------------------------------
"@
    Write-Log $DiagMsg "STARTUP"
    
    # ---------------------------------------------------------
    # 7. Start Backend (with auto-recovery)
    # ---------------------------------------------------------
    $MaxBackendRestarts = 3
    $BackendRestartCount = 0
    $BackendProcess = $null
    
    function Start-BackendProcess {
        Write-Log "Starting FastAPI backend..." "INFO"
        if ($Mode -eq "Development") {
            $BackendStartArgs = "-Command `"Set-Location -Path '$BackendDir'; & '$PythonCmd' -m api.app 2>&1 | Tee-Object -FilePath '$BackendLogFile'`""
            $BackendProcess = Start-Process powershell.exe -ArgumentList $BackendStartArgs -PassThru
        } else {
            $BackendStartArgs = "-WindowStyle Hidden -Command `"Set-Location -Path '$BackendDir'; & '$PythonCmd' -m api.app 2>&1 > '$BackendLogFile'`""
            $BackendProcess = Start-Process powershell.exe -ArgumentList $BackendStartArgs -PassThru -WindowStyle Hidden
        }
        Write-Log "Backend process started (PID: $($BackendProcess.Id))." "SUCCESS"
        return $BackendProcess
    }

    $BackendProcess = Start-BackendProcess

    # ---------------------------------------------------------
    # 8. Wait for Health Check
    # ---------------------------------------------------------
    function Wait-BackendHealth {
        Write-Log "Waiting for backend health ($HealthUrl)..." "INFO"
        $MaxRetries = 90 # 180 seconds
        $RetryCount = 0
        
        while ($RetryCount -lt $MaxRetries) {
            $attempt = $RetryCount + 1
            Write-Log "Health Check Attempt ${attempt}..." "INFO"
            try {
                $response = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
                $json = $response.Content | ConvertFrom-Json
                
                if ($json.success -eq $true) {
                    Write-Log "Health Check Successful. Backend Ready." "SUCCESS"
                    return $true
                } else {
                    Write-Log "Health Check returned 200 but success=false: $($response.Content)" "WARN"
                }
            } catch {
                if ($_.Exception.Response) {
                    $statusCode = $_.Exception.Response.StatusCode.value__
                    try {
                        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                        $responseBody = $reader.ReadToEnd()
                        Write-Log "Health Check Error: HTTP $statusCode - $responseBody" "WARN"
                    } catch {
                        Write-Log "Health Check Error: HTTP $statusCode" "WARN"
                    }
                } else {
                    Write-Log "Health Check Failed: $($_.Exception.Message)" "WARN"
                }
            }
            
            if ($BackendProcess.HasExited) {
                Write-Log "Backend process crashed during health check." "FAILURE"
                return $false
            }
            
            Start-Sleep -Seconds 2
            $RetryCount++
        }
        return $false
    }
    
    $BackendReady = Wait-BackendHealth
    
    while (-not $BackendReady -and $BackendRestartCount -lt $MaxBackendRestarts) {
        $BackendRestartCount++
        Write-Log "Backend failed to start. Initiating recovery attempt $BackendRestartCount of $MaxBackendRestarts..." "WARN"
        Start-Sleep -Seconds 3
        
        $BackendProcess = Start-BackendProcess
        $BackendReady = Wait-BackendHealth
    }
    
    if (-not $BackendReady) {
        if (-not $BackendProcess.HasExited) {
            Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue
        }
        
        $lastLogs = ""
        if (Test-Path $BackendLogFile) {
            $lastLogs = (Get-Content $BackendLogFile -Tail 10) -join "`n"
        }
        Show-Error -Message "Health check timeout or backend crash.`n`nLast Backend Logs:`n$lastLogs" -Recovery "Check if port $ApiPort is already in use or review logs."
    }

    # ---------------------------------------------------------
    # 9. Launch Flutter App
    # ---------------------------------------------------------
    Write-Log "Launching Flutter Windows application..." "INFO"
    $FlutterProcess = $null
    if ($Mode -eq "Development") {
        $FlutterStartArgs = "-Command `"Set-Location -Path '$FlutterDir'; flutter run -d windows 2>&1 | Tee-Object -FilePath '$FlutterLogFile'`""
        $FlutterProcess = Start-Process powershell.exe -ArgumentList $FlutterStartArgs -PassThru
        Write-Log "Flutter application launched (PID: $($FlutterProcess.Id))." "SUCCESS"
    } else {
        $ExePath = Join-Path $FlutterDir "build\windows\x64\runner\Release\falcon.exe"
        if (Test-Path $ExePath) {
            $FlutterProcess = Start-Process $ExePath -PassThru
            Write-Log "Flutter release application launched (PID: $($FlutterProcess.Id))." "SUCCESS"
        } else {
            Show-Error -Message "Release executable not found." -Recovery "Build the flutter project first."
        }
    }

    # ---------------------------------------------------------
    # 10. Process Supervisor
    # ---------------------------------------------------------
    Write-Log "Entering process supervisor mode..." "INFO"
    
    while (-not $FlutterProcess.HasExited) {
        if ($BackendProcess.HasExited) {
            Write-Log "Backend process unexpectedly exited!" "FAILURE"
            
            $BackendRestartCount = 0
            $BackendReady = $false
            while (-not $BackendReady -and $BackendRestartCount -lt $MaxBackendRestarts) {
                $BackendRestartCount++
                Write-Log "Initiating auto-recovery attempt $BackendRestartCount of $MaxBackendRestarts..." "WARN"
                Start-Sleep -Seconds 3
                
                $BackendProcess = Start-BackendProcess
                $BackendReady = Wait-BackendHealth
            }
            
            if (-not $BackendReady) {
                $lastLogs = ""
                if (Test-Path $BackendLogFile) {
                    $lastLogs = (Get-Content $BackendLogFile -Tail 10) -join "`n"
                }
                Show-Error -Message "Backend API crashed and could not be recovered.`n`nLast Backend Logs:`n$lastLogs" -Recovery "Check backend logs for details:`n$BackendLogFile"
            }
        }
        
        Start-Sleep -Seconds 2
    }
    
    # If Flutter exits
    if ($FlutterProcess.HasExited) {
        Write-Log "Flutter application closed." "INFO"
        
        # In PowerShell Start-Process, ExitCode is not easily accessible if it was launched via powershell.exe 
        # unless we wait. But since we use powershell.exe to keep the window open for logs, we just assume 
        # if the user closes it manually it's fine, but if it crashed we check logs.
        # To be robust, if it exited in Development, we check the tail of the log for errors.
        if ($Mode -eq "Development" -and (Test-Path $FlutterLogFile)) {
            $lastLogs = (Get-Content $FlutterLogFile -Tail 10) -join "`n"
            if ($lastLogs -match "Exception" -or $lastLogs -match "Error") {
                Show-Error -Message "Flutter application crashed.`n`nLast Flutter Logs:`n$lastLogs" -Recovery "Check flutter logs for details:`n$FlutterLogFile"
            }
        }
    }
    
    # ---------------------------------------------------------
    # 11. Cleanup
    # ---------------------------------------------------------
    if (-not $BackendProcess.HasExited) {
        Write-Log "Stopping backend process..." "INFO"
        Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Falcon Launcher exiting cleanly." "SUCCESS"
    Start-Sleep -Seconds 2

} catch {
    $ErrMsg = $_.Exception.Message
    Show-Error -Message "Unhandled error during launcher execution:`n$ErrMsg" -Recovery "Check $StartupLogFile for tracebacks."
}
