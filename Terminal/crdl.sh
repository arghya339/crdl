#!/usr/bin/env bash

shopt -s extglob  # Enable extended glob patterns at top of this script

# Chromium is an open-source browser project, developed and maintained by Google
# Easy Script to download and run latest Chromium macOS build
# Use: ~ curl -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Terminal/crdl.sh" && bash "$HOME/.crdl.sh"
# Developer github.com/arghya339

# --- Downloading latest crdl.sh file from GitHub ---
curl -sL -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Terminal/crdl.sh"

if [ ! -f "/usr/local/bin/crdl" ]; then
  ln -s $HOME/.crdl.sh /usr/local/bin/crdl  # symlink (shortcut of .crdl.sh)
fi
chmod +x $HOME/.crdl.sh  # give execute permission to crdl

# --- Define ANSI color codes ---
Green="\033[92m"
Red="\033[91m"
Blue="\033[94m"
skyBlue="\033[38;5;117m"
Cyan="\033[96m"
White="\033[37m"
whiteBG="\e[47m\e[30m"
Yellow="\033[93m"
Orange="\e[38;5;208m"
Reset="\033[0m"

# --- Colored log indicators ---
good="\033[92;1m[✔]\033[0m"
bad="\033[91;1m[✘]\033[0m"
info="\033[94;1m[i]\033[0m"
running="\033[37;1m[~]\033[0m"
notice="\033[93;1m[!]\033[0m"
question="\033[93;1m[?]\033[0m"

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

# --- Checking Internet Connection ---
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
  echo -e "$bad ${Red}Oops! No Internet Connection available. \nConnect to the Internet and try again later.${Reset}"
  exit 1
fi

# --- Global Variables ---
productVersion=$(sw_vers -productVersion | cut -d '.' -f 1)  # get macOS major version
cloudflareDOH="https://cloudflare-dns.com/dns-query"
cloudflareIP="1.1.1.1,1.0.0.1"
if [ -d "/Applications/Cloudflare WARP.app" ]; then
  warp_cli="/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli"
  warpCliStatus=$("$warp_cli" status | head -1 | awk '{printf "%s\n", $3}' 2>/dev/null)
fi
crdlJson="$HOME/.crdl.json"  # json file to store crdl related data
installedPosition=$(jq -r '.INSTALLED_POSITION' "$crdlJson" 2>/dev/null)
installedVersion=$(jq -r '.INSTALLED_VERSION' "$crdlJson" 2>/dev/null)
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"
# Detect platform (Intel or ARM)
if [[ $(uname -m) == "x86_64" ]]; then
  snapshotPlatform="Mac"  # For Intel (x86_64) 
else
  snapshotPlatform="Mac_Arm"  # For Apple Silicon (ARM64)
fi
LAST_CHANGE=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")
appSize=$(jq -r '.APP_SIZE' "$crdlJson" 2>/dev/null)
[ -d /Applications/Chromium.app ] && appVersion=$(/Applications/Chromium.app/Contents/MacOS/Chromium --version)
installedTime=$(jq -r '.INSTALLED_TIME' "$crdlJson" 2>/dev/null)
# --- Check OS version ---
if [ $productVersion -le 10 ]; then
  echo -e "${bad} ${Red}macOS $productVersion is not supported by Chromium.${Reset}"  # Chromium required macOS 10.14+ (Catalina)
  exit 1
fi

printf '\033[2J\033[3J\033[H'; echo -e "🚀 ${Yellow}Please wait! starting crdl...${Reset}"

# --- Check if brew is installed ---
if brew --version >/dev/null 2>&1; then
  brew update > /dev/null 2>&1
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1
fi
formulaeList=$(brew list 2>/dev/null)
outdatedFormulae=$(brew outdated 2>/dev/null)

# --- formulae upgrade function ---
formulaeUpdate() {
  local formulae=$1
  if echo "$outdatedFormulae" | grep -q "^$formulae" 2>/dev/null; then
    echo -e "$running Upgrading $formulae formulae.."
    brew upgrade "$formulae" > /dev/null 2>&1
  fi
}

# --- formulae install/update function ---
formulaeInstall() {
  local formulae=$1
  if echo "$formulaeList" | grep -q "$formulae" 2>/dev/null; then
    formulaeUpdate "$formulae"
  else
    echo -e "$running Installing $formulae formulae.."
    brew install "$formulae" > /dev/null 2>&1
  fi
}

formulaeInstall "bash"  # bash update
formulaeInstall "grep"  # grep update
formulaeInstall "curl"  # curl update
formulaeInstall "aria2"  # aria2 install/update
formulaeInstall "jq"  # jq install/update
#formulaeInstall "libarchive"  # libarchive (brew version of bsdtar: macOS's system utilities) install/update
formulaeInstall "pv"  # pv install/update
formulaeInstall "pup"  # pup install/update

