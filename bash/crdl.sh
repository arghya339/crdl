#!/usr/bin/env bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>
# Chromium is an open-source browser project, developed and maintained by Google <chromium.org/Home>

shopt -s extglob

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

checkInternet() {
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    return
  else
    echo -e "$bad ${Red}No Internet Connection available!${Reset}"
    return 1
  fi
}

if [[ "$(uname)" == "Darwin" ]]; then
  isMacOS=true; isAndroid=false; isFedora=false
elif [[ -d "/sdcard" ]] && [[ -d "/system" ]]; then
  isAndroid=true; isMacOS=false; isFedora=false
elif [[ -f "/etc/os-release" ]]; then
  if grep -qi "fedora" /etc/os-release 2>/dev/null; then
    isFedora=true; isAndroid=false; isMacOS=false
  fi
fi

([ $isAndroid == true ] || [ $isMacOS == true ]) && USER_HOME="$HOME" || USER_HOME="$(getent passwd 1000 | cut -d: -f6)"
crdl="$USER_HOME/.crdl"
[ $isAndroid == true ] && Download="/sdcard/Download" || Download="$USER_HOME/Downloads"
mkdir -p $crdl
crdlJson="$crdl/crdl.json"
[ -t 0 ] && read rows cols < <(stty size)
eButtons=("<Select>" "<Exit>")
bButtons=("<Select>" "<Back>")
ynButtons=("<Yes>" "<No>")
tfButtons=("<true>" "<false>")
branchURL="https://commondatastorage.googleapis.com/chromium-browser-snapshots"
googleDoH="https://dns.google/dns-query"
googleIP="8.8.8.8,8.8.4.4"

config() {
  local key="$1"
  local value="$2"
  
  [ ! -f "$crdlJson" ] && jq -n "{}" > "$crdlJson"
  jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$crdlJson" > temp.json && mv temp.json "$crdlJson"
}

scripts=(menu confirmPrompt)
[ $isAndroid == true ] && scripts+=(Termux)
[ $isMacOS == true ] && scripts+=(macOS)
[ $isFedora == true ] && scripts+=(Fedora)

