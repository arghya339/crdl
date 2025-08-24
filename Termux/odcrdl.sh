#!/usr/bin/bash

# Chromium is an open-source browser project, developed and maintained by Google
# Easy Script to download and run last outdated Chromium supported Android build
# Use: ~ curl -L --progress-bar -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/odcrdl.sh" && bash "$HOME/.crdl.sh"
# Developer github.com/arghya339

# --- Downloading latest odcrdl.sh file from GitHub ---
curl -sL -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/odcrdl.sh"

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

# --- Construct the crdl shape using string concatenation (ANSI Speed Font) ---
print_crdl() {
  printf "${Blue}    https://github.com/arghya339/crdl${Reset}\n"
  printf "${skyBlue}       ${Reset}${Blue}       ${Reset}  ${White}___       ${Reset}${Cyan}______________${Reset}\n"
  printf "${skyBlue}_______${Reset}${Blue}_______${Reset}  ${White}__ \      ${Reset}${Cyan}______  /__  /${Reset}\n"
  printf "${skyBlue}_  ___/${Reset}${Blue}_  ___/${Reset}  ${White}___ \     ${Reset}${Cyan}_  __  /__  / ${Reset}\n"
  printf "${skyBlue}/ /__ ${Reset}${Blue}_  /    ${Reset}  ${White}__  /     ${Reset}${Cyan}/ /_/ / _  /  ${Reset}\n"
  printf "${skyBlue}\___/ ${Reset}${Blue}/_/     ${Reset}  ${White}_/_/______${Reset}${Cyan}\__,_/  /_/   ${Reset}\n"
  printf "${skyBlue}      ${Reset}${Blue}        ${Reset}  ${White}   _/_____/${Reset}${Cyan}             ${Reset}\n"
  #printf "${White}𝒟𝑒𝓋𝑒𝓁𝑜𝓅𝑒𝓇:𝒶𝓇𝑔𝒽𝓎𝒶𝟥𝟥𝟫${Reset}${Blue}${Reset}${White}_/_____/${Reset}   ${Cyan}             ${Reset}\n"
  printf "${White}𝒟𝑒𝓋𝑒𝓁𝑜𝓅𝑒𝓇:𝒶𝓇𝑔𝒽𝓎𝒶𝟥𝟥𝟫${Reset}\n"
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
Model=$(getprop ro.product.model)  # Get device model
Android=$(getprop ro.build.version.release | cut -d. -f1)  # Get major Android version
arch=$(getprop ro.product.cpu.abi)  # Get Android architecture
arch32=$(getprop ro.product.cup.abilist32)  # Get Android 32 bit arch
outdatedPKG=$(apt list --upgradable 2>/dev/null)
installedPKG=$(pkg list-installed 2>/dev/null)  # list of installed pkg
memTotalKB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"

# Latest Chromium required Android 10+ (The last Chromium app that supports Android 8-9 is v139.0.7230.0 [universal] & Android 7.0 is v119.0.6045.0 [arm64-v8a, armeabi-v7a] & Android 6.0 is v106.0.5249.0 [armeabi-v7a] & Android 5.0 is v95.0.4638.0 [armeabi-v7a]).
# v139.0.7230.0: 1471513 ~> | Android: 1471509 | Android_Arm64: 1471509 | AndroidDesktop_arm64: 1471504 | AndroidDesktop_x64: 1471508 |
# v119.0.6045.0: 1204232 ~> | Android: 1204232 | Android_Arm64: 1204197 | AndroidDesktop_arm64: N/A     | AndroidDesktop_x64: N/A     |
# v106.0.5249.0: 1036826 ~> | Android: 1036780 | Android_Arm64: N/A     | AndroidDesktop_arm64: N/A     | AndroidDesktop_x64: N/A     |
# v95.0.4638.0 : 920003  ~> | Android: 920003  | Android_Arm64: N/A     | AndroidDesktop_arm64: N/A     | AndroidDesktop_x64: N/A     |

# --- Checking Android Version & Architecture ---
if [ $Android -eq 7 ] && [ $arch == "x86_64" ]; then
  echo -e "${bad} ${Red}Android $Android with Arch $arch is not supported by Chromium.${Reset}"
  echo -e "$info Find Chromium alternative as KiwiBrowser."  # Android 7.0+ (universal)
  termux-open-url "https://github.com/kiwibrowser/src.next/releases/latest/"
elif [[ ( $Android -eq 6 || $Android -eq 5 ) && ( $arch == "armeabi-v8a" || $arch == "x86_64" ) ]]; then
  echo -e "${bad} ${Red}Android $Android with Arch $arch is not supported by Chromium.${Reset}"
  echo -e "$info Find Chromium alternative as Firefox."  # Android 5.0+ (universal)
  termux-open "https://play.google.com/store/apps/details?id=org.mozilla.firefox"
  rm $PREFIX/bin/crdl && rm $HOME/.crdl.sh
  exit 1
fi

# --- Checking device arch ---
if [ $arch == "x86" ]; then
    echo -e "$bad ${Red} x86 (x32-bit) arch prebuilt binary not provide by Google Chromium, try manual build Chromium from src."
    termux-open-url "https://chromium.googlesource.com/chromium/src/+/0267e3c2/docs/android_build_instructions.md"
    if [ $Android -ge 9 ]; then
      echo -e "$info Find Chromium alternative as BraveMonox86.apk"  # Android 9.0+ (universal: arm64-v8a, armeabi-v7a, x86_64, x86)
      termux-open "https://github.com/brave/brave-browser/releases/latest/"
    elif [ $Android -eq 8 ] || [ $Android -eq 7 ]; then
      echo -e "$info Find Chromium alternative as KiwiBrowser."  # Android 7.0+ (universal)
      termux-open-url "https://github.com/kiwibrowser/src.next/releases/latest/"
    else
      echo -e "$info Find Chromium alternative as Firefox."  # Android 5.0+ (universal)
      termux-open "https://play.google.com/store/apps/details?id=org.mozilla.firefox"
    fi
    rm $PREFIX/bin/crdl && rm $HOME/.crdl.sh
    exit 1
fi

clear && echo -e "🚀 ${Yellow}Please wait! starting crdl...${Reset}"

# --- pkg upgrade function ---
pkgUpdate() {
  local pkg=$1
  if echo $outdatedPKG | grep -q "^$pkg/" 2>/dev/null; then
    echo -e "$running Upgrading $pkg pkg.."
    pkg upgrade "$pkg" -y > /dev/null 2>&1
  fi
}

# --- pkg install/update function ---
pkgInstall() {
  local pkg=$1
  if echo "$installedPKG" | grep -q "$pkg" 2>/dev/null; then
    pkgUpdate "$pkg"
  else
    echo -e "$running Installing $pkg pkg.."
    pkg install "$pkg" -y > /dev/null 2>&1
  fi
}

pkgInstall "bash"  # bash update
pkgInstall "grep"  # grep update
pkgInstall "curl"  # curl update
pkgInstall "jq"  # jq install/update
pkgInstall "bsdtar"  # bsdtar install/update
pkgInstall "pv"  # pv install/update
pkgInstall "bc"  # bc install/update

if [ $arch == "arm64-v8a" ] && [ $Android -eq 9 ]; then
  echo -e "$question Do you want to install Extensions supported AndroidDesktop Chromium.apk? [Y/n]"
  read -r -p "Select: " crx
    case $crx in
      y*|Y*|"")
        AndroidDesktop=1      
        ;;
      n*|N*)
        echo -e "$notice AndroidDesktopChromium skipped!"
        AndroidDesktop=0
        ;;
      *)
        echo -e "$info Invalid choice! AndroidDesktop skipped."
        AndroidDesktop=0
        ;;
    esac
