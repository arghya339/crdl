#!/usr/bin/bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

if [ -f "$crdlJson" ]; then
  AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$crdlJson" 2>/dev/null)
  AutoUpdatesTermux=$(jq -r '.AutoUpdatesTermux' "$crdlJson" 2>/dev/null)
  AndroidDesktop=$(jq -r '.AndroidDesktop' "$crdlJson" 2>/dev/null)
  Prefer32bitApk=$(jq -r '.Prefer32bitApk' "$crdlJson" 2>/dev/null)
  GUI=$(jq -r '.GUI' "$crdlJson" 2>/dev/null)
else
  AutoUpdatesDependencies=true
  AutoUpdatesTermux=true
  GUI=false
fi

Android=$(getprop ro.build.version.release | cut -d. -f1)
arch=$(getprop ro.product.cpu.abi)
chromiumActivityClass="org.chromium.chrome/com.google.android.apps.chrome.Main"

# Latest Chromium required Android 10+
if [ $Android -le 9 ]; then
  curl -L --progress-bar -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/odcrdl.sh" && bash "$HOME/.crdl.sh"
fi

# x86 prebuilt binary not provide by Chromium
if [ $arch == "x86" ]; then
  echo -e "$bad ${Red}x86 (x32-bit) arch prebuilt binary not provide by Google Chromium, try manual build Chromium from src.${Reset}"
  termux-open-url "https://chromium.googlesource.com/chromium/src/+/0267e3c2/docs/android_build_instructions.md"
  if [ $Android -ge 10 ]; then
    echo -e "$info Find Chromium alternative as BraveMonox86.apk"  # Android 9.0+ (universal: arm64-v8a, armeabi-v7a, x86_64, x86)
    termux-open "https://github.com/brave/brave-browser/releases/latest/"
  else
    echo -e "$info Find Chromium alternative as Firefox."  # Android 5.0+ (universal)
    termux-open "https://play.google.com/store/apps/details?id=org.mozilla.firefox"
  fi
  rm -f $PREFIX/bin/crdl $HOME/.crdl.sh
  exit 1
fi

# --- Grant Storage Permission ---
if ! ls /sdcard/ 2>/dev/null | grep -qE "^(Android|Download)"; then
  echo -e "${notice} ${Yellow}Storage permission not granted!${Reset}\n$running ${Green}termux-setup-storage${Reset}.."
  if [ $Android -gt 5 ]; then  # for Android 5 storage permissions grant during app installation time, so Termux API termux-setup-storage command not required
    count=0
    while true; do
      if [ $count -ge 2 ]; then
        echo -e "$bad Failed to get storage permissions after $count attempts!"
        echo -e "$notice Please grant permissions manually in Termux App info > Permissions > Files > File permission → Allow."
        am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.termux &> /dev/null
        exit 0
      fi
      termux-setup-storage  # ask Termux Storage permissions
      sleep 3  # wait 3 seconds
      if ls /sdcard/ 2>/dev/null | grep -q "^Android" || ls "$HOME/storage/shared/" 2>/dev/null | grep -q "^Android"; then
        [ $Android -lt 8 ] && exit 0 || break
      fi
      ((count++))
    done
  fi
fi

# Check if TermuxAPI available
if termux-api-start > /dev/null 2>&1; then
  foundTermuxAPI=true
  grep -q "^# hide-soft-keyboard-on-startup = true" "$HOME/.termux/termux.properties" && sed -i '/hide-soft-keyboard-on-startup = true/s/# //' "$HOME/.termux/termux.properties"
  grep -q "^# soft-keyboard-toggle-behaviour = enable/disable" "$HOME/.termux/termux.properties" && sed -i '/soft-keyboard-toggle-behaviour = enable\/disable/s/# //' "$HOME/.termux/termux.properties"
else
  foundTermuxAPI=false
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

su -c "id" >/dev/null 2>&1 && su=true || su=false

