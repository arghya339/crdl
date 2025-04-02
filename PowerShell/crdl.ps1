# Chromium is an open-source browser project, developed and maintained by Google
# Easy Script to download and run latest Chromium Windows build
# Use: ~ Invoke-WebRequest -Uri "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/PowerShell/crdl.ps1" -OutFile "$env:USERPROFILE\.crdl.ps1" && Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:USERPROFILE\.crdl.ps1"
# Developer github.com/arghya339

# --- Downloading latest crdl.ps1 file from GitHub ---
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/PowerShell/crdl.ps1" -OutFile "$env:USERPROFILE\.crdl.ps1" | Out-Null

# Define ANSI color codes for Windows.PowerShell
$Red = @{ForegroundColor = "Red"}
$Green = @{ForegroundColor = "Green"}
$Yellow = @{ForegroundColor = "Yellow"}
$Cyan = @{ForegroundColor = "Cyan"}
$LightCyan = @{ForegroundColor = "Cyan"}
$Magenta = @{ForegroundColor = "Magenta"}
$Blue = @{ForegroundColor = "Blue"}
$White = @{ForegroundColor = "White"}

function print_crdlDesktop {
    Write-Host "     https://github.com/arghya339/crdl" @Blue

    Write-Host "     " -NoNewline
    Write-Host "         " -NoNewline @LightCyan
    Write-Host "           " -NoNewline @Blue
    Write-Host "    " -NoNewline
    Write-Host "_/  " -NoNewline @White
    Write-Host "         _/  _/" @Cyan

    Write-Host "     " -NoNewline
    Write-Host "    _/_/_/" -NoNewline @LightCyan
    Write-Host "  _/  _/_/" -NoNewline @Blue
    Write-Host "     _/ " -NoNewline @White
    Write-Host "    _/_/_/  _/" @Cyan

    Write-Host "     " -NoNewline
    Write-Host " _/      " -NoNewline @LightCyan
    Write-Host "  _/_/     " -NoNewline @Blue
    Write-Host "      _/" -NoNewline @White
    Write-Host " _/    _/  _/" @Cyan

    Write-Host "     " -NoNewline
    Write-Host "_/       " -NoNewline @LightCyan
    Write-Host " _/        " -NoNewline @Blue
    Write-Host "   _/   " -NoNewline @White
    Write-Host "_/    _/  _/" @Cyan

    Write-Host "     " -NoNewline
    Write-Host " _/_/_/  " -NoNewline @LightCyan
    Write-Host "_/         " -NoNewline @Blue
    Write-Host "_/      " -NoNewline @White
    Write-Host " _/_/_/  _/" @Cyan

    Write-Host "     " -NoNewline
    Write-Host "         " -NoNewline @LightCyan
    Write-Host "           " -NoNewline @Blue
    Write-Host "        " -NoNewline @White
    Write-Host "               " @Cyan

    Write-Host " " -NoNewline
    Write-Host "Developer: @arghya339" -NoNewline @White
    Write-Host "    _/_/_/_/_/" -NoNewline @White
    Write-Host "               " @Cyan
    Write-Host ""

    Write-Host ""
    Write-Host ""
}

function print_crdlCore {
    # Define ANSI color codes for Microsoft.PowerShell
    $Blue = "`e[34m"
    $skyBlue = "`e[36m"
    $Cyan = "`e[36m"
    $White = "`e[37m"
    $Reset = "`e[0m"

    # Construct the prompt
    $crldArt = @"
${Blue}     https://github.com/arghya339/crdl${Reset}
${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}    _/  ${Reset}${Cyan}         _/  _/${Reset}
${skyBlue}    _/_/_/${Reset}${Blue}  _/  _/_/${Reset}  ${White}     _/ ${Reset}${Cyan}    _/_/_/  _/ ${Reset}
${skyBlue} _/      ${Reset}${Blue}  _/_/     ${Reset}  ${White}      _/${Reset}${Cyan} _/    _/  _/  ${Reset}
${skyBlue}_/       ${Reset}${Blue} _/        ${Reset}  ${White}   _/   ${Reset}${Cyan}_/    _/  _/   ${Reset}
${skyBlue} _/_/_/  ${Reset}${Blue}_/         ${Reset}  ${White}_/      ${Reset}${Cyan} _/_/_/  _/    ${Reset}
${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}        ${Reset}${Cyan}               ${Reset}
${White}𝒟𝑒𝓋𝑒𝓁𝑜𝓅𝑒𝓇: @𝒶𝓇𝑔𝒽𝓎𝒶𝟥𝟥𝟫 ${Reset}${Blue} ${Reset}${White}_/_/_/_/_/${Reset}${Cyan}               ${Reset}
"@

    # Return the prompt with standard PowerShell suffix
    Write-Host $crldArt -NoNewline
    Write-Host ""
    Write-Host ""
}

