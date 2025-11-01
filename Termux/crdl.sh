#!/usr/bin/bash

# Chromium is an open-source browser project, developed and maintained by Google
# Easy Script to download and run latest Chromium Android build
# Use: ~ curl --progress-bar -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/crdl.sh" && bash "$HOME/.crdl.sh"
# Developer github.com/arghya339

# --- Colored log indicators ---
good="\033[92;1m[✔]\033[0m"
bad="\033[91;1m[✘]\033[0m"
info="\033[94;1m[i]\033[0m"
running="\033[37;1m[~]\033[0m"
notice="\033[93;1m[!]\033[0m"
question="\033[93;1m[?]\033[0m"

# ANSI color code
Green="\033[92m"
Red="\033[91m"
Blue="\033[94m"
skyBlue="\033[38;5;117m"
Cyan="\033[96m"
White="\033[37m"
whiteBG="\e[47m\e[30m"
Yellow="\033[93m"
Reset="\033[0m"

# --- Checking Internet Connection ---
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 ; then
  echo -e "${bad} ${Red} Oops! No Internet Connection available.\nConnect to the Internet and try again later."
  exit 1
fi

# --- Downloading latest crdl.sh file from GitHub ---
curl -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/crdl.sh" > /dev/null 2>&1

[ ! -f "$PREFIX/bin/crdl" ] && ln -s $HOME/.crdl.sh $PREFIX/bin/crdl  # symlink (shortcut of crdl.sh)
[ ! -x "$HOME/.crdl.sh" ] && chmod +x $HOME/.crdl.sh  # give execute permission to crdl

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
  #printf '\n'
  echo
}

# --- Global variables ---
Android=$(getprop ro.build.version.release | cut -d. -f1)  # Get major Android version
Model=$(getprop ro.product.model)  # Get device model
arch=$(getprop ro.product.cpu.abi)  # Get Android architecture
arch32=$(getprop ro.product.cup.abilist32)  # Get Android 32 bit arch
socOEM=$(getprop ro.soc.manufacturer)  # Get SOC Manufacturer
networkName1=$(getprop gsm.operator.alpha | cut -d',' -f1)  # Get SIM1 Carrier name
networkName2=$(getprop gsm.operator.alpha | cut -d',' -f2)  # Get SIM2 Carrier name
simOperator1=$(getprop gsm.sim.operator.alpha | cut -d',' -f1)  # Get SIM1 Operator name
simOperator2=$(getprop gsm.sim.operator.alpha | cut -d',' -f2)  # Get SIM2 Operator name
simCountry=$(getprop gsm.sim.operator.iso-country | cut -d',' -f1)  # Get SIM1 Country
cloudflareDOH="-L --doh-url https://cloudflare-dns.com/dns-query"
memTotalKB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
crdlJson="$HOME/.crdl.json"  # json file to store crdl related data
installedPosition=$(jq -r '.INSTALLED_POSITION' "$crdlJson" 2>/dev/null)
installedVersion=$(jq -r '.INSTALLED_VERSION' "$crdlJson" 2>/dev/null)
[ "$arch" == "x86_64" ] && AndroidDesktop=1 || AndroidDesktop=0
AndroidDesktop=$(jq -r '.AndroidDesktop' "$crdlJson" 2>/dev/null)
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"
appSize=$(jq -r '.APP_SIZE' "$crdlJson" 2>/dev/null)
appVersion=$(jq -r '.APP_VERSION' "$crdlJson" 2>/dev/null)
installedTime=$(jq -r '.INSTALLED_TIME' "$crdlJson" 2>/dev/null)
chromiumActivityClass="org.chromium.chrome/com.google.android.apps.chrome.Main"
Download="/sdcard/Download"  # Download dir

su -c "id" >/dev/null 2>&1 && su=1 || su=0

clear && echo -e "🚀 ${Yellow}Please wait! starting crdl...${Reset}"

pkg update > /dev/null 2>&1  # It downloads latest package list with versions from Termux remote repository, then compares them to local (installed) pkg versions, and shows a list of what can be upgraded if they are different.
outdatedPKG=$(apt list --upgradable 2>/dev/null)
echo "$outdatedPKG" | grep -q "dpkg was interrupted" 2>/dev/null && { yes "N" | dpkg --configure -a; outdatedPKG=$(apt list --upgradable 2>/dev/null); }
installedPKG=$(pkg list-installed 2>/dev/null)  # list of installed pkg

if [ $su -eq 1 ] || "$HOME/rish" -c "id" >/dev/null 2>&1 || "$HOME/adb" -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell "id" >/dev/null 2>&1; then
  putDns=0
fi
getPvDnsStatus() {
    if [ $su -eq 1 ]; then
      if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
        su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
        pvDnsMode=$(su -c "settings get global private_dns_mode" 2>/dev/null)  # default: null/off
        pvDnsSpec=$(su -c "settings get global private_dns_specifier" 2>/dev/null)  # default: null
        su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
      else
        pvDnsMode=$(su -c "settings get global private_dns_mode" 2>/dev/null)  # default: null/off
        pvDnsSpec=$(su -c "settings get global private_dns_specifier" 2>/dev/null)  # default: null
      fi
    elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
      pvDnsMode=$('$HOME/rish' -c "settings get global private_dns_mode" 2>/dev/null)  # default: null/off
      pvDnsSpec=$(~/rish -c "settings get global private_dns_specifier" 2>/dev/null)  # default: null
    elif "$HOME/adb" -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell "id" >/dev/null 2>&1; then
      pvDnsMode=$(~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | cut -f1) shell "settings get global private_dns_mode" 2>/dev/null)  # default: null/off
      pvDnsSpec=$(~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | cut -f1) shell "settings get global private_dns_specifier" 2>/dev/null)  # default: null
    fi
}

