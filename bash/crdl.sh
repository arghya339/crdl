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
  isMacOS=true; isAndroid=false
elif [[ -d "/sdcard" ]] && [[ -d "/system" ]]; then
  isAndroid=true; isMacOS=false
fi

crdl="$HOME/.crdl"
[ $isAndroid == true ] && Download="/sdcard/Download" || Download="$HOME/Downloads"
mkdir -p $crdl
crdlJson="$crdl/crdl.json"
read rows cols < <(stty size)
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

[ $isAndroid == true ] && scripts=(Termux)
[ $isMacOS == true ] && scripts=(macOS)
scripts+=(menu confirmPrompt)

run() {
  for ((c=0; c<${#scripts[@]}; c++)); do
    source $crdl/${scripts[c]}.sh
  done
}

[ -f "$crdl/.version" ] && localVersion=$(cat "$crdl/.version") || localVersion=
checkInternet &>/dev/null && remoteVersion=$(curl -sL "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/.version") || remoteVersion="$localVersion"
updates() {
  curl -sL -o "$crdl/.version" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/.version"
  curl -sL -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/crdl.sh"
  curl -sL -o $crdl/menu.sh https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/next/bash/menu.sh
  curl -sL -o $crdl/confirmPrompt.sh https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/next/bash/confirmPrompt.sh
  if [ $isAndroid == true ]; then
    [ ! -f "$PREFIX/bin/crdl" ] && ln -s ~/.crdl.sh $PREFIX/bin/crdl
  elif [ $isMacOS == true ]; then
    [ ! -f "/usr/local/bin/crdl" ] && ln -s $HOME/.crdl.sh /usr/local/bin/crdl
  fi
  [ ! -x $HOME/.crdl.sh ] && chmod +x $HOME/.crdl.sh
  curl -sL -o "$crdl/${scripts[0]}.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/bash/${scripts[0]}.sh"
  for ((c=0; c<${#scripts[@]}; c++)); do
    source $crdl/${scripts[c]}.sh
  done
}
[ -f "$crdl" ] && AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$crdlJson" 2>/dev/null) || AutoUpdatesScript=true
if [ "$AutoUpdatesScript" == true ]; then
  [ "$remoteVersion" != "$localVersion" ] && { checkInternet && updates && localVersion="$remoteVersion"; } || run
else
  run
fi

all_key=(AutoUpdatesScript AutoUpdatesDependencies)
all_value=(true true)
for i in "${!all_key[@]}"; do
  ! jq -e --arg key "${all_key[i]}" 'has($key)' "$crdlJson" &>/dev/null && config "${all_key[i]}" "${all_value[i]}"
done

reloadConfig() {
  if [ -f "$crdlJson" ]; then
    AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$crdlJson" 2>/dev/null)
    AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$crdlJson" 2>/dev/null)
  else
    AutoUpdatesScript=true
    AutoUpdatesDependencies=true
  fi
}

print_crdl() {
  printf "${Blue}     https://github.com/arghya339/crdl${Reset}\n"                                               
  printf "${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}    _/  ${Reset} ${Cyan}         _/  _/${Reset}\n"   
  printf "${skyBlue}    _/_/_/${Reset}${Blue}  _/  _/_/${Reset}  ${White}     _/ ${Reset} ${Cyan}    _/_/_/  _/ ${Reset}\n"   
  printf "${skyBlue} _/      ${Reset}${Blue}  _/_/     ${Reset}  ${White}      _/${Reset} ${Cyan} _/    _/  _/  ${Reset}\n"   
  printf "${skyBlue}_/       ${Reset}${Blue} _/        ${Reset}  ${White}   _/   ${Reset} ${Cyan}_/    _/  _/   ${Reset}\n"   
  printf "${skyBlue} _/_/_/  ${Reset}${Blue}_/         ${Reset}  ${White}_/      ${Reset} ${Cyan} _/_/_/  _/    ${Reset}\n"   
  printf "${skyBlue}         ${Reset}${Blue}           ${Reset}  ${White}        ${Reset} ${Cyan}               ${Reset}\n"   
  printf "${White}𝒟𝑒𝓋𝑒𝓁𝑜𝓅𝑒𝓇: @𝒶𝓇𝑔𝒽𝓎𝒶𝟥𝟥𝟫 ${Reset}${Blue} ${Reset} ${White}_/_/_/_/_/${Reset}${Cyan}               ${Reset}\n"
  echo
}

LAST_CHANGE=$(curl -sL "$branchURL/$snapshotPlatform/LAST_CHANGE")
installedPosition=$(jq -r '.INSTALLED_POSITION' "$crdlJson" 2>/dev/null)
installedVersion=$(jq -r '.INSTALLED_VERSION' "$crdlJson" 2>/dev/null)
appSize=$(jq -r '.APP_SIZE' "$crdlJson" 2>/dev/null)
if [ $isAndroid == true ]; then
  appVersion=$(jq -r '.APP_VERSION' "$crdlJson" 2>/dev/null)
elif [ $isMacOS == true ]; then
  [ -d /Applications/Chromium.app ] && appVersion=$(/Applications/Chromium.app/Contents/MacOS/Chromium --version)
fi
installedTime=$(jq -r '.INSTALLED_TIME' "$crdlJson" 2>/dev/null)

# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  printf '\033[2J\033[3J\033[H'  # clear aria2 multi error log from console
  print_crdl  # print crdl logo
  [ -n "$appVersion" ] && echo -e "$info INSTALLED: Chromium v$appVersion - $appSize - $installedTime\n"
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
  config "INSTALLED_POSITION" "$branchPosition"
  config "INSTALLED_VERSION" "$crVersion"
  [ $isAndroid == true ] && { config "APP_VERSION" "$appVersion"; config "APP_VCODE" "$appVersionCode"; }
  config "APP_SIZE" "$crSize"
  config "INSTALLED_TIME" "$(date "+%Y-%m-%d %H:%M")"
  rm -rf "$Download/$crZIP/"
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
  fi

  if [ $isAndroid == true ] && [ $foundTermuxAPI == true ]; then
    opt=$(termux-dialog confirm -t "Install Chromium" -i "Do you want to install Chromium v$appVersion?" | jq -r '.text')
  else
    echo; confirmPrompt "Do you want to install Chromium v$appVersion?" "ynButtons" && opt=yes || opt=no
  fi

  case "$opt" in
    yes)
      appInstall "$appPath"
      if [ $isAndroid == true ] && ! jq -e 'has("INSTALLED_POSITION")' "$crdlJson" &>/dev/null && [ "$AndroidDesktop" == "yes" ]; then
        curl -L --progress-bar -C - -o "$crdl/top-30.sh" "https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-30.sh" && bash "$crdl/top-30.sh" && rm "$crdl/top-30.sh"
      elif [ $isMacOS == true ] || [ ! -d "/Applications/Chromium.app" ]; then
        curl -L --progress-bar -C - -o "$crdl/top-50.sh" "https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-50.sh" && bash "$crdl/top-50.sh" && rm -f "$crdl/top-50.sh"
      fi
      if [ $isAndroid == false ] || { [ $isAndroid == true ] && { [ $su == true ] || "$HOME/rish" -c "id" >/dev/null 2>&1 || "$HOME/adb" -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; }; }; then
        [ $installStatus -eq 0 ] && { echo -e "$good Successfully installed."; mkConfig; } || { echo -e "$bad Installation failed!"; sleep 1; }
      else
        mkConfig
      fi
      ;;
    no)
      ([ $isAndroid == true ] && [ $foundTermuxAPI == true ]) && termux-toast "Chromium installation skipped!" || echo -e "$notice Chromium installation skipped!"
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
    if [ "$channel" == "Extended" ] || [ "$channel" == "Stable" ] || [ "$channel" == "Beta" ] || [ "$channel" == "Dev" ]; then
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
      fi
      installPrompt "$appPath"
      break  # break the resuming download loop
    else
      ([ "$channel" == "Canary" ] || [ "$channel" == "Canary Test" ]) && aria2ConsoleLogHide  # for aria2
    fi
    echo -e "$notice Download failed! retrying in 5 seconds.." && sleep 5  # wait 5 seconds
  done
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
      dl "$dlURL"
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
        dl "$snapshotURL"
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

while true; do
  option=""
  [ $isAndroid == true ] && options=() || options=(Extended)
  options+=("Stable" "Beta" "Dev" "Canary" "Canary Test")
  if [ $isAndroid == true ] && [ $foundTermuxAPI == true ]; then
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
    button_index=$(termux-dialog radio -t "Select" -v "Stable,Beta,Dev,Canary,Canary Test,Quit" | jq -r .index)  # show radio button popup dialog
    [ -n $toast_pid ] && kill $toast_pid 2>/dev/null  # stop toast process
    # show Selected button name using toast
    if [ "$button_index" != "null" ]; then  # if usr chose cancel or ok then index == null
      options+=("Quit")
      option="${options[button_index]}"  # select index pos value by index num
      [ "$option" == "Quit" ] && termux-toast "Script exited !!" || termux-toast "Selected: $option"  # show toast messages
    fi
  else
    menu "options" "eButtons" && option="${options[selected]}"
  fi
  case "$option" in
    Extended) fetchReleases "Extended" ;;
    Stable) fetchReleases "Stable" ;;
    Beta) fetchReleases "Beta" ;;
    Dev) fetchReleases "Dev" ;;
    Canary) fetchReleases "Canary" ;;
    Canary\ Test) fetchPreReleases ;;
    Quit)
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