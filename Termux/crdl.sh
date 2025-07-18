#!/usr/bin/bash

# Chromium is an open-source browser project, developed and maintained by Google
# Easy Script to download and run latest Chromium Android build
# Use: ~ curl --progress-bar -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/crdl.sh" && bash "$HOME/.crdl.sh"
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
Model=$(getprop ro.product.model)  # Get device model
Android=$(getprop ro.build.version.release | cut -d. -f1)  # Get major Android version
arch=$(getprop ro.product.cpu.abi)  # Get Android architecture
arch32=$(getprop ro.product.cup.abilist32)  # Get Android 32 bit arch
socOEM=$(getprop ro.soc.manufacturer)  # Get SOC Manufacturer
OEM=$(getprop ro.product.manufacturer)  # Get Device Manufacturer
apMode=$(getprop persist.radio.airplane_mode_on)  # Get AirPlane Mode Status (0=OFF; 1=ON)
networkType1=$(getprop gsm.network.type | cut -d',' -f1)  # Get SIM1 Network type (NR_SA/NR_NSA,LTE)
networkType2=$(getprop gsm.network.type | cut -d',' -f2)  # Get SIM2 Network type (NR_SA/NR_NSA,LTE)
networkName1=$(getprop gsm.operator.alpha | cut -d',' -f1)  # Get SIM1 Carrier name
networkName2=$(getprop gsm.operator.alpha | cut -d',' -f2)  # Get SIM2 Carrier name
simOperator1=$(getprop gsm.sim.operator.alpha | cut -d',' -f1)  # Get SIM1 Operator name
simOperator2=$(getprop gsm.sim.operator.alpha | cut -d',' -f2)  # Get SIM2 Operator name
simCountry=$(getprop gsm.sim.operator.iso-country | cut -d',' -f1)  # Get SIM1 Country
cloudflareDOH="-L --doh-url https://cloudflare-dns.com/dns-query"
outdatedPKG=$(apt list --upgradable 2>/dev/null)
installedPKG=$(pkg list-installed 2>/dev/null)  # list of installed pkg
memTotalKB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
crdlJson="$HOME/.crdl.json"  # json file to store crdl related data
installedPosition=$(jq -r '.INSTALLED_POSITION' "$crdlJson" 2>/dev/null)
installedVersion=$(jq -r '.INSTALLED_VERSION' "$crdlJson" 2>/dev/null)
AndroidDesktop=$(jq -r '.AndroidDesktop' "$crdlJson" 2>/dev/null)
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"
appSize=$(jq -r '.APP_SIZE' "$crdlJson" 2>/dev/null)
appVersion=$(jq -r '.APP_VERSION' "$crdlJson" 2>/dev/null)
installedTime=$(jq -r '.INSTALLED_TIME' "$crdlJson" 2>/dev/null)
if su -c "id" >/dev/null 2>&1; then
  if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
    su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
    package=$(su -c "pm list packages | grep com.cloudflare.onedotonedotonedotone" 2>/dev/null)  # Cloudflare 1.1.1.1 packages list
    pvDnsMode=$(su -c "settings get global private_dns_mode" 2>/dev/null)  # off
    pvDnsSpec=$(su -c "settings get global private_dns_specifier" 2>/dev/null)  # null
    su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
  else
    package=$(su -c "pm list packages | grep 'com.cloudflare.onedotonedotonedotone'" 2>/dev/null)  # SnapChat packages list
    pvDnsMode=$(su -c "settings get global private_dns_mode" 2>/dev/null)  # off
    pvDnsSpec=$(su -c "settings get global private_dns_specifier" 2>/dev/null)  # null
  fi
elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
  package=$(~/rish -c "pm list packages | grep 'com.cloudflare.onedotonedotonedotone'" 2>/dev/null)  # SnapChat packages list
  pvDnsMode=$('$HOME/rish' -c "settings get global private_dns_mode" 2>/dev/null)  # off
  pvDnsSpec=$(./rish -c "settings get global private_dns_specifier" 2>/dev/null)  # null
fi

