#!/usr/bin/bash

# Chromium is an open-source browser project, developed and maintained by Google
# Easy Script to download and run latest Chromium Android build
# Use: ~ curl -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/crdl.sh" && bash "$HOME/.crdl.sh"
# Developer github.com/arghya339

# --- Downloading latest crdl.sh file from GitHub ---
curl -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/crdl.sh" > /dev/null 2>&1

if [ ! -f "$PREFIX/bin/crdl" ]; then
  ln -s $HOME/.crdl.sh $PREFIX/bin/crdl  # symlink (shortcut of crdl.sh)
fi
chmod +x $HOME/.crdl.sh  # give execute permission to crdl

# --- Colored log indicators ---
good="\033[92;1m[✔]\033[0m"
bad="\033[91;1m[✘]\033[0m"
info="\033[94;1m[i]\033[0m"
running="\033[37;1m[~]\033[0m"
notice="\033[93;1m[!]\033[0m"
question="\033[93;1m[?]\033[0m"

Green="\033[92m"
Red="\033[91m"
Blue="\033[94m"
skyBlue="\033[38;5;117m"
Cyan="\033[96m"
White="\033[37m"
Yellow="\033[93m"
Reset="\033[0m"

# --- Construct the crdl shape using string concatenation (ANSI Lean Font) ---
print_crdl() {
  printf "${Blue}     https://github.com/arghya339/crdl${Reset}\n"                                               
  printf "${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}    _/  ${Reset} ${Cyan}         _/  _/${Reset}\n"   
  printf "${skyBlue}    _/_/_/${Reset}${Blue}  _/  _/_/${Reset}  ${White}     _/ ${Reset} ${Cyan}    _/_/_/  _/ ${Reset}\n"   
  printf "${skyBlue} _/      ${Reset}${Blue}  _/_/     ${Reset}  ${White}      _/${Reset} ${Cyan} _/    _/  _/  ${Reset}\n"   
  printf "${skyBlue}_/       ${Reset}${Blue} _/        ${Reset}  ${White}   _/   ${Reset} ${Cyan}_/    _/  _/   ${Reset}\n"   
  printf "${skyBlue} _/_/_/  ${Reset}${Blue}_/         ${Reset}  ${White}_/      ${Reset} ${Cyan} _/_/_/  _/    ${Reset}\n"   
  printf "${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}        ${Reset} ${Cyan}               ${Reset}\n"   
  printf "${White}𝒟𝑒𝓋𝑒𝓁𝑜𝓅𝑒𝓇: @𝒶𝓇𝑔𝒽𝓎𝒶𝟥𝟥𝟫 ${Reset}${Blue} ${Reset} ${White}_/_/_/_/_/${Reset}${Cyan}               ${Reset}\n"
  printf '\n'
  printf '\n'   
}

# --- Storage Permission Check Logic ---
if [ ! -d "$HOME/storage/shared" ]; then
    # Attempt to list /storage/emulated/0 to trigger the error
    error=$(ls /storage/emulated/0 2>&1)
    expected_error="ls: cannot open directory '/storage/emulated/0': Permission denied"

    if echo "$error" | grep -qF "$expected_error" || ! echo "$error" | grep -q "^Android"; then
        echo -e "${notice} Storage permission not granted. Running termux-setup-storage.."
        termux-setup-storage
        exit 1  # Exit the script after handling the error
    else
        echo -e "${bad} Unknown error: $error"
        exit 1  # Exit on any other error
    fi
fi

# --- Checking Internet Connection ---
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 ; then
  echo -e "${bad} ${Red} Oops! No Internet Connection available.\nConnect to the Internet and try again later."
  exit 1
fi