fi

# --- Detect arch (ARM or ARM64 or x86_64) ---
if [ $arch == "arm64-v8a" ]; then
    memTotalGB=$(echo "scale=2; $memTotalKB / 1048576" | bc -l 2>/dev/null || echo "0")  # scale=2 ensures the result is rounded to 2 decimal places for readability, 1048576 (which is 1024 * 1024, since 1 GB = 1024 MB and 1 MB = 1024 kB), bc is a basicCalculator
    # Prefer 32-bit apk if device is usually low on memory (RAM).
    if [ $AndroidDesktop == 1 ]; then
      snapshotPlatform="AndroidDesktop_arm64"
    elif [ "$(echo "$memTotalGB <= 4" | bc -l)" -eq 1 ] && [ "$arch32" == "armeabi-v7a,armeabi" ]; then  # Prefer 32-bit apk if device is usually lessthen 4GB RAM.
      snapshotPlatform="Android"
    else
      snapshotPlatform="Android_Arm64"  # For ARM64
    fi
elif [ $arch == "armeabi-v7a" ]; then
    snapshotPlatform="Android"  # For ARM
elif [ $arch == "x86_64" ]; then
    snapshotPlatform="AndroidDesktop_x64" # For x86_64
fi

if [ $Android -eq 9 ] || [ $Android -eq 8 ]; then
  target="139.0.7230."
  num=100