# --- Checking Android Version ---
# Latest Chromium required Android 10+
if [ $Android -le 9 ]; then
  echo -e "${bad} ${Red}Android $Android is not supported by Chromium.${Reset}"
  if [ $Android -eq 9 ]; then
    echo -e "$info Find Chromium alternative as Brave."  # Android 9.0+ (universal: arm64-v8a, armeabi-v7a, x86_64, x86)
    termux-open "https://github.com/brave/brave-browser/releases/latest/"
  elif [ $Android -eq 8 ] || [ $Android -eq 7 ]; then
    echo -e "$info Find Chromium alternative as KiwiBrowser."  # Android 7.0+ (universal)
    termux-open-url "https://github.com/kiwibrowser/src.next/releases/latest/"
  else
    echo -e "$info Find Chromium alternative as Firefox."  # Android 5.0+ (universal)
    termux-open "https://play.google.com/store/apps/details?id=org.mozilla.firefox"
  fi
  curl -L --progress-bar -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/odcrdl.sh" && bash "$HOME/.crdl.sh"
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
pkgInstall "aria2"  # aria2 install/update
pkgInstall "jq"  # jq install/update
pkgInstall "bsdtar"  # bsdtar install/update
pkgInstall "pv"  # pv install/update
pkgInstall "bc"  # bc install/update
pkgInstall "pup"  # pup install/update

# --- Download and give execute (--x) permission to AAPT2 Binary ---
if [ ! -f "$HOME/aapt2" ]; then
  curl -L "https://github.com/arghya339/aapt2/releases/download/all/aapt2_$arch" -o "$HOME/aapt2" > /dev/null 2>&1 && chmod +x "$HOME/aapt2"
fi

if [ $arch == "arm64-v8a" ] && [ ! -f "$crdlJson" ]; then
  echo -e "$question Do you want to install Extensions supported AndroidDesktop Chromium.apk? [Y/n]"
  read -r -p "Select: " crx
        case $crx in
            y*|Y*|"")
              jq -n "{ \"AndroidDesktop\": 1 }" > "$crdlJson"
              AndroidDesktop=$(jq -r '.AndroidDesktop' "$crdlJson" 2>/dev/null)
              echo -e "$info crdl Extensions config are store in a '$crdlJson' file. \nif you don't need AndroidDesktopChromium, please remove this file by running following command in Termux ${Cyan}~${Reset} ${Green}jq${Reset} ${Yellow}'del(.AndroidDesktop)' \"${Reset}${Cyan}\$HOME${Reset}${Yellow}/.crdl.json\" >${Reset} temp.json && ${Green}mv${Reset} temp.json \$HOME/.crdl.json" && sleep 10
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
LAST_CHANGE=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")