# --- Global variables ---
Android=$(getprop ro.build.version.release | cut -d. -f1)  # Get major Android version
arch=$(getprop ro.product.cpu.abi)  # Get Android architecture
OEM=$(getprop ro.product.manufacturer)  # Get Device Manufacturer
cloudflareDOH="-L --doh-url https://cloudflare-dns.com/dns-query"
outdatedPKG=$(apt list --upgradable 2>/dev/null)
memTotalKB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
FIRST_INSTALL="$HOME/.FIRST_INSTALL"
LAST_INSTALL="$HOME/.LAST_INSTALL"
INSTALLED_VERSION="$HOME/.INSTALLED_VERSION"
installedPosition=$(cat "$LAST_INSTALL" 2>/dev/null)
installedVersion=$(cat "$INSTALLED_VERSION" 2>/dev/null)
AndroidDesktop="$HOME/.AndroidDesktop_arm64"
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"

# --- Checking Android Version ---
if [ $Android -le 7 ]; then
  echo -e "${bad} ${Red}Android $Android is not supported by Chromium.${Reset}"  # Chromium required Android 8+
  exit 1
fi

# --- Checking device arch ---
if [ $arch == "x86" ]; then
    echo -e "$bad ${Red} x86 (32-bit) arch prebuilt binary not provide by Google Chromium, try manual build Chromium from src."
    termux-open-url "https://chromium.googlesource.com/chromium/src/+/0267e3c2/docs/android_build_instructions.md"
    if [ $Android -ge 9 ]; then
      echo -e "$info Find Chromium alternative as BraveMonox86.apk"
      termux-open "https://github.com/brave/brave-browser/releases/latest/"
    else
      echo -e "$info Find Chromium alternative as Firefox"
      termux-open "https://play.google.com/store/apps/details?id=org.mozilla.firefox"
    fi
    exit 1
fi

clear && echo -e "${Yellow}Please wait! starting crdl...${Reset}"

# --- bash pkg update function ---
update_bash() {
  if echo $outdatedPKG | grep -q "^bash/" 2>/dev/null; then
    pkg upgrade bash -y > /dev/null 2>&1
  fi
}

# --- Check if bash is installed ---
if which bash > /dev/null 2>&1; then
  update_bash
else
  pkg install bash -y > /dev/null 2>&1
fi

# --- grep pkg update function ---
update_grep() {
  if echo $outdatedPKG | grep -q "^grep/" 2>/dev/null; then
    pkg upgrade grep -y > /dev/null 2>&1
  fi
}

# --- Check if grep is installed ----
if [ -f "$PREFIX/bin/grep" ]; then
  update_grep
else
  pkg install grep -y > /dev/null 2>&1
fi

# --- curl pkg update function ---
update_curl() {
  if echo $outdatedPKG | grep -q "^curl/" 2>/dev/null; then
    pkg upgrade curl -y > /dev/null 2>&1
  fi
}

# --- Check if curl is installed ----
if [ -f "$PREFIX/bin/curl" ]; then
  update_curl
else
  pkg install curl -y > /dev/null 2>&1
fi

# --- jq pkg update function ---
update_jq() {
  if echo $outdatedPKG | grep -q "^jq/" 2>/dev/null; then
    pkg upgrade jq -y > /dev/null 2>&1
  fi
}

# --- Check if jq is installed ---
if [ -f "$PREFIX/bin/jq" ]; then
    update_jq  # Check jq pkg updates by calling the function
else
    pkg install jq -y > /dev/null 2>&1
fi

# --- unzip pkg update function ---
update_unzip() {
  if echo $outdatedPKG | grep -q "^unzip/" 2>/dev/null; then
    pkg upgrade unzip -y > /dev/null 2>&1
  fi
}

# --- Check if unzip is installed ---
if [ -f "$PREFIX/bin/unzip" ]; then
  update_unzip  # Check unzip pkg updates by calling the function
else
  pkg install unzip -y > /dev/null 2>&1
fi

# --- bc pkg update function ---
update_bc() {
  if echo $outdatedPKG | grep -q "^bc/" 2>/dev/null; then
    pkg upgrade bc -y > /dev/null 2>&1
  fi
}

# --- Check if bc is installed ---
if [ -f "$PREFIX/bin/bc" ]; then
  update_bc