elif [ $Android -eq 7 ]; then
  target="119.0.6045."
  num=200
elif [ $Android -eq 6 ]; then
  target="106.0.5249."
  num=300
elif [ $Android -eq 5 ]; then
  target="95.0.4638."
  num=325
fi

# --- Shizuku Setup first time ---
if ! $HOME/rish -c "id" >/dev/null 2>&1 && ! su -c "id" >/dev/null 2>&1 && { [[ ! -f "$HOME/rish" ]] || [[ ! -f "$HOME/rish_shizuku.dex" ]]; }; then
  echo -e "$info Please manually install Shizuku from Google Play Store." && sleep 1
  #termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  termux-open-url "https://github.com/RikkaApps/Shizuku/releases/latest"
  am start -n com.android.settings/.Settings\$MyDeviceInfoActivity > /dev/null 2>&1  # Open Device Info
  curl -sL --progress-bar -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish"
  [ ! -x "$HOME/rish" ] && chmod +x "$HOME/rish"
  sleep 0.5 && curl -sL --progress-bar -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish_shizuku.dex"
  echo -e "$info Please start Shizuku by following guide. Then rerun script by running ${Cyan}~${Reset} ${Green}crdl${Reset}" && sleep 1
  if [ $Android -le 10 ]; then
    am start -n com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity > /dev/null 2>&1  # Open Developer options
    termux-open-url "https://youtu.be/ZxjelegpTLA"  # YouTube/@MrPalash360: Start Shizuku using Computer
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
    # Temporary Disable SELinux Enforcing during installation if it not in Permissive
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c "pm install -i com.android.vending '/data/local/tmp/ChromePublic.apk'"
      INSTALL_STATUS=$?  # Capture exit status of the install command
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
    else
      su -c "pm install -i com.android.vending '/data/local/tmp/ChromePublic.apk'"
      INSTALL_STATUS=$?  # Capture exit status of the install command
    fi
    am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
    if [ $? != 0 ]; then
      su -c "monkey -p org.chromium.chrome -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
    fi
    su -c "rm -f '/data/local/tmp/ChromePublic.apk'"  # Cleanup temporary APK
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/ChromePublic.apk"
    ~/rish -c "cp '/sdcard/ChromePublic.apk' '/data/local/tmp/ChromePublic.apk'" > /dev/null 2>&1  # copy apk to System dir
    ./rish -c "pm install -r -i com.android.vending '/data/local/tmp/ChromePublic.apk'" > /dev/null 2>&1  # -r=reinstall --force-uplow=downgrade
    INSTALL_STATUS=$?  # Capture exit status of the install command
    am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
    if [ $? != 0 ]; then
      ~/rish -c "monkey -p org.chromium.chrome -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
    fi
    if [ $INSTALL_STATUS -eq 0 ]; then rm -rf "$HOME/$crUNZIP" && rm -f "/sdcard/ChromePublic.apk" && $HOME/rish -c "rm -f '/data/local/tmp/ChromePublic.apk'"; fi  # Cleanup temp APK
  elif [ $OEM == "Xiaomi" ] || [ $OEM == "Poco" ]; then
    if [ -f "/sdcard/Download/ChromePublic.apk" ]; then
      rm -f "/sdcard/Download/ChromePublic.apk"
    fi
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/Download/ChromePublic.apk"
    echo -e $notice "${Yellow}MIUI Optimization detected! Please manually install Chromium from${Reset} Files: $Model > ${Blue}Download${Reset} > ChromePublic.apk"
    sleep 3 && rm -rf "$HOME/$crUNZIP"
    am start -n "com.google.android.documentsui/com.android.documentsui.files.FilesActivity" > /dev/null 2>&1  # Open Android Files by Google
    if [ $? -ne 0 ] || [ $? -eq 2 ]; then
      am start -n "com.android.documentsui/com.android.documentsui.files.FilesActivity" > /dev/null 2>&1  # Open Android Files
    fi
  elif [ $Android -le 7 ]; then
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/ChromePublic.apk"
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file:///sdcard/ChromePublic.apk" > /dev/null 2>&1  # Activity Manager
    INSTALL_STATUS=$?
    if [ "$INSTALL_STATUS" != "0" ]; then
      termux-open "$HOME/$crUNZIP/apks/ChromePublic.apk"
      FALLBACK_INSTALL_STATUS=$?
    fi
    if [ "$INSTALL_STATUS" -eq "0" ] || [ "$FALLBACK_INSTALL_STATUS" -eq "0" ]; then
      am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm -f "/sdcard/ChromePublic.apk"
    else
      if [ -f "/sdcard/Download/ChromePublic.apk" ]; then
        rm -f "/sdcard/Download/ChromePublic.apk"
      fi
      cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/Download/ChromePublic.apk"
      echo -e $notice "${Yellow}There was a problem open the Chromium package using Termux API! Please manually install Chromium from${Reset} Files: $Model > ${Blue}Download${Reset} > ChromePublic.apk"
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm -f "/sdcard/ChromePublic.apk"
    fi
  else
    termux-open --view "$HOME/$crUNZIP/apks/ChromePublic.apk"  # install apk using Session installer
    INSTALL_STATUS=$?
    if [ "$INSTALL_STATUS" != "0" ]; then
      cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/ChromePublic.apk"
      am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file:///sdcard/ChromePublic.apk" > /dev/null 2>&1  # Activity Manager
      FALLBACK_INSTALL_STATUS=$?
    fi
    if [ "$INSTALL_STATUS" -eq "0" ] || [ "$FALLBACK_INSTALL_STATUS" -eq "0" ]; then
      am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm -f "/sdcard/ChromePublic.apk"
    else
      if [ -f "/sdcard/Download/ChromePublic.apk" ]; then
        rm -f "/sdcard/Download/ChromePublic.apk"
      fi
      cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/Download/ChromePublic.apk"
      echo -e $notice "${Yellow}There was a problem open the Chromium package using Termux API! Please manually install Chromium from${Reset} Files: $Model > ${Blue}Download${Reset} > ChromePublic.apk"
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm -f "/sdcard/ChromePublic.apk"
    fi
  fi
}