# --- Shizuku Setup (first time) ---
if [ $su == false ] && { [ ! -f "$HOME/rish" ] || [ ! -f "$HOME/rish_shizuku.dex" ]; }; then
  #echo -e "$info Please manually install Shizuku from Google Play Store." && sleep 1
  #termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  echo -e "$info Please manually install Shizuku from GitHub." && sleep 1
  termux-open-url "https://github.com/RikkaApps/Shizuku/releases/latest"
  am start -n com.android.settings/.Settings\$MyDeviceInfoActivity > /dev/null 2>&1  # Open Device Info

  curl -sL -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Shizuku/rish" && chmod +x "$HOME/rish"
  sleep 0.5 && curl -sL -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Shizuku/rish_shizuku.dex"
  
  if [ $Android -lt 11 ]; then
    url="https://youtu.be/ZxjelegpTLA"  # YouTube/@MrPalash360: Start Shizuku using Computer
    activityClass="com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity"  # Open Developer options
  else
    activityClass="com.android.settings/.Settings\$WirelessDebuggingActivity"  # Open Wireless Debugging Settings
    url="https://youtu.be/YRd0FBfdntQ"  # YouTube/@MrPalash360: Start Shizuku Android 11+
  fi
  echo -e "$info Please start Shizuku by following guide: ${Blue}$url${Reset}" && sleep 1
  am start -n "$activityClass" > /dev/null 2>&1
  termux-open-url "$url"
fi
if ! "$HOME/rish" -c "id" >/dev/null 2>&1 && [ -f "$HOME/rish_shizuku.dex" ]; then
  if ~/rish -c "id" 2>&1 | grep -q 'java.lang.UnsatisfiedLinkError'; then
    rm -f "$HOME/rish_shizuku.dex" && curl -sL -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Shizuku/Play/rish_shizuku.dex"
  fi
fi

# Only for Genymotion (Android Emulator)
if [ "$(getprop ro.product.manufacturer)" == "Genymobile" ] && [ ! -f "$HOME/adb" ]; then
  curl -sL -o "$HOME/adb" "https://raw.githubusercontent.com/rendiix/termux-adb-fastboot/refs/heads/master/binary/${cpuAbi}/bin/adb" && chmod +x ~/adb
fi

pkgUpdate() {
  pkg=$1
  if echo "$outdatedPkg" | grep -q "^$pkg/" 2>/dev/null; then
    echo -e "$running Upgrading $pkg pkg.."
    output=$(yes "N" | apt install --only-upgrade "$pkg" -y 2>/dev/null)
    echo "$output" | grep -q "dpkg was interrupted" 2>/dev/null && { yes "N" | dpkg --configure -a; yes "N" | apt install --only-upgrade "$pkg" -y > /dev/null 2>&1; }
  fi
}

pkgInstall() {
  pkg=$1
  if echo "$installedPkg" | grep -q "^$pkg/" 2>/dev/null; then
    pkgUpdate "$pkg"
  else
    echo -e "$running Installing $pkg pkg.."
    pkg install "$pkg" -y > /dev/null 2>&1
  fi
}

pkgUninstall() {
  installedPkg=$(pkg list-installed 2>/dev/null)
  pkg=$1
  if echo "$installedPkg" | grep -q "^$pkg/" 2>/dev/null; then
    echo -e "$running Uninstalling $pkg pkg.."
    pkg uninstall "$pkg" -y > /dev/null 2>&1
  fi
}