else
  pkg install bc -y > /dev/null 2>&1
fi

if [ $arch == "arm64-v8a" ] && [ ! -f $AndroidDesktop ] && [ ! -f "$LAST_INSTALL" ]; then
  echo -e "$question Do you want to install Extensions supported AndroidDesktop Chromium.apk? [Y/n]"
  read -r -p "Select: " crx
        case $crx in
            y*|Y*|"")
              touch "$AndroidDesktop"
              echo -e "$info crdl Extensions config are store in a $AndroidDesktop file. \nif you don't need AndroidDesktopChromium please remove this file by running following command in Termux ~ rm $AndroidDesktop" && sleep 6
              ;;
            n*|N*)
              echo -e "$notice AndroidDesktopChromium skipped."
              ;;
            *)
              echo -e "$info Invalid choice. AndroidDesktop skipped."
              ;;
        esac
fi

# --- Variables ---
memTotalGB=$(echo "scale=2; $memTotalKB / 1048576" | bc -l 2>/dev/null || echo "0")  # scale=2 ensures the result is rounded to 2 decimal places for readability, 1048576 (which is 1024 * 1024, since 1 GB = 1024 MB and 1 MB = 1024 kB), bc is a basicCalculator
# --- Detect arch (ARM or ARM64 or x86_64) ---
if [ $arch == "arm64-v8a" ]; then
    # Prefer 32-bit apk if device is usually low on memory (RAM).
    if [ -f $AndroidDesktop ]; then
      snapshotPlatform="AndroidDesktop_arm64"
    elif [ $(echo "$memTotalGB <= 4" | bc -l) -eq 1 ]; then  # Prefer 32-bit apk if device is usually lessthen 4GB RAM.
      snapshotPlatform="Android"
    else
      snapshotPlatform="Android_Arm64"  # For ARM64
    fi
elif [ $arch == "armeabi-v7a" ]; then
    snapshotPlatform="Android"  # For ARM
elif [ $arch == "x86_64" ]; then
    snapshotPlatform="AndroidDesktop_x64" # For x86_64
fi
LAST_CHANGE=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")
if [ ! -f "$FIRST_INSTALL" ]; then
  touch "$FIRST_INSTALL"  # create FIRST_INSTALL file if it doesn't exist
fi
# Get crdl Script First Access time in 'YYYY-MM-DD HH:MM' format
crdlAccessTime=$(stat -c "%x" $FIRST_INSTALL | awk '{print $1, substr($2,1,5)}')
# Get current time in the same format
currentTime=$(date "+%Y-%m-%d %H:%M")

# --- Shizuku Setup first time ---
if ! $HOME/rish -c "id" >/dev/null 2>&1 && [ ! -f "$LAST_INSTALL" ] && [ "crdlAccessTime" == "currentTime" ]; then
  termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  if [ ! -f "$HOME/rish" ] || [ ! -f "$HOME/rish_shizuku.dex" ]; then
    curl -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish" && chmod +x "$HOME/rish" > /dev/null 2>&1
    sleep 0.5 && curl -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish_shizuku.dex" > /dev/null 2>&1
  fi
  if [ $Android -le 10 ]; then
    termux-open-url "https://youtu.be/ZxjelegpTLA"  # YouTube/@MrPalash360: Start Shizuku using Computer
  elif [ $Android -ge 11 ]; then
    termux-open-url "https://youtu.be/YRd0FBfdntQ"  # YouTube/@MrPalash360: Start Shizuku Android 11+
  fi
  exit 1
fi

if [ $snapshotPlatform == "AndroidDesktop_arm64" ] || [ $snapshotPlatform == "AndroidDesktop_x64" ]; then
  crUNZIP="chrome-android-desktop"
else
  crUNZIP="chrome-android"
fi