# --- Check Current Shell ---
if ($PSVersionTable.PSEdition -eq "Desktop") {
    Write-Host "You are running Windows PowerShell (Version $($PSVersionTable.PSVersion))"
    Write-Host "[!]" @Cyan "Please set PowerShell as Default Profile for Windows Termianl"
    Write-Host "[i]" @Blue "right-click on Windows Terminal 'title bar (tab row)' > Startup > Default profile > PowerShell > Save"
} elseif ($PSVersionTable.PSEdition -eq "Core") {
    Write-Host "$(pwsh -v)" @Green
}

# --- Checking Internet Connection using google.com IPv4-IP Address (8.8.8.8) ---
if (!(Test-Connection 8.8.8.8 -Count 1 -Quiet)) {
  Write-Host "[x]" @Red "Oops! No Internet Connection available.`nConnect to the Internet and try again later."
  exit 1
}

# --- Global Variables ---
$majorVersion = (Get-ComputerInfo).WindowsVersion -split '\.' | Select-Object -First 1
$cloudflareDOH = "-L --doh-url https://cloudflare-dns.com/dns-query"
$outdatedPKG = & winget upgrade --list 2>$null
$LAST_INSTALL = "$env:USERPROFILE/.LAST_INSTALL"
$installedVersion = Get-Content -Path "$LAST_INSTALL" -ErrorAction SilentlyContinue
$branchUrl = "https://commondatastorage.googleapis.com/chromium-browser-snapshots"

# Detect platform (Intel or ARM) - Windows equivalent with x86 detection
if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { # AMD64 generally indicates x86-64 on Windows
    $snapshotPlatform = "Win_x64"  # For Intel (x86_64) - Assuming "Win_x64" is desired for Intel
} elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
    $snapshotPlatform = "Win" # For Intel x86 (32-bit)
} else {
    $snapshotPlatform = "Win_Arm64"  # For ARM64 - Assuming "Win_Arm64" is desired for ARM64
}
$LAST_CHANGE = (Invoke-WebRequest -Uri "$branchUrl/$snapshotPlatform/LAST_CHANGE" -UseBasicParsing).Content

# --- Check Windows OS version for Chromium Support ---
$windowsMajorVersion = [System.Environment]::OSVersion.Version.Major  # Get Windows Major Version
if ($windowsMajorVersion -lt 10) {
    Write-Host "[!]" @Cyan "Windows $($windowsMajorVersion).$([System.Environment]::OSVersion.Version.Minor) is not supported by the latest Chromium." -ForegroundColor Red
    Write-Host "[i]" @Blue "Chromium and modern Chromium-based browsers require Windows 10 or later." -ForegroundColor Red
    exit 1
}

Write-Host "Please wait! starting crdl..." @Yellow

# --- Check if winget is installed ---
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "winget is not found. `nYou can install winget from the Microsoft Store or via GitHub"
    Start-Process "https://apps.microsoft.com/detail/9nblggh4nns1"  # Microsoft Store - Microsoft App Installer
    Start-Process "https://github.com/microsoft/winget-cli/releases/latest"  # GitHub - Windows Package Manager
    exit 1
}

# --- Check PowerShell package ---
try {
    pwsh -v *> $null
    winget upgrade Microsoft.PowerShell --accept-source-agreements --silent *> $null
} catch {
    winget install --id Microsoft.PowerShell --source winget *> $null
}