# Check if TermuxAPI available
if termux-api-start > /dev/null 2>&1; then
  foundTermuxAPI=1
  grep -q "^# hide-soft-keyboard-on-startup = true" "$HOME/.termux/termux.properties" && sed -i '/hide-soft-keyboard-on-startup = true/s/# //' "$HOME/.termux/termux.properties"
  grep -q "^# soft-keyboard-toggle-behaviour = enable/disable" "$HOME/.termux/termux.properties" && sed -i '/soft-keyboard-toggle-behaviour = enable\/disable/s/# //' "$HOME/.termux/termux.properties"
else
  foundTermuxAPI=0
fi

# --- Storage Permission Check Logic ---
if ! ls /sdcard/ 2>/dev/null | grep -E -q "^(Android|Download)"; then
  echo -e "${notice} ${Yellow}Storage permission not granted!${Reset}\n$running ${Green}termux-setup-storage${Reset}.."
  if [ "$Android" -gt 5 ]; then  # for Android 5 storage permissions grant during app installation time, so Termux API termux-setup-storage command not required
    count=0
    while true; do
      if [ "$count" -ge 2 ]; then
        echo -e "$bad Failed to get storage permissions after $count attempts!"
        echo -e "$notice Please grant permissions manually in Termux App info > Permissions > Files > File permission → Allow."
        am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.termux &> /dev/null
        exit 0
      fi
      termux-setup-storage  # ask Termux Storage permissions
      sleep 3  # wait 3 seconds
      if ls /sdcard/ 2>/dev/null | grep -q "^Android" || ls "$HOME/storage/shared/" 2>/dev/null | grep -q "^Android"; then
        if [ "$Android" -lt 8 ]; then
          exit 0  # Exit the script
        fi
        break
      fi
      ((count++))
    done
  fi
fi

# --- enabled allow-external-apps ---
isOverwriteTermuxProp=0
if [ "$Android" -ge 6 ]; then
  if grep -q "^# allow-external-apps" "$HOME/.termux/termux.properties"; then
    # other Android applications can send commands into Termux.
    # termux-open utility can send an Android Intent from Termux to Android system to open apk package file in pm.
    # other Android applications also can be Access Termux app data (files).
    sed -i '/allow-external-apps/s/# //' "$HOME/.termux/termux.properties"  # uncomment 'allow-external-apps = true' line
    isOverwriteTermuxProp=1
    echo -e "$notice 'allow-external-apps = true' line has been uncommented (enabled) in Termux \$HOME/.termux/termux.properties."
    #if [ "$Android" -eq 7 ] || [ "$Android" -eq 6 ]; then
      termux-reload-settings  # reload (restart) Termux settings required for Android 6 after enabled allow-external-apps, also required for Android 7 due to 'Package installer has stopped' err
    #fi
  fi
fi

# --- Checking Android Version ---
# Latest Chromium required Android 10+
if [ $Android -le 9 ]; then
  echo -e "${bad} ${Red}Android $Android is not supported by Chromium.${Reset}"
  if [ $Android -ge 7 ]; then
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
  if [ $Android -ge 10 ]; then
    echo -e "$info Find Chromium alternative as BraveMonox86.apk"  # Android 9.0+ (universal: arm64-v8a, armeabi-v7a, x86_64, x86)
    termux-open "https://github.com/brave/brave-browser/releases/latest/"
  elif [ $Android -ge 7 ]; then
    echo -e "$info Find Chromium alternative as KiwiBrowser."  # Android 7.0+ (universal)
    termux-open-url "https://github.com/kiwibrowser/src.next/releases/latest/"
  else
    echo -e "$info Find Chromium alternative as Firefox."  # Android 5.0+ (universal)
    termux-open "https://play.google.com/store/apps/details?id=org.mozilla.firefox"
  fi
  rm -f $PREFIX/bin/crdl && rm -f $HOME/.crdl.sh
  exit 1
fi