# --- install Chromium function ---
crInstall() {
  if su -c "id" >/dev/null 2>&1; then
    su -c "cp '$HOME/$crUNZIP/apks/ChromePublic.apk' '/data/local/tmp/ChromePublic.apk'"  # copy apk to System dir to avoiding SELinux restrictions
    rm -rf "$HOME/$crUNZIP"
    su -c "pm install -i com.android.vending '/data/local/tmp/ChromePublic.apk'"
    su -c "rm '/data/local/tmp/ChromePublic.apk'"  # Cleanup temporary APK
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c "cp '$HOME/$crUNZIP/apks/ChromePublic.apk' '/data/local/tmp/ChromePublic.apk'"  # copy apk to System dir
    rm -rf "$HOME/$crUNZIP"
    ./rish -c "pm install -i com.android.vending '/data/local/tmp/ChromePublic.apk'"
    $HOME/rish -c "rm '/data/local/tmp/ChromePublic.apk'"  # Cleanup temp APK
  elif [ $OEM == "Xiaomi" ] || [ $OEM == "Poco" ] || [ $arch == "x86_64" ]; then
    if [ -f "/sdcard/Download/ChromePublic.apk" ]; then
      rm "/sdcard/Download/ChromePublic.apk"
    fi
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/Download/ChromePublic.apk"
    if [ $OEM == "Xiaomi" ] || [ $OEM == "Poco" ]; then
      echo -e $notice "${Yellow}MIUI Optimization detected! Please manually install Chromium from${Reset} ${Blue}file:///sdcard/Download/ChromePublic.apk${Reset}"
    else
      echo -e $notice "${Yellow}There was a problem open the Chromium package using Termux API! Please manually install Chromium from${Reset} ${Blue}file:///sdcard/Download/ChromePublic.apk${Reset}"
    fi
    sleep 3 && rm -rf "$HOME/$crUNZIP"
  elif [ $Android -le 13 ]; then
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/ChromePublic.apk"
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file:///sdcard/ChromePublic.apk" > /dev/null 2>&1  # Activity Manager
    sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm "/sdcard/ChromePublic.apk"
  else
    termux-open "$HOME/$crUNZIP/apks/ChromePublic.apk"  # install apk using Session installer
    sleep 30 && rm -rf "$HOME/$crUNZIP/"
  fi
}

# --- Direct Download Function ---
directDl() {
downloadUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots/$snapshotPlatform/$branchPosition/$crUNZIP.zip"
# Prefer the direct download link if available
if [ -n "$downloadUrl" ] && [ "$downloadUrl" != "null" ]; then
    echo -e "${good} Found valid snapshot at: $branchPosition"
    if [ "$installedPosition" == "$branchPosition" ]; then
        echo -e "$notice Already installed: $installedPosition"
        sleep 3 && clear && exit 0
    else
        echo -e "$running Direct Downloading Chromium $crVersion from $downloadUrl"
        curl -L -o "$HOME/${snapshotPlatform}_${branchPosition}_$crUNZIP.zip" "$downloadUrl"
        echo -e "$running Extrcting ${snapshotPlatform}_${branchPosition}_$crUNZIP.zip"
        unzip -o "$HOME/${snapshotPlatform}_${branchPosition}_$crUNZIP.zip" -d "$HOME/" > /dev/null 2>&1 && rm "$HOME/${snapshotPlatform}_${branchPosition}_$crUNZIP.zip"
        echo -e "$question Do you want to install Chromium_v$crVersion.apk? [Y/n]"
        read -r -p "Select: " opt
              case $opt in
                y*|Y*|"")
                  crInstall && touch "$LAST_INSTALL" && echo "$branchPosition" > "$LAST_INSTALL"
                  clear && exit 0
                  ;;
                n*|N*) echo -e "$notice Chromium installation skipped."; rm -rf "$HOME/$crUNZIP/"; sleep 1 ;;
                *) echo -e "$info Invalid choice! installation skipped."; rm -rf "$HOME/$crUNZIP/"; sleep 2 ;;
              esac
    fi
else
    echo -e "${bad} No direct download URL found." && sleep 1
fi
}