# --- install Chromium function ---
function crInstall {
    # --- Check if Chromium executable exists at the target path ---
    $chromeEXE = "C:\Chromium\chrome.exe"
    $chrome_winDir = "$env:USERPROFILE\chrome-win"

    if (Test-Path -Path $chromeEXE) {
        Write-Host "[~]" @White "Chromium executable found. Replacing.."

        # Stop running Chromium processes
        Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

        # Remove existing Chromium directory
        Remove-Item -Path "C:\Chromium\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Copy new files (contents of chrome-win)
        Copy-Item -Path "$chrome_winDir\*" -Destination "C:\Chromium" -Recurse -Force -ErrorAction Stop

        Write-Host "[+]" $Green "Chromium Files updated successfully!"
    } else {
        # Create target directory if needed
        if (-not (Test-Path -Path "C:\Chromium")) {
            New-Item -ItemType Directory -Path "C:\Chromium" -Force | Out-Null
        }

        # Copy all contents from source
        Copy-Item -Path "$chrome_winDir\*" -Destination "C:\Chromium" -Recurse -Force -ErrorAction Stop
        
        Write-Host "[+]" @Green "Chromium installed successfully!"

        # Download and run extension script
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/pwsh/top-50.sh" -OutFile "$env:USERPROFILE\top-50.ps1" -UseBasicParsing
        & "$env:USERPROFILE\top-50.ps1"
        Remove-Item -Path "$env:USERPROFILE\top-50.ps1" -Force -ErrorAction SilentlyContinue  # Removing
    }

    # Create shortcut
    $shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Chromium.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $chromeEXE
    $shortcut.WorkingDirectory = "C:\Chromium"
    $shortcut.IconLocation = "$chromeEXE,0"
    $shortcut.Save()

    Remove-Item -Path "$env:USERPROFILE\chrome-win" -Recurse -Force -ErrorAction SilentlyContinue  # Cleanup

    Write-Host "[i]" @Blue "Operation completed successfully. Use Start Menu to launch Chromium." -ForegroundColor Green
    exit 0
}

# --- Direct Download Function ---
function directDl {
    param(
        [string]$branchPosition,
        [string]$crVersion
    )

    $downloadUrl = "https://commondatastorage.googleapis.com/chromium-browser-snapshots/$snapshotPlatform/$branchPosition/chrome-win.zip"

    # Prefer the direct download link if available
    if ($downloadUrl -and $downloadUrl -ne "null") {
        Write-Host "[+]" @Green "Found valid snapshot at: $branchPosition"

        if ($installedVersion -eq $branchPosition) {
            Write-Host "[!]" @Yellow "Already installed: $installedVersion"
            Start-Sleep -Seconds 3
            Clear-Host
            exit 0
        } else {
            Write-Host "[~]" @Cyan "Direct Downloading Chromium $crVersion from $downloadUrl"
            $zipPath = Join-Path -Path $env:USERPROFILE -ChildPath "${snapshotPlatform}_${branchPosition}_chrome-win.zip"

            # Download the file
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

            Write-Host "[~]" @Cyan "Extracting ${snapshotPlatform}_${branchPosition}_chrome-win.zip"
            $extractPath = Join-Path -Path $env:USERPROFILE -ChildPath "chrome-win"
            Expand-Archive -Path $zipPath -DestinationPath $env:USERPROFILE -Force
            Remove-Item -Path $zipPath

            # Prompt for installation
            $choice = Read-Host -Prompt "Do you want to install Chromium_v${crVersion}.exe? [Y/n]"

            switch -Regex ($choice) {
                "^[yY]$|^$" {
                    # Assuming crInstall is a defined function
                    crInstall
                    New-Item -Path $LAST_INSTALL -ItemType File -Force | Out-Null
                    Set-Content -Path $LAST_INSTALL -Value $branchPosition
                    Clear-Host
                    exit 0
                }
                "^[nN]$" {
                    Write-Host "[!]" @Yellow "Chromium installation skipped!"
                    Remove-Item -Path $extractPath -Recurse -Force *> $null
                    Start-Sleep -Seconds 1
                }
                default {
                    Write-Host "[i]" @Blue "Invalid choice! Installation skipped."
                    Remove-Item -Path $extractPath -Recurse -Force *> $null
                    Start-Sleep -Seconds 2
                }
            }
        }
    } else {
        Write-Host "[x]" @Red "No direct download URL found!"
        Start-Sleep -Seconds 1
    }
}

