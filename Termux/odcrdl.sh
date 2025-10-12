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
whiteBG="\e[47m\e[30m"
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

Android=$(getprop ro.build.version.release | cut -d. -f1)  # Get major Android version

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
if [ "$Android" -eq 6 ] && [ ! -f "$HOME/.termux/termux.properties" ]; then
  mkdir -p "$HOME/.termux" && echo "allow-external-apps = true" > "$HOME/.termux/termux.properties"
  isOverwriteTermuxProp=1
  echo -e "$notice 'termux.properties' file has been created successfully & 'allow-external-apps = true' line has been add (enabled) in Termux \$HOME/.termux/termux.properties."
  termux-reload-settings
elif [ "$Android" -eq 6 ] && [ -f "$HOME/.termux/termux.properties" ]; then
  if grep -q "^# allow-external-apps" "$HOME/.termux/termux.properties"; then
    sed -i '/allow-external-apps/s/# //' "$HOME/.termux/termux.properties"  # uncomment 'allow-external-apps = true' line
    isOverwriteTermuxProp=1
    echo -e "$notice 'allow-external-apps = true' line has been uncommented (enabled) in Termux \$HOME/.termux/termux.properties."
    termux-reload-settings
  fi
fi
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

# --- Checking Internet Connection ---
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 ; then
  echo -e "${bad} ${Red} Oops! No Internet Connection available.\nConnect to the Internet and try again later."
  exit 1
fi

# --- Global variables ---
Model=$(getprop ro.product.model)  # Get device model
arch=$(getprop ro.product.cpu.abi)  # Get Android architecture
arch32=$(getprop ro.product.cup.abilist32)  # Get Android 32 bit arch
pkg update > /dev/null 2>&1  # It downloads latest package list with versions from Termux remote repository, then compares them to local (installed) pkg versions, and shows a list of what can be upgraded if they are different.
outdatedPKG=$(apt list --upgradable 2>/dev/null)
echo "$outdatedPKG" | grep -q "dpkg was interrupted" 2>/dev/null && { yes "N" | dpkg --configure -a; outdatedPKG=$(apt list --upgradable 2>/dev/null); }
installedPKG=$(pkg list-installed 2>/dev/null)  # list of installed pkg
memTotalKB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"
Download="/sdcard/Download"  # Download dir

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
pkgInstall "grep"  # grep update
pkgInstall "gawk"  # gnu awk update
pkgInstall "sed"  # sed update
pkgInstall "curl"  # curl update
pkgInstall "libcurl"  # curl lib update
pkgInstall "jq"  # jq install/update
pkgInstall "bsdtar"  # bsdtar install/update
pkgInstall "pv"  # pv install/update
pkgInstall "bc"  # bc install/update

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

if [ $arch == "arm64-v8a" ] && [ $Android -eq 9 ]; then
  buttons=("<Yes>" "<No>"); confirmPrompt "Do you want to install Extensions supported AndroidDesktop Chromium.apk?" "buttons" && crx=Yes || crx=No
  case $crx in
    y*|Y*|"") AndroidDesktop=1 ;;
    n*|N*) echo -e "$notice AndroidDesktopChromium skipped!"; AndroidDesktop=0 ;;
  esac
else
  AndroidDesktop=0
fi

# --- Detect arch (ARM or ARM64 or x86_64) ---
if [ $arch == "arm64-v8a" ]; then
  memTotalGB=$(echo "scale=2; $memTotalKB / 1048576" | bc -l 2>/dev/null || echo "0")  # scale=2 ensures the result is rounded to 2 decimal places for readability, 1048576 (which is 1024 * 1024, since 1 GB = 1024 MB and 1 MB = 1024 kB), bc is a basicCalculator
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
if ! su -c "id" >/dev/null 2>&1 && { [ ! -f "$HOME/rish" ] || [ ! -f "$HOME/rish_shizuku.dex" ]; }; then
  #echo -e "$info Please manually install Shizuku from Google Play Store." && sleep 1
  #termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  echo -e "$info Please manually install Shizuku from GitHub." && sleep 1
  termux-open-url "https://github.com/RikkaApps/Shizuku/releases/latest"
  am start -n com.android.settings/.Settings\$MyDeviceInfoActivity > /dev/null 2>&1  # Open Device Info

  curl -sL -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish" && chmod +x "$HOME/rish"
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