# --- pkg upgrade function ---
pkgUpdate() {
  local pkg=$1
  if echo "$outdatedPKG" | grep -q "^$pkg/" 2>/dev/null; then
    echo -e "$running Upgrading $pkg pkg.."
    output=$(pkg install --only-upgrade "$pkg" -y 2>/dev/null)
    echo "$output" | grep -q "dpkg was interrupted" 2>/dev/null && { yes "N" | dpkg --configure -a; yes "N" | pkg install --only-upgrade "$pkg" -y > /dev/null 2>&1; }
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

pkgInstall "dpkg"  # dpkg update
pkgInstall "libgnutls"  # pm apt & dpkg use it to securely download packages from repositories over HTTPS
pkgInstall "termux-core"  # it's contains basic essential cli utilities, such as: ls, cp, mv, rm, mkdir, cat, echo, etc.
pkgInstall "termux-tools"  # it's provide essential commands, sush as: termux-change-repo, termux-setup-storage, termux-open, termux-share, etc.
pkgInstall "termux-keyring"  # it's use during pkg install/update to verify digital signature of the pkg and remote repository
pkgInstall "termux-am"  # termux am (activity manager) update
pkgInstall "termux-am-socket"  # termux am socket (when run: am start -n activity ,termux-am take & send to termux-am-stcket and it's send to Termux Core to execute am command) update
pkgInstall "inetutils"  # ping utils is provided by inetutils
pkgInstall "util-linux"  # it provides: kill, killall, uptime, uname, chsh, lscpu
pkgInstall "libsmartcols"  # a library from the util-linux pkg
pkgInstall "grep"  # grep update
pkgInstall "gawk"  # gnu awk update
pkgInstall "sed"  # sed update
pkgInstall "curl"  # curl update
pkgInstall "libcurl"  # curl lib update
pkgInstall "aria2"  # aria2 install/update
pkgInstall "jq"  # jq install/update
pkgInstall "pup"  # pup install/update
pkgInstall "bsdtar"  # bsdtar install/update
pkgInstall "pv"  # pv install/update
pkgInstall "bc"  # bc install/update

# --- Download and give execute (--x) permission to AAPT2 Binary ---
[ ! -f "$HOME/aapt2" ] && curl -sL "https://github.com/arghya339/aapt2/releases/download/all/aapt2_$arch" -o "$HOME/aapt2"
[ ! -x "$HOME/aapt2" ] && chmod +x "$HOME/aapt2"

config() {
  local key="$1"
  local value="$2"
  
  if [ ! -f "$crdlJson" ]; then
    jq -n "{}" > "$crdlJson"
  fi
  
  jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$crdlJson" > temp.json && mv temp.json "$crdlJson"
}

# Y/n prompt function
confirmPrompt() {
  Prompt=${1}
  local -n prompt_buttons=$2
  Selected=${3:-0}  # :- set value as 0 if unset
  maxLen=50
  
  # breaks long prompts into multiple lines (50 characters per line)
  lines=()  # empty array
  while [ -n "$Prompt" ]; do
    lines+=("${Prompt:0:$maxLen}")  # take first 50 characters from $Prompt starting at index 0
    Prompt="${Prompt:$maxLen}"  # removes first 50 characters from $Prompt by starting at 50 to 0
  done
  
  # print all-lines except last-line
  last_line_index=$(( ${#lines[@]} - 1 ))  # ${#lines[@]} = number of elements in lines array
  for (( i=0; i<last_line_index; i++ )); do
    echo -e "${lines[i]}"
  done
  last_line="${lines[$last_line_index]}"
  
  echo -ne '\033[?25l'  # Hide cursor
  while true; do
    show_prompt() {
      echo -ne "\r\033[K"  # n=noNewLine r=returnCursorToStartOfLine \033[K=clearLine
      echo -ne "$last_line "
      [ $Selected -eq 0 ] && echo -ne "${whiteBG}➤ ${prompt_buttons[0]} $Reset   ${prompt_buttons[1]}" || echo -ne "  ${prompt_buttons[0]}  ${whiteBG}➤ ${prompt_buttons[1]} $Reset"  # highlight selected bt with white bg
    }; show_prompt

    read -rsn1 key
    case $key in
      $'\E')
      # /bin/bash -c 'read -r -p "Type any ESC key: " input && printf "You Entered: %q\n" "$input"'  # q=safelyQuoted
        read -rsn2 -t 0.1 key2  # -r=readRawInput -s=silent(noOutput) -t=timeout -n2=readTwoChar | waits upto 0.1s=100ms to read key 
        case $key2 in 
          '[C') Selected=1 ;;  # right arrow key
          '[D') Selected=0 ;;  # left arrow key
        esac
        ;;
      [Yy]*) Selected=0; show_prompt; break ;;
      [Nn]*) Selected=1; show_prompt; break ;;
      "") break ;;  # Enter key
    esac
  done
  echo -e '\033[?25h' # Show cursor
  return $Selected  # return Selected int index from this fun
}

if [ $arch == "arm64-v8a" ] && [ ! -f "$crdlJson" ]; then
  if [ $foundTermuxAPI -eq 1 ]; then
    crx=$(termux-dialog confirm -t "Install Chrome Extensions" -i "Do you want to install Extensions supported AndroidDesktop Chromium.apk?" | jq -r '.text')
  else
    buttons=("<Yes>" "<No>"); confirmPrompt "Do you want to install Extensions supported AndroidDesktop Chromium.apk?" "buttons" && crx=Yes || crx=No
  fi
  case $crx in
    y*|Y*|"")
      config "AndroidDesktop" "1"
      AndroidDesktop=$(jq -r '.AndroidDesktop' "$crdlJson" 2>/dev/null)
      echo -e "$info crdl Extensions config are store in a '$crdlJson' file. \nif you don't need AndroidDesktopChromium, please remove this file by running following command in Termux ${Cyan}~${Reset} ${Green}jq${Reset} ${Yellow}'del(.AndroidDesktop)' \"${Reset}${Cyan}\$HOME${Reset}${Yellow}/.crdl.json\" >${Reset} temp.json && ${Green}mv${Reset} temp.json \$HOME/.crdl.json" && sleep 10
      ;;
    n*|N*) echo -e "$notice AndroidDesktopChromium skipped." ;;
  esac
fi

# --- Variables ---
memTotalGB=$(echo "scale=2; $memTotalKB / 1048576" | bc -l 2>/dev/null || echo "0")  # scale=2 ensures the result is rounded to 2 decimal places for readability, 1048576 (which is 1024 * 1024, since 1 GB = 1024 MB and 1 MB = 1024 kB), bc is a basicCalculator
# --- Detect arch (ARM or ARM64 or x86_64) ---
if [ $arch == "arm64-v8a" ]; then
  # Prefer 32-bit apk if device is usually low on memory (RAM).
  if [ $AndroidDesktop -eq 1 ]; then
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
if [ $su -eq 0 ] && { [ ! -f "$HOME/rish" ] || [ ! -f "$HOME/rish_shizuku.dex" ]; }; then
  #echo -e "$info Please manually install Shizuku from Google Play Store." && sleep 1
  #termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  echo -e "$info Please manually install Shizuku from GitHub." && sleep 1
  termux-open-url "https://github.com/RikkaApps/Shizuku/releases/latest"
  am start -n com.android.settings/.Settings\$MyDeviceInfoActivity > /dev/null 2>&1  # Open Device Info

  curl -sL -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish"
  [ ! -x "$HOME/rish" ] && chmod +x "$HOME/rish"
  sleep 0.5 && curl -sL -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish_shizuku.dex"
  
  if [ "$Android" -lt 11 ]; then
    url="https://youtu.be/ZxjelegpTLA"  # YouTube/@MrPalash360: Start Shizuku using Computer
    activityClass="com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity"  # Open Developer options
  else
    activityClass="com.android.settings/.Settings\$WirelessDebuggingActivity"  # Open Wireless Debugging Settings
    url="https://youtu.be/YRd0FBfdntQ"  # YouTube/@MrPalash360: Start Shizuku Android 11+
  fi
  echo -e "$info Please start Shizuku by following guide: $url" && sleep 1
  am start -n "$activityClass" > /dev/null 2>&1
  termux-open-url "$url"