dependencies() {
  installedPkg=$(pkg list-installed 2>/dev/null)  # list of installed pkg
  pkg update > /dev/null 2>&1 || apt update >/dev/null 2>&1  # It downloads latest package list with versions from Termux remote repository, then compares them to local (installed) pkg versions, and shows a list of what can be upgraded if they are different.
  outdatedPkg=$(apt list --upgradable 2>/dev/null)  # list of outdated pkg
  echo "$outdatedPkg" | grep -q "dpkg was interrupted" 2>/dev/null && { yes "N" | dpkg --configure -a; outdatedPkg=$(apt list --upgradable 2>/dev/null); }
  
  pkgInstall "apt"  # apt update
  pkgInstall "dpkg"  # dpkg update
  pkgInstall "bash"  # bash update
  pkgInstall "libgnutls"  # pm apt & dpkg use it to securely download packages from repositories over HTTPS
  pkgInstall "coreutils"  # It provides basic file, shell, & text manipulation utilities. such as: ls, cp, mv, rm, mkdir, cat, echo, etc.
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
  pkgInstall "openssl"  # openssl install/update
  pkgInstall "aria2"  # aria2 install/update
  pkgInstall "jq"  # jq install/update
  pkgInstall "pup"  # pup install/update
  pkgInstall "bsdtar"  # bsdtar install/update
  pkgInstall "pv"  # pv install/update
}
[ "$AutoUpdatesDependencies" == true ] && checkInternet && dependencies