# --- Shizuku Setup first time ---
if ! $HOME/rish -c "id" >/dev/null 2>&1 && ! su -c "id" >/dev/null 2>&1 && { [[ ! -f "$HOME/rish" ]] || [[ ! -f "$HOME/rish_shizuku.dex" ]]; }; then
  echo -e "$info Please manually install Shizuku from Google Play Store." && sleep 1
  termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  am start -n com.android.settings/.Settings\$MyDeviceInfoActivity > /dev/null 2>&1  # Open Device Info
  curl -sL --progress-bar -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish"
  [ ! -x "$HOME/rish" ] && chmod +x "$HOME/rish"
  sleep 0.5 && curl -sL --progress-bar -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish_shizuku.dex"
  echo -e "$info Please start Shizuku by following guide. Then rerun script by running ${Cyan}~${Reset} ${Green}crdl${Reset}" && sleep 1
  if [ $Android -le 10 ]; then
    am start -n com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity > /dev/null 2>&1  # Open Developer options
    termux-open-url "https://youtu.be/ZxjelegpTLA"  # YouTube/@MrPalash360: Start Shizuku using Computer
  else
    am start -n com.android.settings/.Settings\$WirelessDebuggingActivity > /dev/null 2>&1  # Open Wireless Debugging Settings
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
    su -c "rm '/data/local/tmp/ChromePublic.apk'"  # Cleanup temporary APK
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/ChromePublic.apk"
    ~/rish -c "cp '/sdcard/ChromePublic.apk' '/data/local/tmp/ChromePublic.apk'" > /dev/null 2>&1  # copy apk to System dir
    ./rish -c "pm install -r -i com.android.vending '/data/local/tmp/ChromePublic.apk'" > /dev/null 2>&1  # -r=reinstall --force-uplow=downgrade
    INSTALL_STATUS=$?  # Capture exit status of the install command
    am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
    if [ $? != 0 ]; then
      ~/rish -c "monkey -p org.chromium.chrome -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
    fi
    sleep 30 && rm -rf "$HOME/$crUNZIP" && rm "/sdcard/ChromePublic.apk" && $HOME/rish -c "rm '/data/local/tmp/ChromePublic.apk'"  # Cleanup temp APK
  elif [ $OEM == "Xiaomi" ] || [ $OEM == "Poco" ] || [ $arch == "x86_64" ]; then
    if [ -f "/sdcard/Download/ChromePublic.apk" ]; then
      rm "/sdcard/Download/ChromePublic.apk"
    fi
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/Download/ChromePublic.apk"
    if [ $OEM == "Xiaomi" ] || [ $OEM == "Poco" ]; then
      echo -e $notice "${Yellow}MIUI Optimization detected! Please manually install Chromium from${Reset} ${Blue}file:///sdcard/Download/ChromePublic.apk${Reset}"
    else
      echo -e $notice "${Yellow}There was a problem open the Chromium package using Termux API! Please manually install Chromium from${Reset} Files: $Model > ${Blue}Download${Reset} > ChromePublic.apk"
    fi
    sleep 3 && rm -rf "$HOME/$crUNZIP"
    am start -n com.google.android.documentsui/com.android.documentsui.files.FilesActivity > /dev/null 2>&1  # Open Android Files
  elif [ $Android -le 13 ]; then
    cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/ChromePublic.apk"
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file:///sdcard/ChromePublic.apk" > /dev/null 2>&1  # Activity Manager
    INSTALL_STATUS=$?
    if [ "$INSTALL_STATUS" != "0" ]; then
      termux-open "$HOME/$crUNZIP/apks/ChromePublic.apk"
      FALLBACK_INSTALL_STATUS=$?
    fi
    if [ "$INSTALL_STATUS" == "0" ] || [ "$FALLBACK_INSTALL_STATUS" == "0" ]; then
      am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm "/sdcard/ChromePublic.apk"
    else
      if [ -f "/sdcard/Download/ChromePublic.apk" ]; then
        rm "/sdcard/Download/ChromePublic.apk"
      fi
      cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/Download/ChromePublic.apk"
      echo -e $notice "${Yellow}There was a problem open the Chromium package using Termux API! Please manually install Chromium from${Reset} Files: $Model > ${Blue}Download${Reset} > ChromePublic.apk"
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm "/sdcard/ChromePublic.apk"
    fi
  else
    termux-open "$HOME/$crUNZIP/apks/ChromePublic.apk"  # install apk using Session installer
    INSTALL_STATUS=$?
    if [ "$INSTALL_STATUS" != "0" ]; then
      cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/ChromePublic.apk"
      am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file:///sdcard/ChromePublic.apk" > /dev/null 2>&1  # Activity Manager
      FALLBACK_INSTALL_STATUS=$?
    fi
    if [ "$INSTALL_STATUS" == "0" ] || [ "$FALLBACK_INSTALL_STATUS" == "0" ]; then
      am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm "/sdcard/ChromePublic.apk"
    else
      if [ -f "/sdcard/Download/ChromePublic.apk" ]; then
        rm "/sdcard/Download/ChromePublic.apk"
      fi
      cp "$HOME/$crUNZIP/apks/ChromePublic.apk" "/sdcard/Download/ChromePublic.apk"
      echo -e $notice "${Yellow}There was a problem open the Chromium package using Termux API! Please manually install Chromium from${Reset} Files: $Model > ${Blue}Download${Reset} > ChromePublic.apk"
      sleep 30 && rm -rf "$HOME/$crUNZIP/" && rm "/sdcard/ChromePublic.apk"
    fi
  fi
}

# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  clear  # clear aria2 multi error log from console
  print_crdl  # call the print_crdl function 
  if [ -f "$crdlJson" ]; then
    echo -e "$info INSTALLED: Chromium v$appVersion - $appSize - $installedTime" && echo
  fi
  echo -e "S. Stable \nB. Beta \nD. Dev \nC. Canary \nT. Canary Test \nQ. Quit \n"
  echo "Select Chromium Channel: $channel"
  echo && echo -e "$info Last Chromium Canary Test Version: $crVersion at branch position: $branchPosition"
  echo -e "${good} Found valid snapshot at: $branchPosition" && echo
  echo -e "$running Direct Downloading Chromium $crVersion from ${Blue}$downloadUrl${Reset} $crdlSize"
}

