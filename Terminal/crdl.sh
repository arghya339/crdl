#!/bin/bash

# Chromium is an open-source browser project, developed and maintained by Google
# Easy Script to download and run latest Chromium macOS build
# Use: ~ curl -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Terminal/crdl.sh" && bash "$HOME/.crdl.sh"
# Developer github.com/arghya339

# --- Downloading latest crdl.sh file from GitHub ---
curl -o "$HOME/.crdl.sh" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Terminal/crdl.sh" > /dev/null 2>&1

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
  printf '\n'
  printf '\n'   
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
outdatedFormulae=$(brew outdated 2>/dev/null)
LAST_INSTALL="$HOME/.LAST_INSTALL"
INSTALLED_VERSION="$HOME/.INSTALLED_VERSION"
installedPosition=$(cat "$LAST_INSTALL" 2>/dev/null)
installedVersion=$(cat "$INSTALLED_VERSION" 2>/dev/null)
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"
# Detect platform (Intel or ARM)
if [[ $(uname -m) == "x86_64" ]]; then
    snapshotPlatform="Mac"  # For Intel (x86_64) 
else
    snapshotPlatform="Mac_Arm"  # For Apple Silicon (ARM64)
fi
LAST_CHANGE=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")
INSTALLED_SIZE="$HOME/.INSTALLED_SIZE"
installedSize=$(cat "$INSTALLED_SIZE" 2>/dev/null)
if [ -d /Applications/Chromium.app ]; then
  actualInstalledVersion=$(/Applications/Chromium.app/Contents/MacOS/Chromium --version)
fi
INSTALL_TIME="$HOME/.INSTALL_TIME"
installTime=$(cat "$INSTALL_TIME" 2>/dev/null)

# --- Check OS version ---
if [ $productVersion -le 10 ]; then
  echo -e "${bad} ${Red}macOS $productVersion is not supported by Chromium.${Reset}"  # Chromium required macOS 10.14+ (Catalina)
  exit 1
fi

echo -e "🚀 ${Yellow}Please wait! starting crdl...${Reset}"

# --- Check if brew is installed ---
if brew --version >/dev/null 2>&1; then
  brew update > /dev/null 2>&1
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1
fi

# --- bash formulae update function ---
update_bash() {
  if echo $outdatedFormulae | grep -q "^bash" 2>/dev/null; then
    brew upgrade bash > /dev/null 2>&1
  fi
}

# --- Check if bash is installed ---
if which bash > /dev/null 2>&1; then
  update_bash
else
  brew install bash > /dev/null 2>&1
fi

# --- grep formulae update function ---
update_grep() {
  if echo $outdatedFormulae | grep -q "^grep" 2>/dev/null; then
    brew upgrade grep > /dev/null 2>&1
  fi
}

# --- Check if grep is installed ----
if [ -f "/usr/bin/grep" ]; then
  update_grep
else
  brew install grep > /dev/null 2>&1
fi

# --- curl formulae update function ---
update_curl() {
  if echo $outdatedFormulae | grep -q "^curl" 2>/dev/null; then
    brew upgrade curl > /dev/null 2>&1
  fi
}

# --- Check if curl is installed ----
if which curl > /dev/null 2>&1; then
  update_curl
else
  brew install curl > /dev/null 2>&1
fi

# --- aria2 formulae update function ---
update_aria2() {
  if echo $outdatedFormulae | grep -q "^aria2c" 2>/dev/null; then
    brew upgrade aria2 > /dev/null 2>&1
  fi
}

# --- Check if aria2 is installed ----
if which aria2c > /dev/null 2>&1; then
  update_aria2
else
  brew install aria2 > /dev/null 2>&1
fi

# --- jq formulae update function ---
update_jq() {
  if echo $outdatedFormulae | grep -q "^jq" 2>/dev/null; then
    brew upgrade jq > /dev/null 2>&1
  fi
}

# --- Check if jq is installed ---
if which jq > /dev/null 2>&1; then
    update_jq  # Check jq furmulae updates by calling the function
else
    brew install jq > /dev/null 2>&1
fi

# --- libarchive formulae update function ---
update_libarchive() {
  if echo $outdatedFormulae | grep -q "^libarchive" 2>/dev/null; then
    brew upgrade libarchive > /dev/null 2>&1
  fi
}

# bsdtar is part of macOS's system utilities
<<comment
# --- Check if libarchive (brew version of bsdtar) is installed ---
if which libarchive > /dev/null 2>&1; then
    update_libarchive  # Check libarchive furmulae updates by calling the function
else
    brew install libarchive > /dev/null 2>&1
fi
comment

# --- pv update function ---
update_pv() {
  if echo $outdatedFormulae | grep -q "^pv" 2>/dev/null; then
    brew upgrade pv > /dev/null 2>&1
  fi
}

# --- Check if pipeviewer is installed ---
if which pv > /dev/null 2>&1; then
  update_pv
else
  brew install pv > /dev/null 2>&1
fi

# --- bc formulae update function ---
update_bc() {
  if echo $outdatedFormulae | grep -q "^bc" 2>/dev/null; then
    brew upgrade bc > /dev/null 2>&1
  fi
}