run() {
  for ((c=0; c<${#scripts[@]}; c++)); do
    source $crdl/${scripts[c]}.sh
  done
}

[ -f "$crdl/.version" ] && localVersion=$(cat "$crdl/.version") || localVersion=
checkInternet &>/dev/null && remoteVersion=$(curl -sL "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/.version") || remoteVersion="$localVersion"
updates() {
  curl -sL -o "$crdl/.version" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/.version"
  curl -sL -o "$USER_HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/crdl.sh"
  curl -sL -o "$crdl/crup.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/crup.sh"
  if [ $isAndroid == true ]; then
    [ ! -f "$PREFIX/bin/crdl" ] && ln -s ~/.crdl.sh $PREFIX/bin/crdl
    [ ! -f "$PREFIX/bin/crup" ] && ln -s $crdl/crup.sh $PREFIX/bin/crup
  elif [ $isMacOS == true ]; then
    [ ! -f "/usr/local/bin/crdl" ] && ln -s $HOME/.crdl.sh /usr/local/bin/crdl
    [ ! -f "/usr/local/bin/crup" ] && ln -s $crdl/crup.sh /usr/local/bin/crup
  else
    [ ! -f "/usr/local/bin/crdl" ] && sudo ln -s $USER_HOME/.crdl.sh /usr/local/bin/crdl
    [ ! -f "/usr/local/bin/crup" ] && sudo ln -s $crdl/crup.sh /usr/local/bin/crup
  fi
  [ ! -x $USER_HOME/.crdl.sh ] && chmod +x $USER_HOME/.crdl.sh
  [ ! -x $crdl/crup.sh ] && chmod +x $crdl/crup.sh
  for ((c=0; c<${#scripts[@]}; c++)); do
    if [ $c -le 1 ]; then
      curl -sL -o "$crdl/${scripts[c]}.sh" "https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/next/bash/${scripts[c]}.sh"
    else
      curl -sL -o "$crdl/${scripts[c]}.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/${scripts[c]}.sh"
    fi
    source $crdl/${scripts[c]}.sh
  done
}
[ -f "$crdl" ] && AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$crdlJson" 2>/dev/null) || AutoUpdatesScript=true
if [ "$AutoUpdatesScript" == true ]; then
  [ "$remoteVersion" != "$localVersion" ] && { checkInternet && updates && localVersion="$remoteVersion"; } || run
else
  run
fi

all_key=(printArt AutoUpdatesScript AutoUpdatesDependencies RmDlFile Downloader Scheduler Timer Boot)
all_value=(true true true true curl None None false)
[ $isAndroid == true ] && { all_key+=(AutoUpdatesTermux GUI); all_value+=(true false); }
for i in "${!all_key[@]}"; do
  ! jq -e --arg key "${all_key[i]}" 'has($key)' "$crdlJson" &>/dev/null && config "${all_key[i]}" "${all_value[i]}"
done

reloadConfig() {
  if [ -f "$crdlJson" ]; then
    printArt=$(jq -r '.printArt' "$crdlJson" 2>/dev/null)
    AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$crdlJson" 2>/dev/null)
    AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$crdlJson" 2>/dev/null)
    [ $isAndroid == true ] && { AutoUpdatesTermux=$(jq -r '.AutoUpdatesTermux' "$crdlJson" 2>/dev/null); GUI=$(jq -r '.GUI' "$crdlJson" 2>/dev/null); }
    RmDlFile=$(jq -r '.RmDlFile' "$crdlJson" 2>/dev/null)
    Downloader=$(jq -r '.Downloader' "$crdlJson" 2>/dev/null)
    if [ $isAndroid == true ] && [ "$arch" == "arm64-v8a" ]; then
      AndroidDesktop=$(jq -r '.AndroidDesktop' "$crdlJson" 2>/dev/null)
      [ $memTotalGB -le 4 ] && Prefer32bitApk=$(jq -r '.Prefer32bitApk' "$crdlJson" 2>/dev/null)
    fi
    Scheduler=$(jq -r '.Scheduler' "$crdlJson" 2>/dev/null)
    Timer=$(jq -r '.Timer' "$crdlJson" 2>/dev/null)
    Boot=$(jq -r '.Boot' "$crdlJson" 2>/dev/null)
    crupBgServiceType=$(jq -r '.crupBgServiceType' "$crdlJson" 2>/dev/null)
  else
    printArt=true
    AutoUpdatesScript=true
    AutoUpdatesDependencies=true
    [ $isAndroid == true ] && { AutoUpdatesTermux=true; GUI=false; }
    RmDlFile=true
    Downloader=curl
    Scheduler=None
    Timer=None
    Boot=false
  fi
}; reloadConfig

print_crdl() {
  printf '\033[2J\033[3J\033[H'
  printf "${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}    _/  ${Reset} ${Cyan}         _/  _/${Reset}\n"   
  printf "${skyBlue}    _/_/_/${Reset}${Blue}  _/  _/_/${Reset}  ${White}     _/ ${Reset} ${Cyan}    _/_/_/  _/ ${Reset}\n"   
  printf "${skyBlue} _/      ${Reset}${Blue}  _/_/     ${Reset}  ${White}      _/${Reset} ${Cyan} _/    _/  _/  ${Reset}\n"   
  printf "${skyBlue}_/       ${Reset}${Blue} _/        ${Reset}  ${White}   _/   ${Reset} ${Cyan}_/    _/  _/   ${Reset}\n"   
  printf "${skyBlue} _/_/_/  ${Reset}${Blue}_/         ${Reset}  ${White}_/      ${Reset} ${Cyan} _/_/_/  _/    ${Reset}\n"   
  printf "${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}        ${Reset} ${Cyan}               ${Reset}\n"   
  printf "${White}           ${Reset}${Blue}           ${Reset} ${White}_/_/_/_/_/${Reset}${Cyan}               ${Reset}\n"
  echo
}

LAST_CHANGE=$(curl -sL "$branchURL/$snapshotPlatform/LAST_CHANGE")
Channel=$(jq -r '.CHANNEL' "$crdlJson" 2>/dev/null)
[ "$Channel" == "null" ] && Channel=Stable
installedPosition=$(jq -r '.INSTALLED_POSITION' "$crdlJson" 2>/dev/null)
installedVersion=$(jq -r '.INSTALLED_VERSION' "$crdlJson" 2>/dev/null)
appSize=$(jq -r '.APP_SIZE' "$crdlJson" 2>/dev/null)
if [ $isAndroid == true ]; then
  appVersion=$(jq -r '.APP_VERSION' "$crdlJson" 2>/dev/null)
  appVCode=$(jq -r '.APP_VCODE' "$crdlJson" 2>/dev/null)
elif [ $isMacOS == true ]; then
  [ -d /Applications/Chromium.app ] && appVersion=$(/Applications/Chromium.app/Contents/MacOS/Chromium --version | awk '{print $2}')
elif [ $isFedora == true ]; then
  [ -d /opt/$crZIP/ ] && appVersion=$(/opt/$crZIP/chrome --version | awk '{print $2}')
fi
installedTime=$(jq -r '.INSTALLED_TIME' "$crdlJson" 2>/dev/null)

# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  printf '\033[2J\033[3J\033[H'  # clear aria2 multi error log from console
  print_crdl  # print crdl logo
  [ "$appVersion" != "null" ] && echo -e "$info INSTALLED: Chromium v$appVersion - $appSize - $installedTime\n"
  echo "Navigate with [↑] [↓] [←] [→]"
  echo -e "Select with [↵]\n"
  for ((i=0; i<=$((${#options[@]} - 1)); i++)); do
    if [ $i -eq $selected ]; then
      echo -e "${whiteBG}➤ ${options[$i]} $Reset"
    else
      [ $(($i + 1)) -le 9 ] && echo " $(($i + 1)). ${options[$i]}" || echo "$(($i + 1)). ${options[$i]}"
    fi
  done
  echo -e "\n${whiteBG}➤ ${buttons[0]} $Reset   ${buttons[1]}"
  echo -e "\n$info Last Chromium $option Version: $crVersion at branch position: $branchPosition"
  echo -e "${good} Found valid snapshot at: $branchPosition\n"
  echo -e "$running Downloading Chromium $crVersion from ${Blue}$dlURL${Reset} $crdlSize"
}

mkConfig() {
  [ -n "$crup" ] && config "CHANNEL" "$Channel" || config "CHANNEL" "$option"
  config "INSTALLED_POSITION" "$branchPosition"
  config "INSTALLED_VERSION" "$crVersion"
  [ $isAndroid == true ] && { config "APP_VERSION" "$appVersion"; config "APP_VCODE" "$appVersionCode"; }
  config "APP_SIZE" "$crSize"
  config "INSTALLED_TIME" "$(date "+%Y-%m-%d %H:%M")"
  [ $RmDlFile == true ] && rm -rf "$Download/$crZIP/" || { cp "$appPath" "$Download/$(basename $appPath)" && rm -rf "$Download/$crZIP/"; }
  if [ $isAndroid == true ] && [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties"; fi
  printf '\033[2J\033[3J\033[H'; exit 0
}

installPrompt() {
  appPath=${1}
  if [ $isAndroid == true ]; then
    appVersion=$($HOME/aapt2 dump badging $appPath 2>/dev/null | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
    appVersionCode=$($HOME/aapt2 dump badging $appPath 2>/dev/null | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
    crSize=$(awk "BEGIN {printf \"%.2f MB\n\", $(stat -c%s $appPath 2>/dev/null)/1000000}" 2>/dev/null)
  elif [ $isMacOS == true ]; then
    chmod -R +x $appPath && appVersion=$($appPath/Contents/MacOS/Chromium --version | awk '{print $2}' 2>/dev/null)
    crSize=$(du -sk "$appPath" | awk '{total_bytes = $1 * 1024; printf "%.2f MB\n", total_bytes / 1000000}')
  elif [ $isFedora == true ]; then
    chmod -R +x $appPath && appVersion=$($appPath/chrome --version | awk '{print $2}' 2>/dev/null)
    crSize=$(du -sk "$appPath" | awk '{total_bytes = $1 * 1024; printf "%.2f MB\n", total_bytes / 1000000}')
  fi

  if [ -n "$crup" ]; then
    opt=yes
  elif [ $isAndroid == true ] && [ $foundTermuxAPI == true ] && [ $GUI == true ]; then
    opt=$(termux-dialog confirm -t "Install Chromium" -i "Do you want to install Chromium v$appVersion?" | jq -r '.text')
  else
    echo; confirmPrompt "Do you want to install Chromium v$appVersion?" "ynButtons" && opt=yes || opt=no
  fi

  case "$opt" in
    yes)
      appInstall "$appPath"
      if [ $isAndroid == true ] && ! jq -e 'has("INSTALLED_POSITION")' "$crdlJson" &>/dev/null && [ "$AndroidDesktop" == "yes" ]; then
        curl -L --progress-bar -C - -o "$crdl/top-30.sh" "https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh" && bash "$crdl/top-30.sh" && rm "$crdl/top-30.sh"
      elif ( [ $isMacOS == true ] && [ ! -d "/Applications/Chromium.app" ] ) || ( [ $isFedora == true ] && [ ! -d "/opt/$crZIP/" ] ); then
        curl -L --progress-bar -C - -o "$crdl/top-50.sh" "https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-50.sh" && bash "$crdl/top-50.sh" && rm -f "$crdl/top-50.sh"
      fi
      if [ $isAndroid == false ] || { [ $isAndroid == true ] && { [ $su == true ] || "$HOME/rish" -c "id" >/dev/null 2>&1 || "$HOME/adb" -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; }; }; then
        if [ $installStatus -eq 0 ]; then
          if [ -n "$crup" ]; then
            if [ -t 0 ]; then
              echo -e "$good Chromium updated Successfully."
            else
              if [ $isAndroid == true ]; then
                [ $foundTermuxAPI == true ] && termux-notification --title "crdl" --content "Chromium updated Successfully."
              elif [ $isMacOS == true ]; then
                osascript -e 'display notification "Chromium updated Successfully." with title "crdl"'
              else
                sudo -u "$(getent passwd 1000 | cut -d: -f1)" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "crdl" "Chromium updated Successfully."
              fi
            fi
          else
            echo -e "$good Successfully installed."
          fi
          mkConfig
        else
          if [ -n "$crup" ]; then
            if [ -t 0 ]; then
              echo -e "$bad Failed to update Chromium!"
            else
              if [ $isAndroid == true ]; then
                [ $foundTermuxAPI == true ] && termux-notification --title "crdl" --content "Failed to update Chromium!"
              elif [ $isMacOS == true ]; then
                osascript -e 'display notification "Failed to update Chromium!" with title "crdl"'
              else
                sudo -u "$(getent passwd 1000 | cut -d: -f1)" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "crdl" "Failed to update Chromium!"
              fi
            fi
          else
            echo -e "$bad Installation failed!"
          fi
          sleep 1
        fi
      else
        mkConfig
      fi
      ;;
    no)
      ([ $isAndroid == true ] && [ $foundTermuxAPI == true ] && [ $GUI == true ]) && termux-toast "Chromium installation skipped!" || echo -e "$notice Chromium installation skipped!"
      rm -rf "$Download/$crZIP/"
      sleep 1
      ;;
  esac
}

dl() {
  dlURL=${1}

  crdlSize=$(curl -sIL $dlURL 2>/dev/null | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }' 2>/dev/null)
  echo -e "$running Downloading Chromium $crVersion from ${Blue}$dlURL${Reset} $crdlSize"
  archivePath="$Download/$crZIP.zip"
  [ $isMacOS == true ] && aria2Arg=("--ca-certificate=/etc/ssl/cert.pem") || aria2Arg=()
  while true; do
    if [ "$Downloader" == "curl" ]; then
      curl -L --progress-bar -C - -o "$archivePath" "$dlURL" --doh-url $googleDoH
      downloadStatus=$?
    else
      aria2c -x 16 -s 16 --continue=true --console-log-level=error --summary-interval=0 --download-result=hide -o "$crZIP.zip" -d "$Download" "$dlURL" "${aria2Arg[@]}" --async-dns=true --async-dns-server="$googleIP"
      downloadStatus=$?
      echo  # White space
    fi
    if [ $downloadStatus -eq 0 ]; then
      echo -e "\n$running Extrcting ${Red}$crZIP.zip${Reset}"
      [ $isAndroid == true ] && termux-wake-lock
      [ $isAndroid == true ] && pvArg=("--include" "$crZIP/apks/ChromePublic.apk") || pvArg=()
      pv "$archivePath" | bsdtar -xf - -C "$Download" "${pvArg[@]}" && rm -f "$archivePath"
      [ $isAndroid == true ] && termux-wake-unlock
      if [ $isAndroid == true ]; then
        appPath="$Download/$crZIP/apks/ChromePublic.apk"
      elif [ $isMacOS == true ]; then
        appPath="$Download/$crZIP/Chromium.app"
      elif [ $isFedora == true ]; then
        appPath="$Download/$crZIP/"
      fi
      installPrompt "$appPath"
      break  # break the resuming download loop
    else
      [ "$Downloader" == "aria2" ] && aria2ConsoleLogHide  # for aria2
    fi
    echo -e "$notice Download failed! retrying in 5 seconds.." && sleep 5  # wait 5 seconds
  done
}

Notify() {
  if [ $isAndroid == true ]; then
    [ $foundTermuxAPI == true ] && termux-notification --title "crup" --content "$installedVersion($installedPosition)→$crVersion($branchPosition)"
  elif [ $isMacOS == true ]; then
    osascript -e "display notification \"$installedVersion($installedPosition)→$crVersion($branchPosition)\" with title \"crup\""
  else
    sudo -u "$(getent passwd 1000 | cut -d: -f1)" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "crup" "$installedVersion($installedPosition)→$crVersion($branchPosition)"
  fi
  exit 0
}

fetchValidSnapshot() {
  dlURL="$branchURL/$snapshotPlatform/$branchPosition/$crZIP.zip"
  if curl -L --head --silent --fail "$dlURL" &>/dev/null; then
    echo -e "$good Found valid snapshot at position: $branchPosition\n"
    if [ "$installedPosition" == "$branchPosition" ]; then
      echo -e "$notice Already installed: $installedPosition"
      if [ $isAndroid == true ] && [ $isOverwriteTermuxProp == true ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties"; fi
      sleep 3; clear; exit 0
    else
      ([ "$crupBgServiceType" == "Notification" ] && [ ! -t 0 ]) && Notify || dl "$dlURL"
    fi
  else
    echo -e "$bad No direct download URL found!"; sleep 1
  fi
}

findValidSnapshot() {
  local position=$1

  echo -e "$running Searching downward from position $position"
  for ((i=position; i>0; i--)); do
    snapshotURL="$branchURL/$snapshotPlatform/$i/$crZIP.zip"
    if curl -L --head --silent --fail "$snapshotURL" &>/dev/null; then
      branchPosition="$i"
      echo -e "$good Found valid snapshot at position: $branchPosition\n"
      if [ "$installedPosition" == "$branchPosition" ] && [ "$installedVersion" == "$crVersion" ]; then
        echo -e "$notice Already installed: $installedVersion"
        if [ $isAndroid == true ] && [ $isOverwriteTermuxProp == true ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties"; fi
        sleep 3; printf '\033[2J\033[3J\033[H'; exit 0
      else
        ([ "$crupBgServiceType" == "Notification" ] && [ ! -t 0 ]) && Notify || dl "$snapshotURL"
        sleep 3; break  # Break the searching loop
      fi
    else
      echo -e "$notice No valid snapshot found at position: $i"
    fi
  done
}

fetchReleases() {
  channel=${1}
  branchData=$(curl -sL "https://chromiumdash.appspot.com/fetch_releases?channel=${channel}&platform=${platform}&num=2")
  crVersion=$(jq -r '.[0].version' <<< "$branchData")
  branchPosition=$(jq -r '.[0].chromium_main_branch_position' <<< "$branchData")
  echo -e "\n$info Last Chromium $channel version: $crVersion at branch position: $branchPosition"
  findValidSnapshot "$branchPosition"
}

fetchPreReleases() {
  printf "🕊️ ${Yellow}Please wait few seconds! fetching releases version..${Reset}"
  branchData=$(curl -sL "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=${platform}&num=1")
  branchPosition="$LAST_CHANGE"
  
  curl -fsL "https://chromium.googlesource.com/chromium/src/+log?n=1" &>/dev/null
  if [ $? -eq 0 ]; then
    n="500"  # load 500 commits (log)
    while true; do
      count=$(curl -sL "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'li json{}' | jq -r '.[] | select(.children[].text | test("Updating trunk VERSION from")) | .children[] | select(.class == "CommitLog-time") | .text' | sed 's/^[·[:space:]]*//' | wc -l | xargs)
      [ $count -ge 1 ] && break  # break if found "Updating trunk VERSION from" commit message (summary)
      n=$((n + 500))  # load n+500 commits
    done

    # Get the Chromium Canary Test commit time string (e.g., "30 seconds / 30 minutes / 36 hours / 2 days ago")
    time_str=$(curl -sL "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'li json{}' | jq -r '.[] | select(.children[].text | test("Updating trunk VERSION from")) | .children[] | select(.class == "CommitLog-time") | .text' | head -1 | sed 's/^[·[:space:]]*//')

    # Parse the time string into minutes
    if [[ "$time_str" =~ ([0-9]+)[[:space:]]+second ]]; then
      time_min=$(( ${BASH_REMATCH[1]} / 60 ))
    elif [[ "$time_str" =~ ([0-9]+)[[:space:]]+minute ]]; then
      time_min=${BASH_REMATCH[1]}
    elif [[ "$time_str" =~ ([0-9]+)[[:space:]]+hour ]]; then
      time_min=$(( ${BASH_REMATCH[1]} * 60 ))
    elif [[ "$time_str" =~ ([0-9]+)[[:space:]]+day ]]; then
      time_min=$(( ${BASH_REMATCH[1]} * 24 * 60 ))
    fi

    # Compare time
    if (( time_min > 30 )); then
      commit=$(curl -sL "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'a:contains("Updating trunk VERSION from") attr{href}' | head -1)
    else
      commit=$(curl -sL "https://chromium.googlesource.com/chromium/src/+log?n=$n" | pup 'a:contains("Updating trunk VERSION from") attr{href}' | head -2 | tail -1)
    fi
    baseCommitURL="https://chromium.googlesource.com"
    diff=$(curl -sL "$baseCommitURL${commit}" | pup 'span.DiffTree-action--modify a attr{href}' | head -1) && diffGit=$(curl -sL "$baseCommitURL${diff}" | pup 'pre.Diff-unified text{}')
    major=$(grep -E '^\s*MAJOR=' <<< "$diffGit" | head -1 | cut -d'=' -f2)
    [ -z "$major" ] && major=$(grep -E '^\+MAJOR=' <<< "$diffGit" | head -1 | cut -d'=' -f2)
    minor=$(grep -E '^\s*MINOR=' <<< "$diffGit" | head -1 | cut -d'=' -f2)
    build=$(grep -E '^\+BUILD=' <<< "$diffGit" | head -1 | cut -d'=' -f2)
    patch=$(grep -E '^\s*PATCH=' <<< "$diffGit" | head -1 | cut -d'=' -f2)
    crVersion="${major}.${minor}.${build}.${patch}"
  fi
  
  ([ "$crVersion" == " . . . " ] || [ -z "$crVersion" ]) && crVersion=$(jq -r '.[0].version' <<< "$branchData" | sed -E -e 's/^([0-9]{2})([0-9])/\1X/' -e 's/([0-9])([0-9]{3})\.[0-9]+/\1XXX.X/')
  printf "\r\033[K"

  echo -e "\n$info Last Chromium Canary Test version: $crVersion at branch position: $branchPosition"
  fetchValidSnapshot
}

[ -n "$crup" ] && return 0

[ $printArt == true ] && { printf '\033[?25l' && print_crdl && sleep 3 && printf '\033[?25h'; }

while true; do
  option=""
  [ $isMacOS == true ] && { options=(Extended); descriptions=("Releases every 8 weeks"); } || { options=(); descriptions=(); }
  options+=("Stable" "Beta" "Dev" "Canary" "Canary Test" "Settings")
  descriptions+=("Releases every 2 weeks" "Releases weekly" "Releases twice a week" "Releases twice daily" "Releases every hour" "crdl Settings")
  if [ $isAndroid == true ] && [ $foundTermuxAPI == true ] && [ $GUI == true ]; then
    printf '\033[2J\033[3J\033[H'  # clear Terminal
    print_crdl  # print crdl logo
    if [ -f "$crdlJson" ] && jq -e 'has("INSTALLED_POSITION")' "$crdlJson" >/dev/null 2>&1; then
      while true; do
        termux-toast -g top -b white -c black "↓ $appVersion - $appSize - $installedTime"
        sleep 3  # wait for toast disappear
      done &  # run in background
      toast_pid=$!  # get toast process id
    fi
    button_index=""  # reset (clear) index value to empty
    button_index=$(termux-dialog radio -t "Select" -v "Stable,Beta,Dev,Canary,Canary Test,Settings,Exit" | jq -r .index)  # show radio button popup dialog
    [ -n $toast_pid ] && kill $toast_pid 2>/dev/null  # stop toast process
    # show Selected button name using toast
    if [ "$button_index" != "null" ]; then  # if usr chose cancel or ok then index == null
      options+=("Exit")
      option="${options[button_index]}"  # select index pos value by index num
      [ "$option" == "Exit" ] && termux-toast "Script exited !!" || termux-toast "Selected: $option"  # show toast messages
    fi
  else
    for i in "${!options[@]}"; do [ "${options[i]}" == "$Channel" ] && selected_options=$i; done
    menu "options" "eButtons" "descriptions" "" "$selected_options" && option="${options[selected]}"
  fi
  case "$option" in
    Extended) fetchReleases "Extended" ;;
    Stable) fetchReleases "Stable" ;;
    Beta) fetchReleases "Beta" ;;
    Dev) fetchReleases "Dev" ;;
    Canary) fetchReleases "Canary" ;;
    Canary\ Test) fetchPreReleases ;;
    Settings)
      selected_settings=0
      while true; do
        sOptions=(printArt AutoUpdatesScript AutoUpdatesDependencies CheckUpdates About SchedulerUpdateChromium TimerTriggerUpdateChromium UpdateChromiumAtBoot Uninstall SourceCode Donate YouTube)
        sDescriptions=(ShowScriptBrandingOnLaunch AutoUpdatesScriptOnLaunch AutoUpdatesDependenciesOnLaunch ManuallyUpdatingScript PrintScriptVersion SchedulerUpdateChromiumInterval TimerTriggerUpdateChromium UpdateChromiumAtBoot UninstallScript github.com/arghya339/crdl "paypalme/arghyadeep339" "youtube/@mrpalash360")
        ([ "$Scheduler" != "None" ] || [ "$Timer" != "None" ] || [ $Boot == true ]) && { sOptions+=(ChromiumUpdateBackgroundServiceType); sDescriptions+=(ChromiumUpdateBackgroundServiceType); }
        if [ $isAndroid == true ] && [ "$arch" == "arm64-v8a" ]; then
          sOptions+=(AndroidDesktop); sDescriptions+=("Install Extensions supported AndroidDesktop Chromium")
          [ $memTotalGB -le 4 ] && { sOptions+=(Prefer32bitApk); sDescriptions+=("Prefer 32-bit apk if device is usually low on memory (lessthen 4GB RAM)"); }
        fi
        sOptions+=(DeleteDownloadedFileAfterInstallation Downloader)
        sDescriptions+=(RemoveDownloadedFileAfterInstallation Downloader)
        [ $isAndroid == true ] && { sOptions+=(Experiments GUI AutoUpdatesTermux Share); sDescriptions+=("chrome://flags/" GraphicalUserInterface AutoUpdatesTermuxOnLaunch ShareScript); }
        menu sOptions bButtons sDescriptions "" $selected_settings && selected_settings=$selected || break
        case "${sOptions[selected]}" in
          printArt)
            confirmPrompt "Show crdl branding on launch" tfButtons "$printArt" && printArt=true || printArt=false
            config "printArt" "$printArt"
            ;;
          AutoUpdatesScript)
            confirmPrompt "Auto updates Script on launch" tfButtons "$AutoUpdatesScript" && autoupdates=true || autoupdates=false
            config "AutoUpdatesScript" "$autoupdates"
            reloadConfig
            ;;
          AutoUpdatesDependencies)
            confirmPrompt "Auto updates dependencies on launch" tfButtons "$AutoUpdatesDependencies" && autoupdates=true || autoupdates=false
            config "AutoUpdatesDependencies" "$autoupdates"
            reloadConfig
            ;;
          CheckUpdates) checkInternet && { updates; dependencies; } ;;
          About)
            printf '\033[?25l' && print_crdl
            echo "Script Version   : $localVersion"
            if jq -e 'has("INSTALLED_POSITION")' "$crdlJson" &>/dev/null; then
              echo "Channel          : $Channel"
              [ $isAndroid == true ] && echo "App Version      : $appVersion ($appVCode)" || echo "App Version      : $appVersion"
              echo "App Size         : $appSize"
              echo "Installation Time: $installedTime"
            fi
            echo; read -p "Press Enter to continue..."; printf '\033[?25h'
            ;;
          DeleteDownloadedFileAfterInstallation)
            confirmPrompt "DeleteDownloadedFileAfterInstallation" tfButtons "$RmDlFile" && RmDlFile=true || RmDlFile=false
            config "RmDlFile" "$RmDlFile"
            ;;
          Downloader)
            [ "$Downloader" == "curl" ] && defaultButton=0 || defaultButton=1
            buttons=("<curl>" "<aria2>"); confirmPrompt "Downloader" buttons "$defaultButton" && Downloader=curl || Downloader=aria2
            config "Downloader" "$Downloader"
            ;;
          AndroidDesktop)
            [ "$AndroidDesktop" == "yes" ] && defaultButton=0 || defaultButton=1
            confirmPrompt "AndroidDesktop" ynButtons "$defaultButton" && AndroidDesktop=yes || AndroidDesktop=no
            config "AndroidDesktop" "$AndroidDesktop"
            ;;
          Prefer32bitApk)
            confirmPrompt "Prefer32bitApk" tfButtons "$Prefer32bitApk" && Prefer32bitApk=true || Prefer32bitApk=false
            config "Prefer32bitApk" "$Prefer32bitApk"
            ;;
          GUI)
            confirmPrompt "GUI" tfButtons "$GUI" && { GUI=true; installTermuxAPI; } || GUI=false
            config "GUI" "$GUI"
            ;;
          AutoUpdatesTermux)
            confirmPrompt "Auto updates Termux on launch" tfButtons "$AutoUpdatesTermux" && AutoUpdatesTermux=true || AutoUpdatesTermux=false
            config "AutoUpdatesTermux" "$AutoUpdatesTermux"
            reloadConfig
            ;;
          SchedulerUpdateChromium)
            case "$Scheduler" in
              15min) selected_options=1 ;;
              30min) selected_options=2 ;;
              1h) selected_options=3 ;;
              3h) selected_options=4 ;;
              6h) selected_options=5 ;;
              9h) selected_options=6 ;;
              12h) selected_options=7 ;;
              *) selected_options=0 ;;
            esac
            SchedulerOpt=(None 15min 30min 1h 3h 6h 9h 12h)
            SchedulerDesc=("Don'tCheck" CheckEvery15Minutes CheckEvery30Minutes CheckEvery1Hours CheckEvery3Hours CheckEvery6Hours CheckEvery9Hours CheckEvery12Hours)
            if menu SchedulerOpt bButtons SchedulerDesc "" $selected_options; then
              config "Scheduler" "${SchedulerOpt[selected]}"
              reloadConfig
              if [ "$Scheduler" == "None" ]; then
                if [ $isAndroid == true ]; then
                  termux-job-scheduler --cancel --job-id 1993615810
                elif [ $isMacOS == true ]; then
                  if [ "$Timer" == "None" ] && [ "$Boot" == false ]; then
                    launchctl unload $HOME/Library/LaunchAgents/com.${USER}.crup.plist
                    launchctl remove com.${USER}.crup
                    rm -f $HOME/Library/LaunchAgents/com.${USER}.crup.plist
                  else
                    LaunchAgents
                  fi
                elif [ $isFedora == true ]; then
                  if [ "$Timer" == "None" ]; then
                    sudo systemctl disable --now crup.timer
                    sudo rm -f /etc/systemd/system/crup.timer
                    if [ "$Boot" == false ]; then
                      sudo systemctl disable --now crup.service
                      sudo rm -f /etc/systemd/system/crup.service
                    fi
                    sudo systemctl daemon-reload
                  else
                    systemdService
                  fi
                fi
              else
                case "${SchedulerOpt[selected]}" in
                  15min) SchedulerS=$((60 * 15)) ;;
                  30min) SchedulerS=$((60 * 30)) ;;
                  1h) SchedulerS=$((60 * 60)) ;;
                  3h) SchedulerS=$((60 * 60 * 3)) ;;
                  6h) SchedulerS=$((60 * 60 * 6)) ;;
                  9h) SchedulerS=$((60 * 60 * 9)) ;;
                  12h) SchedulerS=$((60 * 60 * 12)) ;;
                esac
                SchedulerMS=$((SchedulerS * 1000))
                if [ $isAndroid == true ]; then
                  SchedulerUpdateChromium "$SchedulerMS"
                elif [ $isMacOS == true ]; then
                  LaunchAgents
                elif [ $isFedora == true ]; then
                  systemdService
                fi
              fi
            fi
            ;;
          TimerTriggerUpdateChromium)
            [ "$Timer" == "None" ] && selected_buttons=0 || selected_buttons=1 
            TimerButtons=(None Trigger); confirmPrompt "TimerTrigger" TimerButtons "$selected_buttons" && TimerOpt=None || TimerOpt=Trigger
            if [ "$TimerOpt" == "None" ]; then
              if [ $isAndroid == true ]; then
                sv down crond
                (crontab -l | grep -v "crup.sh") | crontab -
                pkill crond
                termux-wake-unlock
              elif [ $isMacOS == true ]; then
                if [ "$Scheduler" == "None" ] && [ "$Boot" == false ]; then
                  launchctl unload $HOME/Library/LaunchAgents/com.${USER}.crup.plist
                  launchctl remove com.${USER}.crup
                  rm -f $HOME/Library/LaunchAgents/com.${USER}.crup.plist
                else
                  LaunchAgents
                fi
              elif [ $isFedora == true ]; then
                if [ "$Scheduler" == "None" ]; then
                  sudo systemctl disable --now crup.timer
                  sudo rm -f /etc/systemd/system/crup.timer
                  if [ "$Boot" == false ]; then
                    sudo systemctl disable --now crup.service
                    sudo rm -f /etc/systemd/system/crup.service
                  fi
                  sudo systemctl daemon-reload
                else
                  systemdService
                fi
              fi
              config "Timer" "None"
              reloadConfig
            else
              read -r -p "Timer(24-Hour): " -i "$(date "+%H:%M")" -e Time
              [ -z "$Time" ] && Time="None"
              if [ "$Time" != "None" ]; then
                config "Timer" "$Time"
                reloadConfig
                if [ $isAndroid == true ]; then
                  TimerTriggerUpdateChromium "$Time"
                elif [ $isMacOS == true ]; then
                  LaunchAgents
                elif [ $isFedora == true ]; then
                  systemdService
                fi
              fi
            fi
            ;;
          UpdateChromiumAtBoot)
            confirmPrompt "UpdateChromiumAtBoot" tfButtons "$Boot" && Boot=true || Boot=false
            config "Boot" "$Boot"
            reloadConfig
            if [ "$Boot" == true ]; then
              if [ $isAndroid == true ]; then
                UpdateChromiumAtBoot
              elif [ $isMacOS == true ]; then
                LaunchAgents
              elif [ $isFedora == true ]; then
                systemdService
              fi
            else
              if [ $isAndroid == true ]; then
                rm -f ~/.termux/boot/crup
              elif [ $isMacOS == true ]; then
                if [ "$Scheduler" == "None" ] && [ "$Timer" == "None" ]; then
                  launchctl unload $HOME/Library/LaunchAgents/com.${USER}.crup.plist
                  launchctl remove com.${USER}.crup
                  rm -f $HOME/Library/LaunchAgents/com.${USER}.crup.plist
                else
                  LaunchAgents
                fi
              elif [ $isFedora == true ]; then
                if [ "$Scheduler" == "None" ] && [ "$Timer" == "None" ]; then
                  sudo systemctl disable --now crup.service
                  sudo rm -f /etc/systemd/system/crup.service
                  sudo systemctl daemon-reload
                else
                  systemdService
                fi
              fi
            fi
            ;;
          ChromiumUpdateBackgroundServiceType)
            [ "$crupBgServiceType" == "Notification" ] && selected_buttons=1 || selected_buttons=0
            buttons=("<Update>" "<Notification>"); confirmPrompt "ChromiumUpdateBackgroundServiceType" "buttons" "$selected_buttons" && crupBgServiceType="Update" || crupBgServiceType="Notification"
            ([ $isAndroid == true ] && [ "$crupBgServiceType" == "Notification" ]) && installTermuxAPI
            config "crupBgServiceType" "$crupBgServiceType"
            ;;
          Experiments)
            selected_flag=0
            Experiments=("Open incognito tabs in new window = Disabled" "Reader Mode distillation in app = Disabled" "Omnibox Multiline edit field = Enabled For Autocompte" "Search in Settings = Disabled" "New tab page customization toolbar button = Enabled")
            Flags=("chrome://flags/#android-open-incognito-as-window" "chrome://flags/#reader-mode-distill-in-app" "chrome://flags/#omnibox-multiline-edit-field" "chrome://flags/#search-in-settings" "chrome://flags/#new-tab-page-customization-toolbar-button")
            while true; do
              menu Experiments bButtons Flags "" $selected_flag && selected_flag=$selected || break
              if [ $isAndroid == true ]; then termux-open-url "${Flags[selected_flag]}"; elif [ $isMacOS == true ]; then open "${Flags[selected_flag]}"; else xdg-open "${Flags[selected_flag]}"; fi
            done
            ;;
          Uninstall)
            confirmPrompt "Are you sure you want to uninstall crdl?" "ynButtons" "1" && response=Yes || response=No
            case "$response" in
              Yes)
                echo -ne "${Red}Type 'yes' in capital to continue: ${Reset}" && read -r userInput
                case "$userInput" in
                  YES)
                    [ -d "$crdl" ] && rm -rf "$crdl"
                    [ -f "$USER_HOME/.crdl.sh" ] && rm -f "$USER_HOME/.crdl.sh"
                    if [ $isAndroid == true ]; then
                      [ -f "$PREFIX/bin/crdl" ] && rm -f "$PREFIX/bin/crdl"
                      [ -f "$HOME/.shortcuts/crdl" ] && rm -f "$HOME/.shortcuts/crdl"
                      [ -f "$HOME/.termux/widget/dynamic_shortcuts/crdl" ] && rm -f "$HOME/.termux/widget/dynamic_shortcuts/crdl"
                      [ -f "$PREFIX/bin/crup" ] && rm -f "$PREFIX/bin/crup"
                      [ -f "$HOME/.shortcuts/crup" ] && rm -f "$HOME/.shortcuts/crup"
                      [ -f "$HOME/.termux/widget/dynamic_shortcuts/crup" ] && rm -f "$HOME/.termux/widget/dynamic_shortcuts/crup"
                    elif [ $isMacOS == true ]; then
                      [ -f "/usr/local/bin/crdl" ] && rm -f "/usr/local/bin/crdl"
                      [ -d "/Applications/crdl.app/" ] && rm -rf "/Applications/crdl.app/"
                      [ -f "/usr/local/bin/crup" ] && rm -f "/usr/local/bin/crup"
                      [ -d "/Applications/crup.app/" ] && rm -rf "/Applications/crup.app/"
                    else
                      [ -f "/usr/local/bin/crdl" ] && sudo rm -f "/usr/local/bin/crdl"
                      [ -f "$USER_HOME/.local/share/applications/crdl.desktop" ] && rm -f "$USER_HOME/.local/share/applications/crdl.desktop"
                      [ -f "/usr/local/bin/crup" ] && sudo rm -f "/usr/local/bin/crup"
                      [ -f "$USER_HOME/.local/share/applications/crup.desktop" ] && rm -f "$USER_HOME/.local/share/applications/crup.desktop"
                    fi
                    confirmPrompt "Do you want to remove this script-related dependency?" "ynButtons" "1" && response=Yes || response=No
                    case "$response" in
                      Yes)
                        if [ $isAndroid == true ]; then
                          pkgUninstall "aria2"
                          pkgUninstall "jq"
                          pkgUninstall "pup"
                          pkgUninstall "bsdtar"
                          pkgUninstall "pv"
                        elif [ $isMacOS == true ]; then
                          formulaeUninstall "aria2"
                          formulaeUninstall "jq"
                          formulaeUninstall "pup"
                          formulaeUninstall "pv"
                        elif [ $isFedora == true ]; then
                          dnfRemove "curl"
                          dnfRemove "aria2"
                          dnfRemove "jq"
                          dnfRemove "bsdtar"
                          dnfRemove "pv"
                        fi
                        ;;
                    esac
                    confirmPrompt "Do you want to uninstall Chromium from this Device?" "ynButtons" "1" && response=Yes || response=No
                    case "$response" in
                      Yes)
                        if [ $isMacOS == true ]; then
                          sudo rm -rf /Applications/Chromium.app
                        elif [ $isAndroid == true ]; then
                          am start -a android.intent.action.UNINSTALL_PACKAGE -d package:org.chromium.chrome &>/dev/null
                        else
                          rm -rf /opt/$crZIP/
                          sudo rm -f /usr/local/bin/chromium
                        fi
                        ;;
                    esac
                    printf '\033[2J\033[3J\033[H'
                    echo -e "$good ${Yellow}crdl has been uninstalled successfully :(${Reset}"
                    echo -e "💔 ${Yellow}We're sorry to see you go. Feel free to reinstall anytime!${Reset}"
                    if [ $isAndroid == true ]; then
                      termux-open "https://github.com/arghya339/crdl"
                    elif [ $isMacOS == true ]; then
                      open "https://github.com/arghya339/crdl"
                    else
                      xdg-open "https://github.com/arghya339/crdl"
                    fi
                    exit 0
                    ;;
                esac
                ;;
            esac
            ;;
          SourceCode)
            if [ $isAndroid == true ]; then
              termux-open-url "https://github.com/arghya339/crdl"
            elif [ $isMacOS == true ]; then
              open "https://github.com/arghya339/crdl"
            else
              xdg-open "https://github.com/arghya339/crdl"
            fi
            ;;
          Donate)
            DonateURL="https://www.paypal.com/paypalme/arghyadeep339"
            if [ $isAndroid == true ]; then termux-open-url "$DonateURL"; elif [ $isMacOS == true ]; then open "$DonateURL"; else xdg-open "$DonateURL" &>/dev/null; fi
            ;;
          YouTube)
            YouTubeURL="https://www.youtube.com/@mrpalash360?sub_confirmation=1"
            if [ $isAndroid == true ]; then termux-open-url "$YouTubeURL"; elif [ $isMacOS == true ]; then open "$YouTubeURL"; else xdg-open "$YouTubeURL" &>/dev/null; fi
            ;;
          Share) am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "https://github.com/arghya339/crdl" >/dev/null ;;
        esac
      done
      ;;
    Exit)
      if [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties"; fi
      clear  # clear Termianl
      [ $foundTermuxAPI == true ] && option=""
      [ $foundTermuxAPI == true ] && termux-api-stop &>/dev/null
      break  # break the loop
      ;;
    *) ([ $isAndroid == true ] && [ $foundTermuxAPI == true ]) && { termux-toast -g bottom "Invalid selection! Please select a valid options."; sleep 0.5; } ;;
  esac
done
###############################################################################################################################################################