# Get active interfaces (those with 'status: active')
active_ifaces=$(ifconfig | awk '/^[a-z]/ { iface=$1; sub(":", "", iface) } /status: active/ { print iface }')

# Build list of active service names based on active interfaces
active_services=()
while IFS= read -r device; do
  service=$(networksetup -listnetworkserviceorder | awk -v dev="$device" '$0 ~ "Device: " dev { sub(/^.*\) /, "", prev); print prev } { prev = $0 }')
  [ -n "$service" ] && active_services+=("$service")
done <<< "$active_ifaces"

# Get all network services (remove header and leading '*')
all_services=$(networksetup -listallnetworkservices | tail -n +2 | sed 's/^\* //')

# Build list of inactive services, excluding VPN/Proxy by name pattern
inactive_services=()
while IFS= read -r svc; do
  # Skip if service is active
  skip_active=
  for active in "${active_services[@]}"; do
    [[ "$svc" == "$active" ]] && skip_active=1 && break
  done
  [ -n "$skip_active" ] && continue

  # Skip VPN/Proxy related services by name
  if [[ "$svc" == *"VPN"* || "$svc" == *"Proxy"* || "$svc" == wg-* ]]; then
    continue
  fi

  inactive_services+=("$svc")
done <<< "$all_services"

# Convert arrays to comma-separated strings for display
active_list=$(IFS=, ; echo "${active_services[*]}")
inactive_list=$(IFS=, ; echo "${inactive_services[*]}")

config() {
  local key="$1"
  local value="$2"
  
  if [ ! -f "$crdlJson" ]; then
    jq -n "{}" > "$crdlJson"
  fi
  
  jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$crdlJson" > temp.json && mv temp.json "$crdlJson"
}

# --- install Chromium function ---
crInstall() {
  local appPath=$1

  if [ -d "/Applications/Chromium.app" ]; then
    osascript -e 'quit app "Chromium"'  # Close Chromium if running
    sudo cp -R $appPath /Applications/ 2>/dev/null && { rm -rf "$HOME/chrome-mac"; open -a "Chromium"; }  # Copy with replace an app & open Chromium app after update
  else
    sudo cp -Rn $appPath /Applications/ 2>/dev/null && { rm -rf "$HOME/chrome-mac"; open -a "Chromium"; }  # Skips if already exists
    curl -L --progress-bar -o "$HOME/top-50.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-50.sh && bash "$HOME/top-50.sh" && rm -f "$HOME/top-50.sh"
  fi
  echo -e "$good $actualVersion successfully installed!"; sleep 3
}

# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  printf '\033[2J\033[3J\033[H'  # clear aria2 multi error log from console
  print_crdl  # call the print_crdl function 
  if [ -d /Applications/Chromium.app ]; then
    echo -e "$info INSTALLED: $appVersion - $appSize - $installedTime" && echo
  fi
  echo -e "Navigate with [↑] [↓] [←] [→] || Select with [↵]\n"
  for ((i=0; i<=$((${#options[@]} - 1)); i++)); do
    if [ $i -eq $channel ]; then
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

# Y/n prompt function
confirmPrompt() {
  Prompt=${1}
  local -n prompt_buttons=$2
  Selected=${3:-0}  # :- set value as 0 if unset
  maxLen=70
  
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

installPrompt () {
  local appPath=$1

  chmod -R +x $appPath && actualVersion=$($appPath/Contents/MacOS/Chromium --version 2>/dev/null)
  crSize=$(du -sk "$appPath" | awk '{total_bytes = $1 * 1024; printf "%.2f MB\n", total_bytes / 1000000}')
  buttons=("<Yes>" "<No>"); echo; confirmPrompt "Do you want to install $actualVersion?" "buttons" && opt=Yes || opt=No
  case $opt in
    y*|Y*|"")
      crInstall "$appPath"  # Call cr Install function
      config "INSTALLED_POSITION" "$branchPosition"
      config "INSTALLED_VERSION" "$crVersion"
      config "APP_SIZE" "$crSize"
      config "INSTALLED_TIME" "$(date "+%Y-%m-%d %H:%M")"
      printf '\033[2J\033[3J\033[H' && exit 0
      ;;
    n*|N*) echo -e "$notice Chromium installation skipped."; rm -rf "$HOME/chrome-mac/"; sleep 1 ;;
  esac
}

extrct() {
  local archivePath=$1

  echo && echo -e "$running Extrcting ${Red}chrome-mac.zip${Reset}"
  pv "$archivePath" | tar -xf - -C "$HOME" && rm -f "$archivePath"
  installPrompt "$HOME/chrome-mac/Chromium.app"  # Call install Prompt function
}

dl() {
  local dlUrl=$1
  crdlSize=$(curl -sIL $dlUrl | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }')
  echo -e "$running Direct Downloading Chromium $crVersion from ${Blue}$dlUrl${Reset} $crdlSize"

  while true; do
    if [ "$channel" == "Extended" ] || [ "$channel" == "Stable" ] || [ "$channel" == "Beta" ] || [ "$channel" == "Dev" ]; then
      curl -L --progress-bar -C - -o "$HOME/chrome-mac.zip" "$dlUrl"
      DOWNLOAD_STATUS=$?
    else
      aria2c -x 16 -s 16 --continue=true --console-log-level=error --summary-interval=0 --download-result=hide -o "chrome-mac.zip" -d "$HOME" "$dlUrl"
      DOWNLOAD_STATUS=$?
      echo  # White Space
    fi
    if [ $DOWNLOAD_STATUS -eq 0 ]; then
      if [ -d "/Applications/Cloudflare WARP.app" ]; then
        warpCliStatus=$("$warp_cli" status | head -1 | awk '{printf "%s\n", $3}' 2>/dev/null)
        warp_status=$(curl -s https://www.cloudflare.com/cdn-cgi/trace | awk -F'=' '/ip|colo|warp/ {printf "%s: %s\n", $1, $2}' | awk -F':' '/warp/ {print $2}')
        if [ "$warpCliStatus" == "Connected" ] || [ "$warp_status" == "on" ]; then
          "$warp_cli" disconnect
          #osascript -e 'quit app "Cloudflare WARP"'
        fi
      fi
      break  # break resuming download loop
    elif [ $DOWNLOAD_STATUS -eq 6 ] || [ $DOWNLOAD_STATUS -eq 19 ]; then
      if [ "$channel" != "Extended" ] || [ "$channel" != "Stable" ] || [ "$channel" != "Beta" ] || [ "$channel" != "Dev" ]; then
        aria2ConsoleLogHide  # for aria2
      fi
      echo -e "$bad Default resolver of $active_list failed to resolve ${Blue}https://commondatastorage.googleapis.com/${Reset} host!"
      echo -e "$info Connect Cloudflare 1.1.1.1 with WARP, 1.1.1.1 one of the fastest DNS resolvers on Earth."
      if [ -d "/Applications/Cloudflare WARP.app" ]; then
        #open -a "Cloudflare WARP"
        if [ "$warpCliStatus" == "Disconnected" ]; then
          #"$warp_cli" mode doh  # HTTPS
          "$warp_cli" mode warp  # WARP
          #"$warp_cli" mode warp+doh  # HTTPS + WARP
          "$warp_cli" dns families malware
          "$warp_cli" connect
        fi
      else
        brew install --cask cloudflare-warp > /dev/null 2>&1
        #open -a "Cloudflare WARP"
        ! "$warp_cli" registration show >/dev/null 2>&1 && "$warp_cli" registration new
        osascript -e 'quit app "Cloudflare WARP"'
        warpCliStatus=$("$warp_cli" status | head -1 | awk '{printf "%s\n", $3}' 2>/dev/null)
        if [ "$warpCliStatus" == "Disconnected" ]; then
          "$warp_cli" mode warp
          "$warp_cli" dns families malware
          "$warp_cli" connect
        fi
      fi
      sleep 3  # Wait 3 seconds
      warp_status=$(curl -s https://www.cloudflare.com/cdn-cgi/trace | awk -F'=' '/ip|colo|warp/ {printf "%s: %s\n", $1, $2}' | awk -F':' '/warp/ {print $2}')
      [ "$warp_status" == "on" ] && echo -e "Your Internet is ${Orange}private${Reset}."
    elif [ $DOWNLOAD_STATUS -eq 56 ] || [ $DOWNLOAD_STATUS -eq 1 ]; then
      if [ "$channel" != "Extended" ] || [ "$channel" != "Stable" ] || [ "$channel" != "Beta" ] || [ "$channel" != "Dev" ]; then
        aria2ConsoleLogHide  # for aria2
      fi
      echo -e "$bad $active_list signal are very unstable!"
      echo -e "$info Please switch Network service to $inactive_list"
      [ $productVersion -ge 13 ] && open "x-apple.systempreferences:com.apple.Network-Settings.extension" || open "/System/Library/PreferencePanes/Network.prefPane"
    fi
    echo -e "$notice Download failed! retrying in 5 seconds.."; sleep 5  # wait 5 seconds
  done
  extrct "$HOME/chrome-mac.zip"  # Call extract function
}

# --- Direct Download Function ---
directDl() {
  downloadUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots/$snapshotPlatform/$branchPosition/chrome-mac.zip"
  if curl --head --silent --fail "$downloadUrl" >/dev/null 2>&1; then
    echo -e "${good} Found valid snapshot at: $branchPosition" && echo
    if [ "$installedPosition" == "$branchPosition" ]; then
      echo -e "$notice Already installed: $installedPosition"
      sleep 3; printf '\033[2J\033[3J\033[H'; exit 0
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
        
    checkUrl="$branchUrl/$snapshotPlatform/$pos/chrome-mac.zip"
    if curl --head --silent --fail "$checkUrl" >/dev/null 2>&1; then
      echo -e "${good} Found valid snapshot at: $pos" && echo
      if [ "$installedPosition" == "$pos" ] && [ "$installedVersion" == "$crVersion" ]; then
        echo -e "$notice Already installed: $installedVersion"
        sleep 3; printf '\033[2J\033[3J\033[H'; exit 0
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

# --- Fetch the last Chromium Extended version info ---
eInfo() {
  branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Extended&platform=Mac&num=2")
  crVersion=$(echo "$branchData" | jq -r '.[0].version')
  branchPosition=$(echo "$branchData" | jq -r '.[0].chromium_main_branch_position')
  echo -e "$info Last Chromium Extended Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the last Chromium Stable version info ---
sInfo() {
  branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Mac&num=2")
  crVersion=$(echo "$branchData" | jq -r '.[1].version')
  branchPosition=$(echo "$branchData" | jq -r '.[1].chromium_main_branch_position')
  echo -e "$info Last Chromium Stable Releases Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the last Chromium Beta version info ---
bInfo() {
  branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Beta&platform=Mac&num=1")
  crVersion=$(echo "$branchData" | jq -r '.[0].version')
  branchPosition=$(echo "$branchData" | jq -r '.[0].chromium_main_branch_position')
  echo -e "$info Last Chromium Beta Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the last Chromium Dev version info ---
dInfo() {
  branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Dev&platform=Mac&num=1")
  crVersion=$(echo "$branchData" | jq -r '.[0].version')
  branchPosition=$(echo "$branchData" | jq -r '.[0].chromium_main_branch_position')
  echo -e "$info Last Chromium Dev Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the last Chromium Canary version ---
cInfo() {
  branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Mac&num=1")
  crVersion=$(echo "$branchData" | jq -r '.[0].version')
  branchPosition=$(echo "$branchData" | jq -r '.[0].chromium_main_branch_position')
  echo -e "$info Last Chromium Canary Version: $crVersion at branch position: $branchPosition"
}

# --- Fetch the Chromium Canary Test version info ---
tInfo() {
  printf "🕊️ ${Yellow}Please wait few seconds! fetching crVersion..${Reset}"
  branchData=$(curl -sL "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Android&num=1")
  branchPosition=$(curl -sL "$branchUrl/$snapshotPlatform/LAST_CHANGE")
  
  n="500"  # Initialize n=500
  while true; do
    count=$(curl -s "https://chromium.googlesource.com/chromium/src/+log?n=500" | pup 'li json{}' | jq -r '.[] | select(.children[].text | test("Updating trunk VERSION from")) | .children[] | select(.class == "CommitLog-time") | .text' | sed 's/^[·[:space:]]*//' | wc -l)
    [ "$count" -ge 1 ] && break  # break the loop if count > 1
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
  
  selected_option=1  # Select Stable by default
  selected_button=0
  
  if [ -d /Applications/Chromium.app ] && [ -f "$crdlJson" ] && jq -e 'has("INSTALLED_POSITION")' "$crdlJson" >/dev/null 2>&1; then
    INSTALLED=1
  else
    INSTALLED=0
  fi

  show_menu() {
    printf '\033[2J\033[3J\033[H'  # clear
    print_crdl  # call print_crdl function
    [ $INSTALLED -eq 1 ] && { echo -e "$info INSTALLED: $appVersion - $appSize - $installedTime"; echo; }
    echo -e "Navigate with [↑] [↓] [←] [→] || Select with [↵]\n"
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
  printf '\033[2J\033[3J\033[H'  # fully clear the screen and reset scrollback
  options=("Extended" "Stable" "Beta" "Dev" "Canary" "Canary Test"); buttons=("<Select>" "<Exit>"); menu "options" "buttons"; channel="${options[$selected]}"
  case "$channel" in
    [Ee]*)
      channel="Extended"
      echo && eInfo  # Call the Chromium Extended info function
      echo && findValidSnapshot "$branchPosition" $LAST_CHANGE  # Call the find valid snapshot function and pass the value
      ;;
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
  esac
done
#####################################################################################