fi
if ! "$HOME/rish" -c "id" >/dev/null 2>&1 && [ -f "$HOME/rish_shizuku.dex" ]; then
  if ~/rish -c "id" 2>&1 | grep -q 'java.lang.UnsatisfiedLinkError'; then
    rm -f "$HOME/rish_shizuku.dex" && curl -sL -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/Play/rish_shizuku.dex"
  fi
fi

if [ "$(getprop ro.product.manufacturer)" == "Genymobile" ] && [ ! -f "$HOME/adb" ]; then
  curl -sL -o "$HOME/adb" "https://raw.githubusercontent.com/rendiix/termux-adb-fastboot/refs/heads/master/binary/${arch}/bin/adb"
  [ ! -x "$HOME/adb" ] && chmod +x ~/adb
fi

# --- apk installation function ---
apkInstall() {
  local apkPath=$1
  local activityClass=$2
  local fileName=$(basename "$apkPath" 2>/dev/null)
  
  if [ $su -eq 1 ]; then
    su -c "cp '$apkPath' '/data/local/tmp/$fileName'"
    # Temporary Disable SELinux Enforcing during installation if it not in Permissive
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
      INSTALL_STATUS=$?
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
    else
      su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
      INSTALL_STATUS=$?
    fi
    su -c "rm -f '/data/local/tmp/$fileName'"
    [ "$activityClass" == "$chromiumActivityClass" ] && am start -n $activityClass > /dev/null 2>&1  # launch app after install/update
    [ $INSTALL_STATUS -eq 0 ] && rm -f "$apkPath"
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c "cp '$apkPath' '/data/local/tmp/$fileName'"
    ~/rish -c "pm install -r -i com.android.vending '/data/local/tmp/$fileName'" > /dev/null 2>&1  # -r=reinstall
    INSTALL_STATUS=$?
    $HOME/rish -c "rm -f '/data/local/tmp/$fileName'"
    [ "$activityClass" == "$chromiumActivityClass" ] && am start -n $activityClass > /dev/null 2>&1  # launch app after install/update
    [ $INSTALL_STATUS -eq 0 ] && rm -f "$apkPath"
  elif "$HOME/adb" -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell "id" >/dev/null 2>&1; then
    ~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | cut -f1) shell cp $apkPath /data/local/tmp/$fileName
    ~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | cut -f1) shell pm install -r -i com.android.vending "/data/local/tmp/$fileName" > /dev/null 2>&1
    #~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell cmd package install -r -i com.android.vending "/data/local/tmp/$fileName" > /dev/null 2>&1
    INSTALL_STATUS=$?
    ~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | cut -f1) shell "rm -f '/data/local/tmp/$fileName'"
    [ "$activityClass" == "$chromiumActivityClass" ] && am start -n $activityClass > /dev/null 2>&1  # launch app after install/update
    [ $INSTALL_STATUS -eq 0 ] && rm -f "$apkPath"
  elif [ $Android -le 6 ]; then
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file://${apkPath}"
    sleep 15
    am start -n $activityClass > /dev/null 2>&1 && rm -f "$apkPath"
  else
    termux-open --view "$apkPath"  # open file in pm
    sleep 15
    am start -n $activityClass > /dev/null 2>&1 && rm -f "$apkPath"
  fi
}