<<comment
# --- Fallback to Chromium snapshots using the list of branch positions from Stable releases ---
findValidSnapshotInEachPossition() {
  echo -e "$running Fetching list of all Stable branch positions.."
  range="70"
  branchDataAll=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=$channel&platform=$snapshotPlatform&num=$range")
  positions=$(echo "$branchDataAll" | jq -r '.[].chromium_main_branchPosition' | sort -nu -r)

  # Iterate through each unique branch position in descending order
  for pos in $positions; do
      echo -e "$running Checking for snapshot at branch position: $pos"
      checkUrl="$branchUrl/$snapshotPlatform/$pos/$crUNZIP.zip"
      if curl --head --silent --fail "$checkUrl" > /dev/null; then
          # Get version for this position
          version=$(echo "$branchDataAll" | jq -r --arg pos "$pos" 'map(select(.chromium_main_branchPosition == ($pos | tonumber))) | .[0].version')
          echo -e "$info Version info for position $pos: $version"
          if [ "$version" == "null" ] || [ -z "$version" ]; then
              version="Unknown"
          fi
          echo -e "$good Found valid snapshot for Chromium version $crVersion at position: $pos"
          if [ "$installedPosition" == "$pos" ] && [ "$installedVersion" == "$crVersion" ]; then
              echo -e "$notice Already installed: $installedVersion"
              sleep 3 && clear && exit 0
          else
              echo -e "$running Downloading Chromium $crVersion from: $checkUrl"
              curl -L -o "$HOME/$crUNZIP.zip" "$checkUrl"
              echo -e "$running Extracting $crUNZIP.zip"
              unzip -o "$HOME/$crUNZIP.zip" -d "$HOME" > /dev/null 2>&1 && rm "$HOME/$crUNZIP.zip"
              echo -e "$question Do you want to install Chromium_v$crVersion.apk? [Y/n]"
              read -r -p "Select: " opt
              case $opt in
                  y*|Y*|"")
                    crInstall && echo "$pos" | tee "$LAST_INSTALL" > /dev/null && echo "$crVersion" | tee "$INSTALLED_VERSION" > /dev/null
                    sleep 3 && clear && exit 0
                    ;;
                  n*|N*)
                    echo -e "$notice Chromium installation skipped."
                    rm -rf "$HOME/$crUNZIP" && sleep 1
                    ;;
                  *)
                    echo -e "$info Invalid choice. Installation skipped."
                    rm -rf "$HOME/$crUNZIP" && sleep 2
                    ;;
              esac
              sleep 3 && break
          fi
      else
          echo -e "$notice No valid snapshot found at position: $pos"
      fi
  done
}
comment

# --- Find valid snapshot by searching downward from branch position ---
findValidSnapshot() {
    local position=$1
    local maxPosition=$2
    local range=500

    # Validate inputs are integers
    if ! [[ "$position" =~ ^[0-9]+$ ]] || ! [[ "$maxPosition" =~ ^[0-9]+$ ]]; then
        echo -e "${bad} Invalid positions: $position (branch) or $maxPosition (max)"
        exit 1
    fi

    echo -e "${running} Searching downward from $position (max attempts: $range)"

    # Search downward starting from branchPosition
    for ((pos = position; pos >= position - range; pos--)); do
        [ "$pos" -lt 0 ] && break  # Stop if we go below 0
        
        checkUrl="$branchUrl/$snapshotPlatform/$pos/$crUNZIP.zip"
        if curl --head --silent --fail "$checkUrl" >/dev/null 2>&1; then
            echo -e "${good} Found valid snapshot at: $pos"
            if [ "$installedPosition" == "$pos" ] && [ "$installedVersion" == "$crVersion" ]; then
                echo -e "$notice Already installed: $installedVersion"
                sleep 3 && clear && exit 0
            else
                echo -e "$running Downloading Chromium $crVersion from: $checkUrl"
                curl -L -o "$HOME/$crUNZIP.zip" "$checkUrl"
                echo -e "$running Extracting $crUNZIP.zip"
                unzip -o "$HOME/$crUNZIP.zip" -d "$HOME" > /dev/null 2>&1 && rm "$HOME/$crUNZIP.zip"
                echo -e "$question Do you want to install Chromium_v$crVersion.apk? [Y/n]"
                read -r -p "Select: " opt
                case $opt in
                    y*|Y*|"")
                      crInstall && echo "$pos" | tee "$LAST_INSTALL" > /dev/null && echo "$crVersion" | tee "$INSTALLED_VERSION" > /dev/null
                      sleep 3 && clear && exit 0
                      ;;
                    n*|N*)
                      echo -e "$notice Chromium installation skipped."
                      rm -rf "$HOME/chrome-android" && sleep 1
                      ;;
                    *)
                      echo -e "$info Invalid choice. Installation skipped."
                      rm -rf "$HOME/chrome-android" && sleep 2 
                      ;;
                esac
                sleep 3 && break  # Break the searching loop
            fi
        else
          echo -e "$notice No valid snapshot found at position: $pos"
        fi
    done
}