# --- Direct Download Function ---
directDl() {
downloadUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots/$snapshotPlatform/$branchPosition/$crUNZIP.zip"
# Prefer the direct download link if available
if [ -n "$downloadUrl" ] && [ "$downloadUrl" != "null" ]; then
    echo -e "${good} Found valid snapshot at: $branchPosition" && echo
    if [ "$installedPosition" == "$branchPosition" ]; then
        echo -e "$notice Already installed: $installedPosition"
        sleep 3 && clear && exit 0
    else
        crdlSize=$(curl -sIL $downloadUrl 2>/dev/null | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }' 2>/dev/null)
        echo -e "$running Direct Downloading Chromium $crVersion from ${Blue}$downloadUrl${Reset} $crdlSize"
        while true; do
            #curl -L --progress-bar -C - -o "$HOME/$crUNZIP.zip" "$downloadUrl"
            aria2c -x 16 -s 16 --continue=true --console-log-level=error --summary-interval=0 --download-result=hide -o "$crUNZIP.zip" -d "$HOME" "$downloadUrl"
            DOWNLOAD_STATUS=$?
            echo
            if [ $DOWNLOAD_STATUS -eq "0" ]; then
              break  # break the resuming download loop
            elif [ $DOWNLOAD_STATUS -eq "6" ] || [ $DOWNLOAD_STATUS -eq "19" ]; then
              aria2ConsoleLogHide  # for aria2
              echo -e "$bad ISP: $simOperator1 / $simOperator2 failed to resolve ${Blue}https://commondatastorage.googleapis.com/${Reset} host!"
              echo -e "$info Connect Cloudflare 1.1.1.1 + WARP, 1.1.1.1 one of the fastest DNS resolvers on Earth."
              if su -c "id" >/dev/null 2>&1 && [ "$pvDnsMode" == "off" ] && [ "$pvDnsSpec" == "null" ]; then
                if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
                  su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
                  su -c "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
                  su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
                else
                  su -c "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
                fi
                putDns="1"
              elif "$HOME/rish" -c "id" >/dev/null 2>&1 && [ "$pvDnsMode" == "off" ] && [ "$pvDnsSpec" == "null" ]; then
                ~/rish -c "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
                putDns="1"
              else
                am start -n com.cloudflare.onedotonedotonedotone/com.cloudflare.app.presentation.main.SplashActivity > /dev/null 2>&1
                if [ $simCountry != "in" ]; then
                  termux-open-url "https://play.google.com/store/apps/details?id=com.cloudflare.onedotonedotonedotone"
                else
                  termux-open "https://www.apkmirror.com/apk/cloudflare/1-1-1-1-faster-safer-internet/"
                  sleep 0.5 && termux-open "https://github.com/Aefyr/SAI/releases/latest/"
                fi
              fi
            elif [ $DOWNLOAD_STATUS -eq "56" ] || [ $DOWNLOAD_STATUS -eq "1" ]; then
              aria2ConsoleLogHide  # for aria2
              echo -e "$bad $networkName1 / $networkName2 signal are unstable!"
              if [ $apMode == 1 ]; then
                echo -e "$notice Please turn off Airplane mode!"
              fi
              am start -a android.settings.WIRELESS_SETTINGS > /dev/null 2>&1
              if [ $networkType1 == "LTE" ] && [ $networkType2 == "NR_SA" ]; then
                echo -e "$info If Mobile data is turned on for SIM1, please switch Mobile data to SIM2: $simOperator2"
                am start -a android.settings.MANAGE_ALL_SIM_PROFILES_SETTINGS > /dev/null 2>&1
              elif [ $networkType2 == "LTE" ] && [ $networkType1 == "NR_SA" ]; then
                echo -e "$info If Mobile data is turned on for SIM2, please switch Mobile data to SIM1: $simOperator1"
                am start -a android.settings.MANAGE_ALL_SIM_PROFILES_SETTINGS > /dev/null 2>&1
              else
                echo -e "$info Please connect to Wi-Fi if there is a network available near you."
                am start -a android.settings.WIFI_SETTINGS > /dev/null 2>&1
              fi
              if [[ "$networkType1" == "GSM" || "$networkType1" == "WCDMA" || "$networkType1" == "UMTS" || "$networkType2" == "GSM" || "$networkType2" == "WCDMA" || "$networkType2" == "UMTS" ]]; then
                if [ $socOEM == "Mediatek" ] && su -c "id" >/dev/null 2>&1; then
                  echo -e "$info Please select Network Type: LTE/NR"
                  su -c "am start --user 0 -n com.mediatek.engineermode/.EngineerMode > /dev/null"
                fi
                if [ $socOEM != "Mediatek" ]; then
                  echo -e "$info Please select Network Type: LTE/NR"
                  am start -n com.android.phone/.settings.RadioInfo > /dev/null 2>&1  # Open Redio Info
                fi
              fi
            fi
            echo -e "$notice Download failed! retrying in 5 seconds.." && sleep 5  # wait 5 seconds
        done
        if [ "$putDns" == "1" ] && [ "$pvDnsMode" == "hostname" ] && [ "$pvDnsSpec" == "one.one.one.one" ]; then
          if su -c "id" >/dev/null 2>&1; then
            if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
              su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
              su -c "settings put global private_dns_mode off && settings put global private_dns_specifier null"
              su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
            else
              su -c "settings put global private_dns_mode off && settings put global private_dns_specifier null"
            fi
          elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
            ~/rish -c "settings put global private_dns_mode off && settings put global private_dns_specifier null"
          fi
          putDns="0"
        fi
        echo && echo -e "$running Extrcting ${Red}$crUNZIP.zip${Reset}"
        pv "$HOME/$crUNZIP.zip" | bsdtar -xf - -C "$HOME" --include "$crUNZIP/apks/ChromePublic.apk" && rm "$HOME/$crUNZIP.zip"
        appVersion=$($HOME/aapt2 dump badging $HOME/$crUNZIP/apks/ChromePublic.apk 2>/dev/null | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
        appVersionCode=$($HOME/aapt2 dump badging $HOME/$crUNZIP/apks/ChromePublic.apk 2>/dev/null | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
        crSize=$(awk "BEGIN {printf \"%.2f MB\n\", $(stat -c%s "$HOME/$crUNZIP/apks/ChromePublic.apk" 2>/dev/null)/1000000}" 2>/dev/null)
        echo && echo -e "$question Do you want to install Chromium_v$appVersion.apk? [Y/n]"
        read -r -p "Select: " opt
              case $opt in
                y*|Y*|"")
                  mkConfig() {
                    if [ ! -f "$crdlJson" ]; then
                      jq -n "{ \"INSTALLED_POSITION\": "$branchPosition" }" > "$crdlJson"  # Create new json file with {data} using jq null flags
                    else
                      jq ".INSTALLED_POSITION = $branchPosition" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Change key value: Reads content of existing json and assigns key new value then redirect new json data to temp.json then rename it to crdl.json
                    fi
                    jq ".INSTALLED_VERSION = \"$crVersion\"" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Add new data to existing json file by reading existing source json using jq
                    jq ".APP_VERSION = \"${appVersion}(${appVersionCode})\"" "$crdlJson" > temp.json && mv temp.json $crdlJson
                    jq ".APP_SIZE = \"$crSize\"" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Add new data: first read data from existing josn file then merge & add new data (key: value) to temp.json then rename it to crdl.json by mv command
                    timeIs=$(date "+%Y-%m-%d %H:%M") && jq ".INSTALLED_TIME = \"$timeIs\"" "$crdlJson" > temp.json && mv temp.json $crdlJson
                    clear && exit 0
                  }
                  crInstall
                  if [ -f "$crdlJson" ] && [ "$installedPosition" == null ] && [ "$AndroidDesktop" == 1 ]; then
                    curl -o "$HOME/top-30.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh > /dev/null 2>&1 && bash "$HOME/top-30.sh" && rm "$HOME/top-30.sh"
                  fi
                  if su -c "id" >/dev/null 2>&1 || "$HOME/rish" -c "id" >/dev/null 2>&1; then
                    if [ $INSTALL_STATUS -eq 0 ]; then
                      mkConfig
                    else
                      echo -e "$bad installation failed!" && sleep 1
                    fi
                  else
                    mkConfig
                  fi
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
          echo -e "$good Found valid snapshot for Chromium version $crVersion at position: $pos" && echo
          if [ "$installedPosition" == "$pos" ] && [ "$installedVersion" == "$crVersion" ]; then
              echo -e "$notice Already installed: $installedVersion"
              sleep 3 && clear && exit 0
          else
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
              appVersion=$($HOME/aapt2 dump badging $HOME/$crUNZIP/apks/ChromePublic.apk 2>/dev/null | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
              appVersionCode=$($HOME/aapt2 dump badging $HOME/$crUNZIP/apks/ChromePublic.apk 2>/dev/null | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
              crSize=$(awk "BEGIN {printf \"%.2f MB\n\", $(stat -c%s "$HOME/$crUNZIP/apks/ChromePublic.apk" 2>/dev/null)/1000000}" 2>/dev/null)
              echo && echo -e "$question Do you want to install Chromium_v$appVersion.apk? [Y/n]"
              read -r -p "Select: " opt
              case $opt in
                  y*|Y*|"")
                    mkConfig() {
                      if [ ! -f "$crdlJson" ]; then
                        jq -n "{ \"INSTALLED_POSITION\": "$pos" }" > "$crdlJson"  # Create new json file with {data} using jq null flags
                      else
                        jq ".INSTALLED_POSITION = $pos" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Change key value: Reads content of existing json and assigns key new value then redirect new json data to temp.json then rename it to crdl.json
                      fi
                      jq ".INSTALLED_VERSION = \"$crVersion\"" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Add new data to existing json file by reading existing source json using jq
                      jq ".APP_VERSION = \"${appVersion}(${appVersionCode})\"" "$crdlJson" > temp.json && mv temp.json $crdlJson
                      jq ".APP_SIZE = \"$crSize\"" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Add new data: first read data from existing josn file then merge & add new data (key: value) to temp.json then rename it to crdl.json by mv command
                      timeIs=$(date "+%Y-%m-%d %H:%M") && jq ".INSTALLED_TIME = \"$timeIs\"" "$crdlJson" > temp.json && mv temp.json $crdlJson
                      sleep 3 && clear && exit 0
                    }
                    crInstall
                    if [ -f "$crdlJson" ] && [ "$installedPosition" == null ] && [ "$AndroidDesktop" == 1 ]; then
                      curl -o "$HOME/top-30.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh > /dev/null 2>&1 && bash "$HOME/top-30.sh" && rm "$HOME/top-30.sh"
                    fi
                    if su -c "id" >/dev/null 2>&1 || "$HOME/rish" -c "id" >/dev/null 2>&1; then
                      if [ $INSTALL_STATUS -eq 0 ]; then
                        mkConfig
                      else
                        echo -e "$bad installation failed!" && sleep 1
                      fi
                    else
                      mkConfig
                    fi
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
            echo -e "${good} Found valid snapshot at: $pos" && echo
            if [ "$installedPosition" == "$pos" ] && [ "$installedVersion" == "$crVersion" ]; then
                echo -e "$notice Already installed: $installedVersion"
                sleep 3 && clear && exit 0
            else
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
                appVersion=$($HOME/aapt2 dump badging $HOME/$crUNZIP/apks/ChromePublic.apk 2>/dev/null | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
                appVersionCode=$($HOME/aapt2 dump badging $HOME/$crUNZIP/apks/ChromePublic.apk 2>/dev/null | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
                crSize=$(awk "BEGIN {printf \"%.2f MB\n\", $(stat -c%s "$HOME/$crUNZIP/apks/ChromePublic.apk" 2>/dev/null)/1000000}" 2>/dev/null)
                echo && echo -e "$question Do you want to install Chromium_v$appVersion.apk? [Y/n]"
                read -r -p "Select: " opt
                case $opt in
                    y*|Y*|"")
                      mkConfig() {
                        if [ ! -f "$crdlJson" ]; then
                          jq -n "{ \"INSTALLED_POSITION\": "$pos" }" > "$crdlJson"  # Create new json file with {data} using jq null flags
                        else
                          jq ".INSTALLED_POSITION = $pos" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Change key value: Reads content of existing json and assigns key new value then redirect new json data to temp.json then rename it to crdl.json
                        fi
                        jq ".INSTALLED_VERSION = \"$crVersion\"" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Add new data to existing json file by reading existing source json using jq
                        jq ".APP_VERSION = \"${appVersion}(${appVersionCode})\"" "$crdlJson" > temp.json && mv temp.json $crdlJson
                        jq ".APP_SIZE = \"$crSize\"" "$crdlJson" > temp.json && mv temp.json $crdlJson  # Add new data: first read data from existing josn file then merge & add new data (key: value) to temp.json then rename it to crdl.json by mv command
                        timeIs=$(date "+%Y-%m-%d %H:%M") && jq ".INSTALLED_TIME = \"$timeIs\"" "$crdlJson" > temp.json && mv temp.json $crdlJson
                        sleep 3 && clear && exit 0
                      }
                      crInstall
                      if [ -f "$crdlJson" ] && [ "$installedPosition" == null ] && [ "$AndroidDesktop" == 1 ]; then
                        curl -o "$HOME/top-30.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh > /dev/null 2>&1 && bash "$HOME/top-30.sh" && rm "$HOME/top-30.sh"
                      fi
                      if su -c "id" >/dev/null 2>&1 || "$HOME/rish" -c "id" >/dev/null 2>&1; then
                        if [ $INSTALL_STATUS -eq 0 ]; then
                          mkConfig
                        else
                          echo -e "$bad installation failed!" && sleep 1
                        fi
                      else
                        mkConfig
                      fi
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
  printf "🕊️ ${Yellow}Please wait few seconds! fetching crVersion..${Reset}"
  branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Android&num=1")
  branchPosition=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")
  
  n="500"  # Initialize n=500
  while true; do
    count=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=500" | pup 'li json{}' | jq -r '.[] | select(.children[].text | test("Updating trunk VERSION from")) | .children[] | select(.class == "CommitLog-time") | .text' \
      | sed 's/^[·[:space:]]*//' | wc -l)
    if [ "$count" -ge 1 ]; then
      break  # break the loop if count > 1
    fi
    n=$((n + 500))  # if ! count > 1; then n=n+500
  done

  # Get the Chromium Canary Test commit time string (e.g., "30 seconds / 30 minutes / 36 hours / 2 days ago")
  time_str=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'li json{}' | jq -r '.[] | select(.children[].text | test("Updating trunk VERSION from")) | .children[] | select(.class == "CommitLog-time") | .text' \
    | head -1 | sed 's/^[·[:space:]]*//')

  # Parse the time string into minutes
  if [[ "$time_str" =~ ([0-9]+)[[:space:]]+second ]]; then
    minutes=$(( ${BASH_REMATCH[1]} / 60 ))
  elif [[ "$time_str" =~ ([0-9]+)[[:space:]]+minute ]]; then
    minutes=${BASH_REMATCH[1]}
  elif [[ "$time_str" =~ ([0-9]+)[[:space:]]+hour ]]; then
    minutes=$(( ${BASH_REMATCH[1]} * 60 ))
  elif [[ "$time_str" =~ ([0-9]+)[[:space:]]+day ]]; then
    minutes=$(( ${BASH_REMATCH[1]} * 24 * 60 ))
  fi

  # Compare time
  if (( minutes > 30 )); then
    commit=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'a:contains("Updating trunk VERSION from") attr{href}' | head -1) && baseCommitUrl="https://chromium.googlesource.com"
    diff=$(curl -sL "$baseCommitUrl$commit" | pup 'span.DiffTree-action--modify a attr{href}' | head -1) && diffGit=$(curl -s "$baseCommitUrl$diff" | pup 'pre.Diff-unified text{}')
    major=$(echo "$diffGit" | grep -E '^\s*MAJOR=' | head -1 | cut -d'=' -f2)
    if [ -z "$major" ]; then
      major=$(echo "$diffGit" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
    fi
    minor=$(echo "$diffGit" | grep -E '^\s*MINOR=' | head -1 | cut -d'=' -f2)
    build=$(echo "$diffGit" | grep -E '^\+BUILD=' | head -1 | cut -d'=' -f2) && patch=$(echo "$diffGit" | grep -E '^\s*PATCH=' | head -1 | cut -d'=' -f2)
    crVersion="${major}.${minor}.${build}.${patch}"
    
<<comment
    firstPageCommitCount=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=1&per_page=100" | jq '[.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+"))] | length')
    secondPageCommitCount=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=2&per_page=100" | jq '[.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+"))] | length')
    thirdPageCommitCount=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=3&per_page=100" | jq '[.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+"))] | length')
    if [ "$firstPageCommitCount" -ge 1 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=1&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -1 2>/dev/null)
    elif [ "$firstPageCommitCount" -eq 0 ] && [ "$secondPageCommitCount" -ge 1 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=2&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -1 2>/dev/null)
    elif [ "$secondPageCommitCount" -eq 0 ] && [ "$thirdPageCommitCount" -ge 1 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=3&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -1 2>/dev/null)
    fi
    diff=$(curl -s "https://api.github.com/repos/chromium/chromium/commits/$commitHash" | jq -r '.files[] | "\n--- \(.filename) ---\n\(.patch // "binary or too large to display")"' 2>/dev/null)
    major=$(echo "$diff" | grep -E '^\s*MAJOR=' | head -1 | cut -d'=' -f2)
    if [ -z "$major" ]; then
      major=$(echo "$diff" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
    fi
    minor=$(echo "$diff" | grep -E '^\s*MINOR=' | head -1 | cut -d'=' -f2)
    build=$(echo "$diff" | grep -E '^\+BUILD=' | head -1 | cut -d'=' -f2) && patch=$(echo "$diff" | grep -E '^\s*PATCH=' | head -1 | cut -d'=' -f2)
    crVersion="${major}.${minor}.${build}.${patch}"
comment
  else
    commit=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'a:contains("Updating trunk VERSION from") attr{href}' | head -n 2 | tail -n 1) && baseCommitUrl="https://chromium.googlesource.com"
    diff=$(curl -sL "$baseCommitUrl$commit" | pup 'span.DiffTree-action--modify a attr{href}' | head -1) && diffGit=$(curl -s "$baseCommitUrl$diff" | pup 'pre.Diff-unified text{}')
    major=$(echo "$diffGit" | grep -E '^\s*MAJOR=' | head -1 | cut -d'=' -f2)
    if [ -z "$major" ]; then
      major=$(echo "$diffGit" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
    fi
    minor=$(echo "$diffGit" | grep -E '^\s*MINOR=' | head -1 | cut -d'=' -f2)
    build=$(echo "$diffGit" | grep -E '^\+BUILD=' | head -1 | cut -d'=' -f2) && patch=$(echo "$diffGit" | grep -E '^\s*PATCH=' | head -1 | cut -d'=' -f2)
    crVersion="${major}.${minor}.${build}.${patch}"

<<comment  
    firstPageCommitCount=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=1&per_page=100" | jq '[.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+"))] | length')
    secondPageCommitCount=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=2&per_page=100" | jq '[.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+"))] | length')
    thirdPageCommitCount=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=3&per_page=100" | jq '[.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+"))] | length')
    if [ "$firstPageCommitCount" -ge 2 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=1&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -n 2 | tail -n 1 2>/dev/null)
    elif [ "$firstPageCommitCount" -eq 0 ] && [ $secondPageCommitCount -ge 2 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=2&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -n 2 | tail -n 1 2>/dev/null)
    elif [ "$firstPageCommitCount" -eq 1 ] && [ $secondPageCommitCount -ge 2 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=2&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -n 2 | tail -n 1 2>/dev/null)
    elif [ "$firstPageCommitCount" -eq 1 ] && [ $secondPageCommitCount -eq 1 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=2&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -1 2>/dev/null)
    elif [ "$firstPageCommitCount" -eq 0 ] && [ $secondPageCommitCount -eq 0 ] && [ $thirdPageCommitCount -ge 2 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=3&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -n 2 | tail -n 1 2>/dev/null)
    elif [ "$firstPageCommitCount" -eq 1 ] && [ $secondPageCommitCount -eq 0 ] && [ $thirdPageCommitCount -ge 2 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=3&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -n 2 | tail -n 1 2>/dev/null)
    elif [ "$firstPageCommitCount" -eq 1 ] && [ $secondPageCommitCount -eq 0 ] && [ $thirdPageCommitCount -eq 1 ]; then
      commitHash=$(curl -s "https://api.github.com/repos/chromium/chromium/commits?sha=main&page=3&per_page=100" | jq -r '.[] | select(.commit.message | test("Updating trunk VERSION from [0-9.]+ to [0-9.]+")) | .sha' | head -1 2>/dev/null)
    fi
    diff=$(curl -s "https://api.github.com/repos/chromium/chromium/commits/$commitHash" | jq -r '.files[] | "\n--- \(.filename) ---\n\(.patch // "binary or too large to display")"' 2>/dev/null)
    major=$(echo "$diff" | grep -E '^\s*MAJOR=' | head -1 | cut -d'=' -f2)
    if [ -z "$major" ]; then
      major=$(echo "$diff" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
    fi
    minor=$(echo "$diff" | grep -E '^\s*MINOR=' | head -1 | cut -d'=' -f2)
    build=$(echo "$diff" | grep -E '^\+BUILD=' | head -1 | cut -d'=' -f2) && patch=$(echo "$diff" | grep -E '^\s*PATCH=' | head -1 | cut -d'=' -f2)
    crVersion="${major}.${minor}.${build}.${patch}"
comment
  fi
  
  if [ "$crVersion" == " . . . " ]; then
    crVersion=$(echo "$branchData" | jq -r '.[0].version' | sed -E -e 's/^([0-9]{2})([0-9])/\1X/' -e 's/([0-9])([0-9]{3})\.[0-9]+/\1XXX.X/')
  fi
  printf "\r\033[K"

  echo -e "$info Last Chromium Canary Test Version: $crVersion at branch position: $branchPosition"
}

# --- Main Menu ---
while true; do
  clear  # clear Terminal
  print_crdl  # Call the print crdl shape function
  if [ -f "$crdlJson" ]; then
    echo -e "$info INSTALLED: Chromium v$appVersion - $appSize - $installedTime" && echo
  fi
  echo -e "S. Stable \nB. Beta \nD. Dev \nC. Canary \nT. Canary Test \nQ. Quit \n"
  read -r -p "Select Chromium Channel: " channel
        case "$channel" in
          [Ss]*)
            channel="Stable"
            echo && sInfo  # Call the Chromium Stable info function
            echo && findValidSnapshot "$branchPosition" $LAST_CHANGE  # Call the find valid snapshot function and pass the value
            ;;
          [Bb]*)
            channel="Beta"
            echo && bInfo
            echo && findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Dd]*)
            channel="Dev"
            echo && dInfo
            echo && findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Cc]*)
            channel="Canary"
            echo && cInfo
            echo && findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Tt]*)
            echo && tInfo
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
