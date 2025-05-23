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
cloudflareDOH="-L --doh-url https://cloudflare-dns.com/dns-query"
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

echo -e "${Yellow}Please wait! starting crdl...${Reset}"

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

# --- unzip formulae update function ---
update_unzip() {
  if echo $outdatedFormulae | grep -q "^unzip" 2>/dev/null; then
    brew upgrade unzip > /dev/null 2>&1
  fi
}

# --- Check if unzip is installed ---
if which unzip > /dev/null 2>&1; then
    update_unzip  # Check unzip furmulae updates by calling the function
else
    brew install unzip > /dev/null 2>&1
fi

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
    sudo cp -R $HOME/chrome-mac/Chromium.app /Applications/  # Copy with replace an app
    sleep 15 && rm -rf "$HOME/chrome-mac"
  else
    sudo cp -Rn ~/chrome-mac/Chromium.app /Applications/  # Skips if already exists
    sleep 15 && rm -rf "$HOME/chrome-mac"
    curl -o "$HOME/top-50.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/bash/top-50.sh > /dev/null 2>&1 && bash "$HOME/top-50.sh" && rm "$HOME/top-50.sh"
  fi
  echo -e "$good $actualVersion successfully installed! Please restart Chromium.app to take effect." && sleep 3
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
            curl -L --progress-bar -C - -o "$HOME/${snapshotPlatform}_${branchPosition}_chrome-mac.zip" "$downloadUrl"
            DOWNLOAD_STATUS=$?
            if [ $DOWNLOAD_STATUS -eq "0" ]; then
              break  # break the resuming download loop
            elif [ $DOWNLOAD_STATUS -eq "6" ]; then
              echo -e "$bad Default resolver of $active_list failed to resolve ${Blue}https://commondatastorage.googleapis.com/${Reset} host!"
              echo -e "$info Connect Cloudflare 1.1.1.1 with WARP, 1.1.1.1 one of the fastest DNS resolvers on Earth."
              if [ -d "/Applications/Cloudflare WARP.app" ]; then
                open -a "Cloudflare WARP"
              else
                curl -L --progress-bar -o "$HOME/Downloads/Cloudflare_WARP.pkg" "https://1111-releases.cloudflareclient.com/mac/latest"
                sudo installer -pkg ~/Downloads/Cloudflare_WARP.pkg  -target / > /dev/null 2>&1
                rm "$HOME/Downloads/Cloudflare_WARP.pkg"
              fi
            elif [ $DOWNLOAD_STATUS -eq "56" ]; then
              echo -e "$bad $active_list signal are very unstable!"
              echo -e "$info Please switch Network service to $inactive_list"
              if [ $productVersion -ge "13" ]; then
                open "x-apple.systempreferences:com.apple.Network-Settings.extension"
              else
                open "/System/Library/PreferencePanes/Network.prefPane"
              fi
            fi
            echo -e "$notice Retrying in 5 seconds.." && sleep 5  # wait 5 seconds
        done
        echo && echo -e "$running Extrcting ${snapshotPlatform}_${branchPosition}_chrome-mac.zip"
        itemCount=$(unzip -l "$HOME/${snapshotPlatform}_${branchPosition}_chrome-mac.zip" | tail -n +4 | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | wc -l)
        unzip -o "$HOME/${snapshotPlatform}_${branchPosition}_chrome-mac.zip" -d "$HOME/" | pv -l -s "$itemCount" > /dev/null && rm "$HOME/${snapshotPlatform}_${branchPosition}_chrome-mac.zip"
        chmod +x $HOME/chrome-mac/Chromium.app && actualVersion=$($HOME/chrome-mac/Chromium.app/Contents/MacOS/Chromium --version)
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
                echo && echo -e "$running Extracting chrome-mac.zip"
                itemCount=$(unzip -l "$HOME/chrome-mac.zip" | tail -n +4 | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | wc -l)
                unzip -o "$HOME/chrome-mac.zip" -d "$HOME" | pv -l -s "$itemCount" > /dev/null && rm "$HOME/chrome-mac.zip"
                chmod +x $HOME/chrome-mac/Chromium.app && actualVersion=$($HOME/chrome-mac/Chromium.app/Contents/MacOS/Chromium --version)
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
    branchData=$(curl -s "https://chromiumdash.appspot.com/fetch_releases?channel=Canary&platform=Mac&num=1")
    # canary_milestone=$(echo "$canary_branchData" | jq -r '.[0].milestone')
    crVersion=$(echo "$branchData" | jq -r '.[0].version' | sed -E -e 's/^([0-9]{2})([0-9])/\1X/' -e 's/([0-9])([0-9]{3})\.[0-9]+/\1XXX.X/')
    branchPosition=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")
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