# --- Fetch the last Chromium Stable version info ---
sInfo() {
    branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Android&num=2")
    crVersion=$(echo "$branchData" | jq -r '.[1].version')
    branchPosition=$(echo "$branchData" | jq -r '.[1].chromium_main_branch_position')
    echo -e "$info Last Chromium Stable Releases Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the last Chromium Beta version info ---
bInfo() {
    branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Beta&platform=Android&num=1")
    crVersion=$(echo "$branchData" | jq -r '.[0].version')
    branchPosition=$(echo "$branchData" | jq -r '.[0].chromium_main_branch_position')
    echo -e "$info Last Chromium Beta Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the last Chromium Dev version info ---
dInfo() {
    branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Dev&platform=Android&num=1")
    crVersion=$(echo "$branchData" | jq -r '.[0].version')
    branchPosition=$(echo "$branchData" | jq -r '.[0].chromium_main_branch_position')
    echo -e "$info Last Chromium Dev Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the last Chromium Canary version ---
cInfo() {
    branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Android&num=1")
    crVersion=$(echo "$branchData" | jq -r '.[0].version')
    branchPosition=$(echo "$branchData" | jq -r '.[0].chromium_main_branch_position')
    echo -e "$info Last Chromium Canary Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the Chromium Canary Test version info ---
tInfo() {
    branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Android&num=1")
    # canary_milestone=$(echo "$canary_branchData" | jq -r '.[0].milestone')
    crVersion=$(echo "$branchData" | jq -r '.[0].version' | sed -E -e 's/^([0-9]{2})([0-9])/\1X/' -e 's/([0-9])([0-9]{3})\.[0-9]+/\1XXX.X/')
    branchPosition=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")
    echo -e "$info Last Chromium Canary Test Version: $crVersion at branch position: $branchPosition"
}

# --- Main Menu ---
while true; do
  clear  # clear Terminal
  print_crdl  # Call the print crdl shape function
  echo -e "S. Stable \nB. Beta \nD. Dev \nC. Canary \nT. Canary Test \nQ. Quit \n"
  read -r -p "Select Chromium Channel: " channel
        case "$channel" in
          [Ss]*)
            channel="Stable"
            sInfo  # Call the Chromium Stable info function
            findValidSnapshot "$branchPosition" $LAST_CHANGE  # Call the find valid snapshot function and pass the value
            ;;
          [Bb]*)
            channel="Beta"
            bInfo
            findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Dd]*)
            channel="Dev"
            dInfo
            findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Cc]*)
            channel="Canary"
            cInfo
            findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Tt]*)
            tInfo
            directDl  # Call the direct download function
            ;;
          [Qq]*)
            clear  # clear Termianl
            break  # break the loop
            ;;
          *)
            echo -e "$info Invalid option. Please select a valid channel." && sleep 3
            ;;
        esac
done
#####################################################################################