function Find-ValidSnapshot {
    param(
        [int]$position,
        [int]$maxPosition,
        [string]$branchPosition,
        [string]$crVersion,
        [string]$LAST_CHANGE
    )

    $range = 500

    Write-Host "[~]" @White "Searching downward from $position (max attempts: $range)"

    # Search downward starting from branchPosition
    for ($pos = $position; $pos -ge ($position - $range); $pos--) {
        if ($pos -lt 0) {
            break
        }

        $checkUrl = "$branchUrl/$snapshotPlatform/$pos/chrome-win.zip"
        try {
            $response = Invoke-WebRequest -Uri $checkUrl -Method Head -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "[+]" @Green "Found valid snapshot at: $pos"

                if ($installedVersion -eq $pos) {
                    Write-Host "[!]" @Yellow "Already installed: $installedVersion"
                    Start-Sleep -Seconds 3
                    Clear-Host
                    exit 0
                } else {
                    Write-Host "[~]" @White "Downloading Chromium $crVersion from: $checkUrl"
                    Invoke-WebRequest -Uri $checkUrl -OutFile "$env:USERPROFILE\chrome-win.zip"

                    Write-Host "[~]" @White "Extracting chrome-win.zip"
                    Expand-Archive -Path "$env:USERPROFILE\chrome-win.zip" -DestinationPath "$env:USERPROFILE\" -Force
                    Remove-Item -Path "$env:USERPROFILE\chrome-win.zip" -Force

                    $answer = Read-Host "Do you want to install Chromium_v${crVersion}.exe? [Y/n]"
                    switch -Regex ($answer) {
                        "^y|^Y|^$" {
                            # Call crInstall function for installation
                            crInstall # Call the installation function
                            New-Item -Path $LAST_INSTALL -ItemType File -Force | Out-Null
                            Set-Content -Path $LAST_INSTALL -Value $pos
                            Start-Sleep -Seconds 3
                            Clear-Host
                            exit 0
                        }
                        "^n|^N" {
                            Write-Host "[!]" @Yellow "Chromium installation skipped!"
                            Remove-Item -Path "$env:USERPROFILE\chrome-win" -Recurse -Force -ErrorAction SilentlyContinue *> $null
                        }
                        default {
                            Write-Host "[i]" @Blue "Invalid choice! Installation skipped."
                            Remove-Item -Path "$env:USERPROFILE\chrome-win" -Recurse -Force -ErrorAction SilentlyContinue *> $null
                        }
                    }
                    break
                    Start-Sleep -Seconds 3
                }
            }
        }
        catch {
            Write-Host "[!]" @Yellow "No valid snapshot found at position: $pos"
        }
    }
}

# --- Fetch the last Chromium Extended version info ---
function eInfo {
    $branchData = Invoke-WebRequest -Uri "https://chromiumdash.appspot.com/fetch_releases?channel=Extended&platform=Windows&num=2" | ConvertFrom-Json
    $script:crVersion = $branchData[0].version # update to global crVersion
    $script:branchPosition = $branchData[0].chromium_main_branch_position # update to global branchPosition
    Write-Host "[i]" @Blue "Last Chromium Extended Version: $script:crVersion at branch position: $script:branchPosition"
}

# --- Fetch the last Chromium Stable version info ---
function sInfo {
    $branchData = Invoke-WebRequest -Uri "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Windows&num=2" | ConvertFrom-Json
    $script:crVersion = $branchData[1].version # update to global crVersion
    $script:branchPosition = $branchData[1].chromium_main_branch_position # update to global branchPosition
    Write-Host "[i]" @Blue "Last Chromium Stable Releases Version: $script:crVersion at branch position: $script:branchPosition"
}