if [ $snapshotPlatform == "AndroidDesktop_arm64" ] || [ $snapshotPlatform == "AndroidDesktop_x64" ]; then
  crUNZIP="chrome-android-desktop"
else
  crUNZIP="chrome-android"
fi

# --- install Chromium function ---
crInstall() {
  if su -c "id" >/dev/null 2>&1; then
    su -c "cp '$Download/$crUNZIP/apks/ChromePublic.apk' '/data/local/tmp/ChromePublic.apk'"  # copy apk to System dir to avoiding SELinux restrictions
    # Temporary Disable SELinux Enforcing during installation if it not in Permissive
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c "pm install -r -i com.android.vending '/data/local/tmp/ChromePublic.apk'"
      INSTALL_STATUS=$?  # Capture exit status of the install command
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
    else
      su -c "pm install -r -i com.android.vending '/data/local/tmp/ChromePublic.apk'"
      INSTALL_STATUS=$?  # Capture exit status of the install command
    fi
    am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
    if [ $? != 0 ]; then
      su -c "monkey -p org.chromium.chrome -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
    fi
    su -c "rm -f '/data/local/tmp/ChromePublic.apk'"  # Cleanup temporary APK
    [ $INSTALL_STATUS -eq 0 ] && rm -rf "$Download/$crUNZIP"
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c "cp '$Download/$crUNZIP/apks/ChromePublic.apk' '/data/local/tmp/ChromePublic.apk'" > /dev/null 2>&1  # copy apk to System dir
    $HOME/rish -c "pm install -r -i com.android.vending '/data/local/tmp/ChromePublic.apk'" > /dev/null 2>&1  # -r=reinstall
    INSTALL_STATUS=$?  # Capture exit status of the install command
    am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1  # launch Chromium after update
    if [ $? != 0 ]; then
      ~/rish -c "monkey -p org.chromium.chrome -c android.intent.category.LAUNCHER 1" > /dev/null 2>&1
    fi
    $HOME/rish -c "rm -f '/data/local/tmp/ChromePublic.apk'"  # Cleanup temp APK
    [ $INSTALL_STATUS -eq 0 ] && rm -rf "$Download/$crUNZIP"
  elif [ $Android -le 6 ]; then
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file://$Download/$crUNZIP/apks/ChromePublic.apk" > /dev/null 2>&1  # Activity Manager
    sleep 30
    am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1 && rm -rf "$Download/$crUNZIP/"
  else
    termux-open --view "$Download/$crUNZIP/apks/ChromePublic.apk"  # install apk using Session installer
    sleep 30
    am start -n org.chromium.chrome/com.google.android.apps.chrome.Main > /dev/null 2>&1 && rm -rf "$Download/$crUNZIP/"
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
        curl -L --progress-bar -C - -o "$Download/$crUNZIP.zip" "$checkUrl"
        [ $? -eq 0 ] && break || { echo -e "$notice Retrying in 5 seconds.."; sleep 5; }
      done
      echo && echo -e "$running Extracting ${Red}$crUNZIP.zip${Reset}"
      pv "$Download/$crUNZIP.zip" | bsdtar -xf - -C "$Download" --include "$crUNZIP/apks/ChromePublic.apk" && rm "$Download/$crUNZIP.zip"
      echo; buttons=("<Yes>" "<No>"); confirmPrompt "Do you want to install Chromium_v$crVersion.apk?" "buttons" && opt=Yes || opt=No
      case $opt in
        y*|Y*|"")
          crInstall
          if [ $AndroidDesktop -eq 1 ]; then
            curl -L --progress-bar -o "$HOME/top-30.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh && bash "$HOME/top-30.sh" && rm -f "$HOME/top-30.sh"
          fi
          if su -c "id" >/dev/null 2>&1 || "$HOME/rish" -c "id" >/dev/null 2>&1; then
            [ $INSTALL_STATUS -eq 0 ] && { rm -f $PREFIX/bin/crdl; rm -f $HOME/.crdl.sh; } || { echo -e "$bad installation failed!"; sleep 1; }
          fi
          ;;
        n*|N*) echo -e "$notice Chromium installation skipped!"; rm -rf "$Download/chrome-android"; sleep 1 ;;
      esac
      if [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties";fi
      sleep 3; clear; break  # Break the searching loop
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