# --- Create crdl shortcut on Laucher Home ---
if [ ! -f "$HOME/.shortcuts/crdl" ] || [ ! -f "$HOME/.termux/widget/dynamic_shortcuts/crdl" ]; then
  echo -e "$notice Please wait few seconds! Creating crdl shortcut to access crdl from Launcher Widget."
  mkdir -p ~/.shortcuts  # create $HOME/.shortcuts dir if it not exist
  echo -e "#!/usr/bin/bash\nbash \$PREFIX/bin/crdl" > ~/.shortcuts/crdl  # create crdl shortcut script
  mkdir -p ~/.termux/widget/dynamic_shortcuts
  echo -e "#!/usr/bin/bash\nbash \$PREFIX/bin/crdl" > ~/.termux/widget/dynamic_shortcuts/crdl  # create crdl dynamic shortcut script
  chmod +x ~/.termux/widget/dynamic_shortcuts/crdl  # give execute (--x) permissions to crdl script
  if ! am start -n com.termux.widget/com.termux.widget.TermuxLaunchShortcutActivity > /dev/null 2>&1; then
    # Download Termux:Widget app from GitHub
    tag=$(curl -s https://api.github.com/repos/termux/termux-widget/releases/latest | jq -r '.tag_name | sub("^v"; "")')
    assetsName="termux-widget-app_v$tag+github.debug.apk"
    dlUrl="https://github.com/termux/termux-widget/releases/download/v$tag/$assetsName"
    apk_path="$Download/$assetsName"
    while true; do
      curl -L --progress-bar -C - -o "$apk_path" "$dlUrl"
      [ $? -eq 0 ] && break || { echo -e "$notice Download failed! Retrying in 5 seconds.."; sleep 5; }
    done
    apkInstall "$apk_path" "com.termux.widget/com.termux.widget.TermuxLaunchShortcutActivity"  # Install Termux:Widget app using apkInstall function
  fi
  if [ $su -eq 1 ]; then
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
      su -c "cmd deviceidle whitelist +com.termux"
      su -c "cmd appops set com.termux SYSTEM_ALERT_WINDOW allow"
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
    else
      su -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
      su -c "cmd deviceidle whitelist +com.termux"
      su -c "cmd appops set com.termux SYSTEM_ALERT_WINDOW allow"
    fi
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
    ~/rish -c "cmd deviceidle whitelist +com.termux"
    $HOME/rish -c "cmd appops set com.termux REQUEST_INSTALL_PACKAGES allow"
    $HOME/rish -c "cmd appops set com.termux.widget REQUEST_INSTALL_PACKAGES allow"
    $HOME/rish -c "cmd appops set com.termux SYSTEM_ALERT_WINDOW allow"
  else
    echo -e "$info Please manually turn on: ${Green}Display over other apps → Termux → Allow display over other apps${Reset}" && sleep 6
    am start -a android.settings.action.MANAGE_OVERLAY_PERMISSION &> /dev/null  # open manage overlay permission settings
  fi
  echo -e "$info Please Disabled: ${Green}Battery optimization → Not optimized → All apps → Termux → Don't optiomize → DONE${Reset}" && sleep 6
  am start -n com.android.settings/.Settings\$HighPowerApplicationsActivity &> /dev/null
  echo -e "$info From Termux:Widget app tap on ${Green}crdl → Add to home screen${Reset}. Opening Termux:Widget app in 6 seconds.." && sleep 6
  am start -n com.termux.widget/com.termux.widget.TermuxCreateShortcutActivity > /dev/null 2>&1  # open Termux:Widget app shortcut create activity (screen/view) to add shortcut on Launcher Home
fi

if [ $snapshotPlatform == "AndroidDesktop_arm64" ] || [ $snapshotPlatform == "AndroidDesktop_x64" ]; then
  crUNZIP="chrome-android-desktop"
else
  crUNZIP="chrome-android"
fi

# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  clear  # clear aria2 multi error log from console
  print_crdl  # call the print_crdl function 
  if [ -f "$crdlJson" ]; then
    echo -e "$info INSTALLED: Chromium v$appVersion - $appSize - $installedTime" && echo
  fi
  echo "Navigate with [↑] [↓] [←] [→]"
  echo -e "Select with [↵]\n"
  for ((i=0; i<=$((${#options[@]} - 1)); i++)); do
    if [ $i -eq $selected ]; then
      echo -e "${whiteBG}➤ ${options[$i]} $Reset"
    else
      [ $(($i + 1)) -le 9 ] && echo " $(($i + 1)). ${options[$i]}" || echo "$(($i + 1)). ${options[$i]}"
    fi
  done
  echo
  echo -e "${whiteBG}➤ ${buttons[0]} $Reset   ${buttons[1]}"
  echo && echo -e "$info Last Chromium Canary Test Version: $crVersion at branch position: $branchPosition"
  echo -e "${good} Found valid snapshot at: $branchPosition" && echo
  echo -e "$running Direct Downloading Chromium $crVersion from ${Blue}$downloadUrl${Reset} $crdlSize"
}

installPrompt() {
  local apkPath=$1

  appVersion=$($HOME/aapt2 dump badging $apkPath 2>/dev/null | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
  appVersionCode=$($HOME/aapt2 dump badging $apkPath 2>/dev/null | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
  crSize=$(awk "BEGIN {printf \"%.2f MB\n\", $(stat -c%s $apkPath 2>/dev/null)/1000000}" 2>/dev/null)

  if [ $foundTermuxAPI -eq 1 ]; then
    opt=$(termux-dialog confirm -t "Install Chromium" -i "Do you want to install Chromium_v$appVersion.apk?" | jq -r '.text')
  else
    buttons=("<Yes>" "<No>"); echo; confirmPrompt "Do you want to install Chromium_v$appVersion.apk?" "buttons" && opt=Yes || opt=No
  fi

  case $opt in
    y*|Y*|"")
      mkConfig() {
        config "INSTALLED_POSITION" "$branchPosition"
        config "INSTALLED_VERSION" "$crVersion"
        config "APP_VERSION" "${appVersion}(${appVersionCode})"
        config "APP_SIZE" "$crSize"
        config "INSTALLED_TIME" "$(date "+%Y-%m-%d %H:%M")"
        rm -rf "$Download/$crUNZIP/"  # Remove extracting dir
        if [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties";fi
        clear; exit 0
      }
      apkInstall "$apkPath" "$chromiumActivityClass"  # Call apkInstall function
      if [ -f "$crdlJson" ] && ! jq -e 'has("INSTALLED_POSITION")' "$crdlJson" >/dev/null 2>&1 && [ $AndroidDesktop -eq 1 ]; then
        curl -L --progress-bar -o "$HOME/top-30.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh && bash "$HOME/top-30.sh" && rm "$HOME/top-30.sh"
      fi
      if [ $su -eq 1 ] || "$HOME/rish" -c "id" >/dev/null 2>&1; then
        [ $INSTALL_STATUS -eq 0 ] && mkConfig || { echo -e "$bad installation failed!"; sleep 1; }
      else
        mkConfig
      fi
      ;;
    n*|N*) echo -e "$notice Chromium installation skipped."; rm -rf "$Download/$crUNZIP/"; sleep 1 ;;
  esac
}

extract() {
  local archivePath=$1
  if [ $su -eq 1 ] || "$HOME/rish" -c "id" >/dev/null 2>&1 || "$HOME/adb" -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell "id" >/dev/null 2>&1; then
    getPvDnsStatus
    if [ $putDns -eq 1 ] && [ "$pvDnsMode" == "hostname" ] && [ "$pvDnsSpec" == "one.one.one.one" ]; then
      if [ $su -eq 1 ]; then
        if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
          su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
          su -c "settings put global private_dns_mode off && settings put global private_dns_specifier null"
          su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
        else
          su -c "settings put global private_dns_mode off && settings put global private_dns_specifier null"
        fi
      elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
        ~/rish -c "settings put global private_dns_mode off && settings put global private_dns_specifier null"
      elif "$HOME/adb" -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell "id" >/dev/null 2>&1; then
        ~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | cut -f1) shell "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
      fi
      putDns=0
    fi
  fi
  echo && echo -e "$running Extrcting ${Red}$crUNZIP.zip${Reset}"
  termux-wake-lock
  pv "$archivePath" | bsdtar -xf - -C "$Download" --include "$crUNZIP/apks/ChromePublic.apk" && rm -f "$archivePath"
  termux-wake-unlock
  apk_path="$Download/$crUNZIP/apks/ChromePublic.apk"
  installPrompt "$apk_path"  # Call install prompt function
}

dl() {
  local dlUrl=$1

  crdlSize=$(curl -sIL $dlUrl 2>/dev/null | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }' 2>/dev/null)
  echo -e "$running Direct Downloading Chromium $crVersion from ${Blue}$dlUrl${Reset} $crdlSize"
  archive_path="$Download/$crUNZIP.zip"
  resolve_err=0; signal_err=0
  while true; do
    if [ "$channel" == "Stable" ] || [ "$channel" == "Beta" ] || [ "$channel" == "Dev" ]; then
      curl -L --progress-bar -C - -o "$archive_path" "$dlUrl"
      DOWNLOAD_STATUS=$?
    else
      aria2c -x 16 -s 16 --continue=true --console-log-level=error --summary-interval=0 --download-result=hide -o "$crUNZIP.zip" -d "$Download" "$dlUrl"
      DOWNLOAD_STATUS=$?
      echo  # White space
    fi
    if [ $DOWNLOAD_STATUS -eq 0 ]; then
      extract "$archive_path"  # Call extract function
      break  # break the resuming download loop
    elif [ $DOWNLOAD_STATUS -eq 6 ] || [ $DOWNLOAD_STATUS -eq 19 ]; then
      if [ "$channel" != "Stable" ] || [ "$channel" != "Beta" ] || [ "$channel" != "Dev" ]; then
        aria2ConsoleLogHide  # for aria2
      fi
      echo -e "$bad ISP: $simOperator1 / $simOperator2 failed to resolve ${Blue}https://commondatastorage.googleapis.com/${Reset} host!"
      if [ $resolve_err -eq 0 ]; then
        echo -e "$info Connect Cloudflare 1.1.1.1 + WARP, 1.1.1.1 one of the fastest DNS resolvers on Earth."
        if [ $su -eq 1 ] || "$HOME/rish" -c "id" >/dev/null 2>&1 || "$HOME/adb" -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell "id" >/dev/null 2>&1; then
          getPvDnsStatus
          if [ $putDns -eq 0 ] && { [ "$pvDnsMode" == "null" ] || [ "$pvDnsMode" == "off" ]; } && [ "$pvDnsSpec" == "null" ]; then
            if [ $su -eq 1 ]; then
              if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
                su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
                su -c "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
                su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
              else
                su -c "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
              fi
            elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
              ~/rish -c "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
            elif "$HOME/adb" -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | awk '{print $1}') shell "id" >/dev/null 2>&1; then
              ~/adb -s $(~/adb devices 2>/dev/null | head -2 | tail -1 | cut -f1) shell "settings put global private_dns_mode hostname && settings put global private_dns_specifier one.one.one.one"
            fi
            putDns=1
          fi
        else
          am start -n com.cloudflare.onedotonedotonedotone/com.cloudflare.app.presentation.main.SplashActivity > /dev/null 2>&1
          if [ $? != 0 ]; then
            [ $simCountry != "in" ] && termux-open-url "https://play.google.com/store/apps/details?id=com.cloudflare.onedotonedotonedotone" || { termux-open "https://www.apkmirror.com/apk/cloudflare/1-1-1-1-faster-safer-internet/"; sleep 0.5; termux-open "https://github.com/Aefyr/SAI/releases/latest/"; }
          fi
        fi
      fi
      ((resolve_err++))
    elif [ $DOWNLOAD_STATUS -eq 56 ] || [ $DOWNLOAD_STATUS -eq 1 ]; then
      if [ "$channel" != "Stable" ] || [ "$channel" != "Beta" ] || [ "$channel" != "Dev" ]; then
        aria2ConsoleLogHide  # for aria2
      fi
      echo -e "$bad $networkName1 / $networkName2 signal are unstable!"
      apMode=$(getprop persist.radio.airplane_mode_on)  # Get AirPlane Mode Status (0=OFF; 1=ON)
      [ $apMode -eq 1 ] && echo -e "$notice Please turn off Airplane mode!"
      if [ $signal_err -eq 0 ]; then
        am start -a android.settings.WIRELESS_SETTINGS > /dev/null 2>&1
        networkType1=$(getprop gsm.network.type | cut -d',' -f1)  # Get SIM1 Network type (NR_SA/NR_NSA,LTE)
        networkType2=$(getprop gsm.network.type | cut -d',' -f2)  # Get SIM2 Network type (NR_SA/NR_NSA,LTE)
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
          if [ $socOEM == "Mediatek" ] && [ $su -eq 1 ]; then
            echo -e "$info Please select Network Type: LTE/NR"
            su -c "am start --user 0 -n com.mediatek.engineermode/.EngineerMode > /dev/null"
          fi
          if [ $socOEM != "Mediatek" ]; then
            echo -e "$info Please select Network Type: LTE/NR"
            am start -n com.android.phone/.settings.RadioInfo > /dev/null 2>&1  # Open Redio Info
          fi
        fi
      fi
      ((signal_err++))
    fi
    echo -e "$notice Download failed! retrying in 5 seconds.." && sleep 5  # wait 5 seconds
  done
}

# --- Direct Download Function ---
directDl() {
  downloadUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots/$snapshotPlatform/$branchPosition/$crUNZIP.zip"
  if curl --head --silent --fail "$downloadUrl" >/dev/null 2>&1; then
    echo -e "${good} Found valid snapshot at: $branchPosition" && echo
    if [ "$installedPosition" == "$branchPosition" ]; then
      echo -e "$notice Already installed: $installedPosition"
      if [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties";fi
      sleep 3; clear; exit 0
    else
      dl "$downloadUrl"  # Call dl function
    fi
  else
    echo -e "${bad} No direct download URL found!"; sleep 1
  fi
}

# --- Find valid snapshot by searching downward from branch position ---
findValidSnapshot() {
  local position=$1
  local maxPosition=$2
  local range=500

  echo -e "${running} Searching downward from $position (max attempts: $range)"

  # Search downward starting from branchPosition
  for ((pos = position; pos >= position - range; pos--)); do
    [ "$pos" -lt 0 ] && break  # Stop if we go below 0
    checkUrl="$branchUrl/$snapshotPlatform/$pos/$crUNZIP.zip"
    if curl --head --silent --fail "$checkUrl" >/dev/null 2>&1; then
      echo -e "${good} Found valid snapshot at: $pos" && echo
      if [ "$installedPosition" == "$pos" ] && [ "$installedVersion" == "$crVersion" ]; then
        echo -e "$notice Already installed: $installedVersion"
        if [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties";fi
        sleep 3; clear; exit 0
      else
        branchPosition="$pos"
        dl "$checkUrl"  # Call dl function
        sleep 3; break  # Break the searching loop
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
    count=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=500" | pup 'li json{}' | jq -r '.[] | select(.children[].text | test("Updating trunk VERSION from")) | .children[] | select(.class == "CommitLog-time") | .text' | sed 's/^[·[:space:]]*//' | wc -l)
    [ $count -ge 1 ] && break  # break the loop if count > 1
    n=$((n + 500))  # if ! count > 1; then n=n+500
  done

  # Get the Chromium Canary Test commit time string (e.g., "30 seconds / 30 minutes / 36 hours / 2 days ago")
  time_str=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'li json{}' | jq -r '.[] | select(.children[].text | test("Updating trunk VERSION from")) | .children[] | select(.class == "CommitLog-time") | .text' | head -1 | sed 's/^[·[:space:]]*//')

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
    [ -z "$major" ] && major=$(echo "$diffGit" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
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
    [ -z "$major" ] && major=$(echo "$diff" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
    minor=$(echo "$diff" | grep -E '^\s*MINOR=' | head -1 | cut -d'=' -f2)
    build=$(echo "$diff" | grep -E '^\+BUILD=' | head -1 | cut -d'=' -f2) && patch=$(echo "$diff" | grep -E '^\s*PATCH=' | head -1 | cut -d'=' -f2)
    crVersion="${major}.${minor}.${build}.${patch}"
comment
  else
    commit=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'a:contains("Updating trunk VERSION from") attr{href}' | head -n 2 | tail -n 1) && baseCommitUrl="https://chromium.googlesource.com"
    diff=$(curl -sL "$baseCommitUrl$commit" | pup 'span.DiffTree-action--modify a attr{href}' | head -1) && diffGit=$(curl -s "$baseCommitUrl$diff" | pup 'pre.Diff-unified text{}')
    major=$(echo "$diffGit" | grep -E '^\s*MAJOR=' | head -1 | cut -d'=' -f2)
    [ -z "$major" ] && major=$(echo "$diffGit" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
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
    [ -z "$major" ] && major=$(echo "$diff" | grep -E '^\+MAJOR=' | head -1 | cut -d'=' -f2)
    minor=$(echo "$diff" | grep -E '^\s*MINOR=' | head -1 | cut -d'=' -f2)
    build=$(echo "$diff" | grep -E '^\+BUILD=' | head -1 | cut -d'=' -f2) && patch=$(echo "$diff" | grep -E '^\s*PATCH=' | head -1 | cut -d'=' -f2)
    crVersion="${major}.${minor}.${build}.${patch}"
comment
  fi
  
  [ "$crVersion" == " . . . " ] && crVersion=$(echo "$branchData" | jq -r '.[0].version' | sed -E -e 's/^([0-9]{2})([0-9])/\1X/' -e 's/([0-9])([0-9]{3})\.[0-9]+/\1XXX.X/')
  printf "\r\033[K"

  echo -e "$info Last Chromium Canary Test Version: $crVersion at branch position: $branchPosition"
}

menu() {
  local -n menu_options=$1
  local -n menu_buttons=$2
  
  selected_option=0
  selected_button=0
  
  if [ -f "$crdlJson" ] && jq -e 'has("INSTALLED_POSITION")' "$crdlJson" >/dev/null 2>&1; then
    INSTALLED=1
  else
    INSTALLED=0
  fi

  show_menu() {
    printf '\033[2J\033[3J\033[H'  # clear
    print_crdl  # call print_crdl function
    [ $INSTALLED -eq 1 ] && { echo -e "$info INSTALLED: Chromium v$appVersion - $appSize - $installedTime"; echo; }
    echo "Navigate with [↑] [↓] [←] [→]"
    echo -e "Select with [↵]\n"
    for ((i=0; i<=$((${#menu_options[@]} - 1)); i++)); do
      if [ $i -eq $selected_option ]; then
        echo -e "${whiteBG}➤ ${menu_options[$i]} $Reset"
      else
        [ $(($i + 1)) -le 9 ] && echo " $(($i + 1)). ${menu_options[$i]}" || echo "$(($i + 1)). ${menu_options[$i]}"
      fi
    done
    echo
    for ((i=0; i<=$((${#menu_buttons[@]} - 1)); i++)); do
      if [ $i -eq $selected_button ]; then
        [ $i -eq 0 ] && echo -ne "${whiteBG}➤ ${menu_buttons[$i]} $Reset" || echo -ne "  ${whiteBG}➤ ${menu_buttons[$i]} $Reset"
      else
        [ $i -eq 0 ] && echo -n "  ${menu_buttons[$i]}" || echo -n "   ${menu_buttons[$i]}"
      fi
    done
    echo
  }

  printf '\033[?25l'
  while true; do
    show_menu
    read -rsn1 key
    case $key in
      $'\E')  # ESC
        # /bin/bash -c 'read -r -p "Type any ESC key: " input && printf "You Entered: %q\n" "$input"'  # q=safelyQuoted
        read -rsn2 -t 0.1 key2
        case "$key2" in
          '[A')  # Up arrow
            selected_option=$((selected_option - 1))
            [ $selected_option -lt 0 ] && selected_option=$((${#menu_options[@]} - 1))
            ;;
          '[B')  # Down arrow
            selected_option=$((selected_option + 1))
            [ $selected_option -ge ${#menu_options[@]} ] && selected_option=0
            ;;
          '[C')  # Right arrow
            [ $selected_button -lt $((${#menu_buttons[@]} - 1)) ] && selected_button=$((selected_button + 1))
            ;;
          '[D')  # Left arrow
            [ $selected_button -gt 0 ] && selected_button=$((selected_button - 1))
            ;;
        esac
        ;;
      '')  # Enter key
        break
        ;;
      [0-9])
        if [ $key -eq 0 ]; then
          selected_option=$((${#menu_options[@]} - 1))
        elif [ $key -gt ${#menu_options[@]} ]; then
          selected_option=0
        else
          selected_option=$((key - 1))
        fi
        show_menu; sleep 0.5; break
       ;;
    esac
  done
  printf '\033[?25h'

  [ $selected_button -eq 0 ] && { printf '\033[2J\033[3J\033[H'; selected=$selected_option; }
  [ $selected_button -eq $((${#menu_buttons[@]} - 1)) ] && { printf '\033[2J\033[3J\033[H'; echo "Script exited !!"; exit 0; }
}

# --- Main Menu ---
while true; do
  if [ $foundTermuxAPI -eq 1 ]; then
    clear  # clear Terminal
    print_crdl  # Call the print crdl shape function
    if [ -f "$crdlJson" ] && jq -e 'has("INSTALLED_POSITION")' "$crdlJson" >/dev/null 2>&1; then
      while true; do
        termux-toast -g top -b white -c black "↓ $appVersion - $appSize - $installedTime"
        sleep 3  # wait for toast disappear
      done &  # run in background
      toast_pid=$!  # get toast process id
    fi
    channel_index=""  # reset (clear) index value to empty
    channel_index=$(termux-dialog radio -t "Select Chromium Channel" -v "Stable,Beta,Dev,Canary,Canary Test,Quit" | jq -r .index &)  # show radio button popup dialog
    c=0
    while true; do
      [ $c -eq 30 ] && { termux-api-stop >/dev/null 2>&1; channel_index=$(termux-dialog radio -t "Select Chromium Channel" -v "Stable,Beta,Dev,Canary,Canary Test,Quit" | jq -r .index &); c=0; }
      [ -n "$channel_index" ] && break || { sleep 1; ((c++)); }
    done
    [ -n $toast_pid ] && kill $toast_pid 2>/dev/null  # stop toast process
    # show Selected channel name using toast
    if [ "$channel_index" != "null" ]; then  # if usr chose cancel or ok then index == null
      channels=("Stable" "Beta" "Dev" "Canary" "Canary Test" "Quit")  # channels arrays
      channel="${channels[$channel_index]}"  # select index pos value by index num
      [ "$channel" == "Quit" ] && termux-toast "Script exited !!" || termux-toast "Selected: $channel"  # show toast messages
    fi
  else
    options=(Stable Beta Dev Canary Canary\ Test); buttons=("<Select>" "<Exit>"); menu "options" "buttons"; channel="${options[$selected]}"
  fi
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
    Canary)
      channel="Canary"
      echo && cInfo
      echo && findValidSnapshot "$branchPosition" $LAST_CHANGE
      ;;
    Canary\ Test)
      echo && tInfo
      directDl  # Call the direct download function
      ;;
    Quit)
      if [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties";fi
      clear  # clear Termianl
      [ $foundTermuxAPI -eq 1 ] && channel=""
      [ $foundTermuxAPI -eq 1 ] && termux-api-stop >/dev/null 2>&1
      break  # break the loop
      ;;
    *) [ $foundTermuxAPI -eq 1 ] && { termux-toast -g bottom "Invalid option! Please select a valid channel."; sleep 0.5; } ;;
  esac
done
#####################################################################################