# --- Fetch the last Chromium Beta version info ---
function bInfo {
    $branchData = Invoke-WebRequest -Uri "https://chromiumdash.appspot.com/fetch_releases?channel=Beta&platform=Windows&num=1" | ConvertFrom-Json
    $script:crVersion = $branchData[0].version # update to global crVersion
    $script:branchPosition = $branchData[0].chromium_main_branch_position # update to global branchPosition
    Write-Host "[i]" @Blue "Last Chromium Beta Version: $script:crVersion at branch position: $script:branchPosition"
}

# --- Fetch the last Chromium Dev version info ---
function dInfo {
    $branchData = Invoke-WebRequest -Uri "https://chromiumdash.appspot.com/fetch_releases?channel=Dev&platform=Windows&num=1" | ConvertFrom-Json
    $script:crVersion = $branchData[0].version # update to global crVersion
    $script:branchPosition = $branchData[0].chromium_main_branch_position # update to global branchPosition
    Write-Host "[i]" @Blue "Last Chromium Dev Version: $script:crVersion at branch position: $script:branchPosition"
}

# --- Fetch the last Chromium Canary version ---
function cInfo {
    $branchData = Invoke-WebRequest -Uri "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Windows&num=1" | ConvertFrom-Json
    $script:crVersion = $branchData[0].version # update to global crVersion
    $script:branchPosition = $branchData[0].chromium_main_branch_position # update to global branchPosition
    Write-Host "[i]" @Blue "Last Chromium Canary Version: $script:crVersion at branch position: $script:branchPosition"
}

# --- Fetch the last Chromium Canary Test version info ---
function tInfo {
    $branchData = Invoke-WebRequest -Uri "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Windows&num=1" | ConvertFrom-Json
    $script:crVersion = $branchData[0].version -replace '^(\d{2})(\d)', '${1}X' -replace '(\d)(\d{3})\.\d+', '${1}XXX.X' # update to global crVersion
    $script:branchPosition = (Invoke-WebRequest -Uri "$branchUrl/$snapshotPlatform/LAST_CHANGE").Content # update to global branchPosition
    Write-Host "[i]" @Blue "Last Chromium Canary Test Version: $script:crVersion at branch position: $script:branchPosition"
}

# --- Main Menu ---
while ($true) {
    # Call ASCII art function
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        Clear-Host
        print_crdlDesktop
    } else {
        Write-Host "`e[2J`e[3J`e[H"  # Clear screen using ANSI escape codes (Ms.PS)
        print_crdlCore
    }

    Write-Host @"
E. Extended
S. Stable
B. Beta
D. Dev
C. Canary
T. Canary Test
Q. Quit

"@

    $channel = Read-Host "Select Chromium Channel"

    switch -Regex ($channel) {
        '^[Ee]' {
            $script:channel = "Extended"
            eInfo  # call the eInfo function
            Find-ValidSnapshot -position $script:branchPosition -crVersion $script:crVersion -maxPosition $script:LAST_CHANGE # call Find-ValidSnapshot function
        }
        '^[Ss]' {
            $script:channel = "Stable"
            sInfo
            Find-ValidSnapshot -position $script:branchPosition -crVersion $script:crVersion -maxPosition $script:LAST_CHANGE
        }
        '^[Bb]' {
            $script:channel = "Beta"
            bInfo
            Find-ValidSnapshot -position $script:branchPosition -crVersion $script:crVersion -maxPosition $script:LAST_CHANGE
        }
        '^[Dd]' {
            $script:channel = "Dev"
            dInfo
            Find-ValidSnapshot -position $script:branchPosition -crVersion $script:crVersion -maxPosition $script:LAST_CHANGE
        }
        '^[Cc]' {
            $script:channel = "Canary"
            cInfo
            Find-ValidSnapshot -position $script:branchPosition -crVersion $script:crVersion -maxPosition $script:LAST_CHANGE
        }
        '^[Tt]' {
            tInfo
            directDl -branchPosition $script:branchPosition -crVersion $script:crVersion  # Call directDl with parameters
        }
        '^[Qq]' {
            Clear-Host
            exit  # exit from the while loop
        }
        default {
            Write-Host "[i]" @Blue "Invalid option! Please select a valid channel."
            Start-Sleep -Seconds 3
        }
    }
}
###################################################################################