# --- Find valid snapshot by searching downward from branch position ---
findValidSnapshot() {
  local position=$1
  local range=500

  echo -e "${running} Searching downward from $position (max attempts: $range)"
  
  # Search downward starting from branchPosition
  for ((pos = position; pos >= position - range; pos--)); do
    [ "$pos" -lt 0 ] && break  # Stop if we go below 0
    checkUrl="$branchUrl/$snapshotPlatform/$pos/$crUNZIP.zip"
    if curl --head --silent --fail "$checkUrl" >/dev/null 2>&1; then
      echo -e "${good} Found valid snapshot at: $pos" && echo
      crdlSize=$(curl -sIL $checkUrl 2>/dev/null | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }' 2>/dev/null)
      echo -e "$running Downloading Chromium $crVersion from: ${Blue}$checkUrl${Reset} $crdlSize"
      while true; do
        curl -L --progress-bar -C - -o "$HOME/$crUNZIP.zip" "$checkUrl"
        DOWNLOAD_STATUS=$?
        if [ $DOWNLOAD_STATUS -eq "0" ]; then
          break  # break the resuming download loop
        fi
        echo -e "$notice Retrying in 5 seconds.." && sleep 5  # wait 5 seconds
      done
      echo && echo -e "$running Extracting ${Red}$crUNZIP.zip${Reset}"
      pv "$HOME/$crUNZIP.zip" | bsdtar -xf - -C "$HOME" --include "$crUNZIP/apks/ChromePublic.apk" && rm "$HOME/$crUNZIP.zip"
      echo && echo -e "$question Do you want to install Chromium_v$crVersion.apk? [Y/n]"
      read -r -p "Select: " opt
      case $opt in
        y*|Y*|"")
          crInstall
          if [ "$AndroidDesktop" -eq 1 ]; then
            curl -L --progress-bar -o "$HOME/top-30.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh && bash "$HOME/top-30.sh" && rm "$HOME/top-30.sh"
          fi
          if su -c "id" >/dev/null 2>&1 || "$HOME/rish" -c "id" >/dev/null 2>&1; then
            if [ $INSTALL_STATUS -eq 0 ]; then
              rm $PREFIX/bin/crdl && rm $HOME/.crdl.sh
            else
              echo -e "$bad installation failed!" && sleep 1
            fi
          fi
          ;;
        n*|N*)
          echo -e "$notice Chromium installation skipped!"
          rm -rf "$HOME/chrome-android" && sleep 1
          ;;
        *)
          echo -e "$info Invalid choice! Installation skipped."
          rm -rf "$HOME/chrome-android" && sleep 2 
          ;;
      esac
      sleep 3 && break  # Break the searching loop
    else
      echo -e "$notice No valid snapshot found at position: $pos"
    fi
  done
}