# --- Check if basicCalculator is installed ---
if which bc > /dev/null 2>&1; then
    update_bc  # Check bc furmulae updates by calling the function
else
    brew install bc > /dev/null 2>&1
fi

# --- pup formulae update function ---
update_pup() {
  if echo $outdatedFormulae | grep -q "^pup" 2>/dev/null; then
    brew upgrade pup > /dev/null 2>&1
  fi
}

# --- Check if pup is installed ---
if which pup > /dev/null 2>&1; then
    update_pup  # Check pup furmulae updates by calling the function
else
    brew install pup > /dev/null 2>&1
fi

# Get active interfaces (those with 'status: active')
active_ifaces=$(ifconfig | awk '
  /^[a-z]/ { iface=$1; sub(":", "", iface) }
  /status: active/ { print iface }
')

# Build list of active service names based on active interfaces
active_services=()
while IFS= read -r device; do
  service=$(networksetup -listnetworkserviceorder | awk -v dev="$device" '
    $0 ~ "Device: " dev {
      sub(/^.*\) /, "", prev)
      print prev
    }
    { prev = $0 }
  ')
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

# --- install Chromium function ---
crInstall() {
  if [ -d "/Applications/Chromium.app" ]; then
    sudo cp -R $HOME/chrome-mac/Chromium.app /Applications/ 2>/dev/null  # Copy with replace an app
    sleep 15 && rm -rf "$HOME/chrome-mac"
    open -a "Chromium" # open Chromium app after update
  else
    sudo cp -Rn ~/chrome-mac/Chromium.app /Applications/ 2>/dev/null  # Skips if already exists
    sleep 15 && rm -rf "$HOME/chrome-mac"
    curl -o "$HOME/top-50.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-50.sh > /dev/null 2>&1 && bash "$HOME/top-50.sh" && rm "$HOME/top-50.sh"
  fi
  echo -e "$good $actualVersion successfully installed! Please restart Chromium.app to take effect." && sleep 3
}

# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  printf '\033[2J\033[3J\033[H'  # clear aria2 multi error log from console
  print_crdl  # call the print_crdl function 
  if [ -d /Applications/Chromium.app ]; then
    echo -e "$info INSTALLED: $actualInstalledVersion - $installedSize - $installTime" && echo
  fi
  echo -e "E. Extended \nS. Stable \nB. Beta \nD. Dev \nC. Canary \nT. Canary Test \nQ. Quit \n"
  echo "Select Chromium Channel: $channel"
  echo && echo -e "$info Last Chromium Canary Test Version: $crVersion at branch position: $branchPosition"
  echo -e "${good} Found valid snapshot at: $branchPosition" && echo
  echo -e "$running Direct Downloading Chromium $crVersion from ${Blue}$downloadUrl${Reset} $crdlSize"
}

# --- Direct Download Function ---
directDl() {
downloadUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots/$snapshotPlatform/$branchPosition/chrome-mac.zip"
# Prefer the direct download link if available
if [ -n "$downloadUrl" ] && [ "$downloadUrl" != "null" ]; then
    echo -e "${good} Found valid snapshot at: $branchPosition" && echo
    if [ "$installedPosition" == "$branchPosition" ]; then
        echo -e "$notice Already installed: $installedPosition"
        sleep 3 && printf '\033[2J\033[3J\033[H' && exit 0
    else
        crdlSize=$(curl -sIL $downloadUrl | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }')
        echo -e "$running Direct Downloading Chromium $crVersion from ${Blue}$downloadUrl${Reset} $crdlSize"
        while true; do
            #curl -L --progress-bar -C - -o "$HOME/chrome-mac.zip" "$downloadUrl"
            aria2c -x 16 -s 16 --continue=true --console-log-level=error --summary-interval=0 --download-result=hide -o "chrome-mac.zip" -d "$HOME" "$downloadUrl"
            DOWNLOAD_STATUS=$?
            echo
            if [ $DOWNLOAD_STATUS -eq "0" ]; then
              break  # break the resuming download loop
            elif [ $DOWNLOAD_STATUS -eq "6" ] || [ $DOWNLOAD_STATUS -eq "19" ]; then
              aria2ConsoleLogHide  # for aria2
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
                if ! "$warp_cli" registration show >/dev/null 2>&1; then
                  "$warp_cli" registration new
                fi
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
              if [ "$warp_status" == "on" ]; then
                echo -e "Your Internet is ${Orange}private${Reset}."
              fi
            elif [ $DOWNLOAD_STATUS -eq "56" ] || [ $DOWNLOAD_STATUS -eq "1" ]; then
              aria2ConsoleLogHide  # for aria2
              echo -e "$bad $active_list signal are very unstable!"
              echo -e "$info Please switch Network service to $inactive_list"
              if [ $productVersion -ge "13" ]; then
                open "x-apple.systempreferences:com.apple.Network-Settings.extension"
              else
                open "/System/Library/PreferencePanes/Network.prefPane"
              fi
            fi
            echo -e "$notice Download failed! retrying in 5 seconds.." && sleep 5  # wait 5 seconds
        done
        echo && echo -e "$running Extrcting ${Red}chrome-mac.zip${Reset}"
        pv "$HOME/chrome-mac.zip" | tar -xf - -C "$HOME" && rm "$HOME/chrome-mac.zip"
        chmod -R +x $HOME/chrome-mac/Chromium.app && actualVersion=$($HOME/chrome-mac/Chromium.app/Contents/MacOS/Chromium --version 2>/dev/null)
        crSize=$(du -sk "$HOME/chrome-mac/Chromium.app" | awk '{total_bytes = $1 * 1024; printf "%.2f MB\n", total_bytes / 1000000}')
        echo && echo -e "$question Do you want to install $actualVersion? [Y/n]"
        read -r -p "Select: " opt
              case $opt in
                y*|Y*|"")
                  crInstall
                  timeIs=$(date "+%Y-%m-%d %H:%M")
                  touch "$INSTALL_TIME" && echo "$timeIs" > "$INSTALL_TIME"
                  touch "$LAST_INSTALL" && echo "$branchPosition" > "$LAST_INSTALL"
                  touch "$INSTALLED_SIZE" && echo "$crSize" > "$INSTALLED_SIZE"
                  printf '\033[2J\033[3J\033[H' && exit 0
                  ;;
                n*|N*) echo -e "$notice Chromium installation skipped."; rm -rf "$HOME/chrome-mac/"; sleep 1 ;;
                *) echo -e "$info Invalid choice! installation skipped."; rm -rf "$HOME/chrome-mac/"; sleep 2 ;;
              esac
    fi