[[ $(~/aapt2 version 2>&1 | awk '{print $NF}') =~ ^(2.19-1023|2.19-3401)$ ]] || { rm -f ~/aapt2 && curl -L --progress-bar -C - -o ~/aapt2 $(curl -sL https://api.github.com/repos/ReVanced/aapt2/releases/latest | jq -r --arg abi "$arch" '.assets[] | select(.name == "aapt2-" + $abi) | .browser_download_url') && chmod +x ~/aapt2 && ~/aapt2 version 2>&1; }

if [ "$arch" == "arm64-v8a" ] && [ -z "$AndroidDesktop" ]; then
  if [ $foundTermuxAPI == true ] && [ $GUI == true ]; then
    crx=$(termux-dialog confirm -t "Install Chrome Extensions" -i "Do you want to install Extensions supported AndroidDesktop Chromium?" | jq -r '.text')
  else
    confirmPrompt "Do you want to install Extensions supported AndroidDesktop Chromium?" "ynButtons" && AndroidDesktop=yes || AndroidDesktop=no
  fi
  config "AndroidDesktop" "$AndroidDesktop"
fi

# Prefer 32-bit apk if device is usually low on memory (lessthen 4GB RAM)
memTotalKB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
memTotalGB=$((memTotalKB / 1024 / 1024))
arch32=$(getprop ro.product.cpu.abilist32)
([ $memTotalGB -le 4 ] && [ "$arch32" == "armeabi-v7a,armeabi" ]) && isPrefer32bitApk=true || isPrefer32bitApk=false
! jq -e --arg key "Prefer32bitApk" 'has($key)' "$crdlJson" &>/dev/null && { Prefer32bitApk="$isPrefer32bitApk"; config "Prefer32bitApk" "$Prefer32bitApk"; }

if [ "$arch" == "arm64-v8a" ]; then
  if [ "$AndroidDesktop" == "yes" ]; then
    snapshotPlatform="AndroidDesktop_arm64"
  elif [ $Prefer32bitApk == true ]; then
    snapshotPlatform="Android"
  else
    snapshotPlatform="Android_Arm64"
  fi
elif [ "$arch" == "armeabi-v7a" ]; then
  snapshotPlatform="Android"
elif [ "$arch" == "x86_64" ]; then
  snapshotPlatform="AndroidDesktop_x64"
fi
platform=Android
([ $snapshotPlatform == "AndroidDesktop_arm64" ] || [ $snapshotPlatform == "AndroidDesktop_x64" ]) && crZIP="chrome-android-desktop" || crZIP="chrome-android"

appInstall() {
  filePath=${1}
  activityClass=${2:-$chromiumActivityClass}
  fileName=$(basename "$filePath" 2>/dev/null)
  
  if [ $su == true ]; then
    su -c "cp '$filePath' '/data/local/tmp/$fileName'"
    # Temporary Disable SELinux Enforcing during installation if it not in Permissive
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
      installStatus=$?
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
    else
      su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
      installStatus=$?
    fi
    su -c "rm -f '/data/local/tmp/$fileName'"
    am start -n $activityClass &>/dev/null  # launch Chromium after install/update
    [ $installStatus -eq 0 ] && rm -f "$filePath"
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c "cp '$filePath' '/data/local/tmp/$fileName'"
    ~/rish -c "pm install -r -i com.android.vending '/data/local/tmp/$fileName'" > /dev/null 2>&1  # -r=reinstall
    installStatus=$?
    $HOME/rish -c "rm -f '/data/local/tmp/$fileName'"
    am start -n $activityClass &>/dev/null  # launch app after install/update
    [ $installStatus -eq 0 ] && rm -f "$filePath"
  elif "$HOME/adb" -s $(~/adb devices | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; then
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cp $filePath /data/local/tmp/$fileName
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell pm install -r -i com.android.vending "/data/local/tmp/$fileName" > /dev/null 2>&1
    #~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cmd package install -r -i com.android.vending "/data/local/tmp/$fileName" > /dev/null 2>&1
    installStatus=$?
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "rm -f '/data/local/tmp/$fileName'"
    am start -n $activityClass &>/dev/null  # launch app after install/update
    [ $installStatus -eq 0 ] && rm -f "$filePath"
  elif [ $Android -le 6 ]; then
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file://${filePath}"
    sleep 15
    am start -n $activityClass &>/dev/null
    rm -f "$filePath"
  else
    termux-open --view "$filePath"
    sleep 15
    am start -n $activityClass &>/dev/null
    rm -f "$filePath"
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
    tag=$(curl -sL https://api.github.com/repos/termux/termux-widget/releases/latest | jq -r '.tag_name')
    while true; do
      curl -L --progress-bar -C - -o "$Download/termux-widget-app_$tag+github.debug.apk" "https://github.com/termux/termux-widget/releases/download/$tag/termux-widget-app_$tag+github.debug.apk"
      [ $? -eq 0 ] && break || { echo -e "$notice Download failed! Retrying in 5 seconds.."; sleep 5; }
    done
    appInstall "$Download/termux-widget-app_$tag+github.debug.apk" "com.termux.widget/com.termux.widget.TermuxLaunchShortcutActivity"  # Install Termux:Widget app using appInstall function
  fi
  if [ $su == true ]; then
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
  elif "$HOME/adb" -s $(~/adb devices | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; then
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell pm grant com.termux android.permission.POST_NOTIFICATIONS
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cmd deviceidle whitelist +com.termux
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cmd appops set com.termux REQUEST_INSTALL_PACKAGES allow
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cmd appops set com.termux.widget REQUEST_INSTALL_PACKAGES allow
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cmd appops set com.termux SYSTEM_ALERT_WINDOW allow
  else
    echo -e "$info Please manually turn on: ${Green}Display over other apps → Termux → Allow display over other apps${Reset}" && sleep 5
    am start -a android.settings.action.MANAGE_OVERLAY_PERMISSION &>/dev/null  # open manage overlay permission settings
  fi
  echo -e "$info Please Disabled: ${Green}Battery optimization → Not optimized → All apps → Termux → Don't optiomize → DONE${Reset}" && sleep 5
  am start -n com.android.settings/.Settings\$HighPowerApplicationsActivity &>/dev/null
  echo -e "$info From Termux:Widget app tap on ${Green}crdl → Add to home screen${Reset}. Opening Termux:Widget app in 5 seconds.." && sleep 5
  am start -n com.termux.widget/com.termux.widget.TermuxCreateShortcutActivity > /dev/null 2>&1  # open Termux:Widget app shortcut create activity (screen/view) to add shortcut on Launcher Home
fi

# Create crup shortcut
if [ ! -f "$HOME/.shortcuts/crup" ] || [ ! -f "$HOME/.termux/widget/dynamic_shortcuts/crup" ]; then
  if am start -n com.termux.widget/com.termux.widget.TermuxLaunchShortcutActivity &>/dev/null; then
    echo -e "$notice Please wait few seconds! Creating crup shortcut to Update Chromium from Launcher Widget."
    echo -e "#!/usr/bin/bash\nbash \$PREFIX/bin/crup" > ~/.shortcuts/crup  # create crup shortcut script
    echo -e "#!/usr/bin/bash\nbash \$PREFIX/bin/crup" > ~/.termux/widget/dynamic_shortcuts/crup  # create crup dynamic shortcut script
    chmod +x ~/.termux/widget/dynamic_shortcuts/crup  # give execute (--x) permissions to crup script
    echo -e "$info From Termux:Widget app tap on ${Green}crup → Add to home screen${Reset}." && sleep 5
    am start -n com.termux.widget/com.termux.widget.TermuxCreateShortcutActivity &>/dev/null  # open Termux:Widget app shortcut create activity (screen/view) to add shortcut on Launcher Home
  fi
fi

if [ $AutoUpdatesTermux == true ]; then
  if [ $Android -ge 8 ]; then
    tag_name=$(curl -sL https://api.github.com/repos/termux/termux-app/releases/latest | jq -r '.tag_name')  # v0.118.3
    fileName="termux-app_${tag_name}+github-debug_$arch.apk"
  else
    tag_name=$(curl -sL https://api.github.com/repos/termux/termux-app/tags | jq -r '.[0].name')  # v0.119.0-beta.3
    [ $Android -eq 7 ] && variant=7 || variant=5
    fileName="termux-app_${tag_name}+apt-android-$variant-github-debug_$arch.apk"
  fi
  dlURL="https://github.com/termux/termux-app/releases/download/$tag_name/$fileName"; filePath="$Download/$fileName"
  if [ "$TERMUX_VERSION" != "$(sed 's/^v//' <<< "$tag_name")" ]; then
    echo -e "$notice Termux app is outdated!\n$running Downloading Termux app update.."
    while true; do
      curl -L --progress-bar -C - -o "$filePath" "$dlURL"
      [ $? -eq 0 ] && break || { echo -e "$notice Download failed! retrying in 5 seconds.."; sleep 5; }
    done
    echo -e "$notice Please rerun this script again after updating the Termux app!"
    echo -e "$running Installing app update and restarting Termux app.." && sleep 3
    if [ $su == true ]; then
      su -c "cp '$filePath' '/data/local/tmp/$fileName'"
      if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
        su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
        su -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
        su -c "cmd deviceidle whitelist +com.termux" >/dev/null 2>&1
        touch "$crdl/setenforce0"
        su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
      else
        su -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
        su -c "cmd deviceidle whitelist +com.termux" >/dev/null 2>&1
        su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
      fi
    else
      if "$HOME/rish" -c "id" >/dev/null 2>&1; then
        $HOME/rish -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
        $HOME/rish -c "cmd deviceidle whitelist +com.termux" >/dev/null 2>&1
        $HOME/rish -c "cmd appops set com.termux REQUEST_INSTALL_PACKAGES allow"
      elif "$HOME/adb" -s $(~/adb devices | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; then
        ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "pm grant com.termux android.permission.POST_NOTIFICATIONS"
        ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "cmd deviceidle whitelist +com.termux" >/dev/null 2>&1
        ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "cmd appops set com.termux REQUEST_INSTALL_PACKAGES allow"
      else
        echo -e "$info Please Disabled: ${Green}Battery optimization → Not optimized → All apps → Termux → Don't optiomize → DONE${Reset}" && sleep 6
        am start -n com.android.settings/.Settings\$HighPowerApplicationsActivity &> /dev/null
        echo -e "$info Please Allow: ${Green}Install unknown apps → Termux → Allow from this source${Reset}" && sleep 6
        am start -n com.android.settings/.Settings\$ManageExternalSourcesActivity &> /dev/null
      fi
      appInstall "$filePath" "com.termux/.app.TermuxActivity"
    fi
  else
    if [ -f "$filePath" ]; then
      if [ $su == true ]; then
        if [ "$(su -c 'getenforce 2>/dev/null')" = "Permissive" ] && [ -f "$crdl/setenforce0" ]; then
          su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
          rm -f "$crdl/setenforce0"
        fi
        su -c "rm -f '/data/local/tmp/$fileName'"
      elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
        ~/rish -c "rm -f '/data/local/tmp/$fileName'"
      elif "$HOME/adb" -s $(~/adb devices | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; then
        ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "rm -f '/data/local/tmp/$fileName'"
      fi
      rm -f "$filePath"
    fi
  fi
fi

installTermuxAPI() {
  if ! am start -n "com.termux.api/com.termux.shared.activities.ReportActivity" &>/dev/null; then
    tag_name=$(curl -sL "https://api.github.com/repos/termux/termux-api/releases/latest" | jq -r '.tag_name')
    while true; do
      curl -L -C - --progress-bar -o "$Download/termux-api-app_${tag_name}+github.debug.apk" "https://github.com/termux/termux-api/releases/download/$tag_name/termux-api-app_$tag_name+github.debug.apk"
      [ $? -eq 0 ] && break || sleep 5
    done
    [ -f $Download/termux-api-app_${tag_name}+github.debug.apk ] && appInstall "$Download/termux-api-app_${tag_name}+github.debug.apk" "com.termux.api/com.termux.shared.activities.ReportActivity"
  else
    filePath=$(find "$Download" -type f -name "termux-api-app_v*+github.debug.apk" -print -quit)
    [ -f "$filePath" ] && rm -f "$filePath"
  fi
  pkgInstall "termux-api"
}

SchedulerUpdateChromium() { termux-job-scheduler --script $crdl/crup.sh --period-ms ${1} --job-id 1993615810 --persisted true; }  # host chromium.org

TimerTriggerUpdateChromium() {
  time=${1}
  HH="${time%:*}"
  MM="${time#*:}"
  pkgInstall "cronie"
  (crontab -l | grep -v "crup.sh") | crontab -
  (crontab -l 2>/dev/null; echo "${MM} ${HH} * * * $crdl/crup.sh") | crontab -
  pkgInstall "termux-services"  # for bg services
  mkdir -p $PREFIX/var/service/crond
  echo -e "#!/usr/bin/bash\nexec crond -n -s" > $PREFIX/var/service/crond/run
  pgrep crond >/dev/null || crond
  sv up $PREFIX/var/service/crond
  sv-enable crond
  pgrep crond && termux-wake-lock
}

UpdateChromiumAtBoot() {
  if ! am start -n com.termux.boot/com.termux.boot.BootActivity &>/dev/null; then
    tag_name=$(curl -sL "https://api.github.com/repos/termux/termux-boot/releases/latest" | jq -r '.tag_name')
    while true; do
      curl -L -C - --progress-bar -o "$Download/termux-boot-app_${tag_name}+github.debug.apk" "https://github.com/termux/termux-boot/releases/download/$tag_name/termux-boot-app_$tag_name+github.debug.apk"
      [ $? -eq 0 ] && break || sleep 5
    done
    [ -f "$Download/termux-boot-app_${tag_name}+github.debug.apk" ] && apkInstall "$Download/termux-boot-app_${tag_name}+github.debug.apk" "com.termux.boot/com.termux.boot.BootActivity"
  else
    filePath=$(find "$Download" -type f -name "termux-boot-app_v*+github.debug.apk" -print -quit)
    [ -f "$filePath" ] && rm -f "$filePath"
  fi
  mkdir -p ~/.termux/boot/
  echo -e "#!/usr/bin/bash\nbash $crdl/crup.sh" > ~/.termux/boot/crup
}