# --- Fetch Chromium version info ---
sInfo() {
    attempts=5
    attempt_count=0
    
    if [ $Android -eq 9 ] || [ $Android -eq 8 ]; then
      channel=Canary
    else
      channel=Stable
    fi

    while true; do
        dashUrl="https://chromiumdash.appspot.com/fetch_releases?channel=$channel&platform=Android&num=$num"
        branchData=$(curl -sL "$dashUrl" | jq --arg t "$target" 'map(select(.version | startswith($t))) | first')
        crVersion=$(echo "$branchData" | jq -r '.version')
        prefix=$(echo "$crVersion" | awk -F '.' '{print $1"."$2"."$3"."}')
        
        if [ "$prefix" = "$target" ]; then
            branchPosition=$(echo "$branchData" | jq -r '.chromium_main_branch_position')
            echo -e "$info Last Chromium $channel Releases Version: $crVersion at branch position: $branchPosition"
            break
        fi
        
        attempt_count=$((attempt_count + 1))
        num=$((num + 100))
        if (( attempt_count >= attempts )); then
          echo -e "$bad Version starting with $target not found after $attempts attempts!" >&2
          return 1
        fi
    done
}

# --- Main Execution ---
clear  # clear Terminal
print_crdl  # Call the print crdl shape function
echo && sInfo  # Call the Chromium Stable info function
echo && findValidSnapshot "$branchPosition"
#######################################################