else
    echo -e "${bad} No direct download URL found." && sleep 1
fi
}

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
        
        checkUrl="$branchUrl/$snapshotPlatform/$pos/chrome-mac.zip"
        if curl --head --silent --fail "$checkUrl" >/dev/null 2>&1; then
            echo -e "${good} Found valid snapshot at: $pos" && echo
            if [ "$installedPosition" == "$pos" ] && [ "$installedVersion" == "$crVersion" ]; then
                echo -e "$notice Already installed: $installedVersion"
                sleep 3 && printf '\033[2J\033[3J\033[H' && exit 0
            else
                crdlSize=$(curl -sIL $checkUrl | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }')
                echo -e "$running Downloading Chromium $crVersion from: ${Blue}$checkUrl${Reset} $crdlSize"
                while true; do
                    curl -L --progress-bar -C - -o "$HOME/chrome-mac.zip" "$checkUrl"
                    DOWNLOAD_STATUS=$?
                    if [ $DOWNLOAD_STATUS -eq "0" ]; then
                      break  # break the resuming download loop
                    fi
                    echo -e "$notice Retrying in 5 seconds.." && sleep 5  # wait 5 seconds
                done
                echo && echo -e "$running Extracting ${Red}chrome-mac.zip${Reset}"
                pv "$HOME/chrome-mac.zip" | tar -xf - -C "$HOME" && rm "$HOME/chrome-mac.zip"
                chmod -R +x $HOME/chrome-mac/Chromium.app && actualVersion=$($HOME/chrome-mac/Chromium.app/Contents/MacOS/Chromium --version 2>/dev/null)
                crSize=$(du -sk "$HOME/chrome-mac/Chromium.app" | awk '{total_bytes = $1 * 1024; printf "%.2f MB\n", total_bytes / 1000000}') 
                echo && echo -e "$question Do you want to install Chromium_v$crVersion.dmg? [Y/n]"
                read -r -p "Select: " opt
                case $opt in
                    y*|Y*|"")
                      crInstall
                      timeIs=$(date "+%Y-%m-%d %H:%M")
                      touch "$INSTALL_TIME" && echo "$timeIs" > "$INSTALL_TIME"
                      echo "$pos" | tee "$LAST_INSTALL" > /dev/null && echo "$crVersion" | tee "$INSTALLED_VERSION" > /dev/null
                      echo "$crSize" | tee "$INSTALLED_SIZE" > /dev/null
                      sleep 3 && printf '\033[2J\033[3J\033[H' && exit 0
                      ;;
                    n*|N*)
                      echo -e "$notice Chromium installation skipped."
                      rm -rf "$HOME/chrome-mac" && sleep 1
                      ;;
                    *)
                      echo -e "$info Invalid choice. Installation skipped."
                      rm -rf "$HOME/chrome-mac" && sleep 2 
                      ;;
                esac
                sleep 3 && break  # Break the searching loop
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
  printf '\033[2J\033[3J\033[H'  # fully clear the screen and reset scrollback
  print_crdl  # Call the print crdl shape function
  if [ -d /Applications/Chromium.app ]; then
    echo -e "$info INSTALLED: $actualInstalledVersion - $installedSize - $installTime" && echo
  fi
  echo -e "E. Extended \nS. Stable \nB. Beta \nD. Dev \nC. Canary \nT. Canary Test \nQ. Quit \n"
  read -r -p "Select Chromium Channel: " channel
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
            printf '\033[2J\033[3J\033[H' # clear Terminal
            break  # break the loop
            ;;
          *)
            echo -e "$info Invalid option. Please select a valid channel." && sleep 3
            ;;
        esac
done
#####################################################################################