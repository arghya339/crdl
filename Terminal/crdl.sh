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
installedVersion=$(cat "$LAST_INSTALL" 2>/dev/null)
branchUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots"
# Detect platform (Intel or ARM)
if [[ $(uname -m) == "x86_64" ]]; then
    snapshotPlatform="Mac"  # For Intel (x86_64) 
else
    snapshotPlatform="Mac_Arm"  # For Apple Silicon (ARM64)
fi
LAST_CHANGE=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")

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
    brew upgrade bash -y > /dev/null 2>&1
  fi
}

# --- Check if bash is installed ---
if which bash > /dev/null 2>&1; then
  update_bash
else
  brew install bash -y > /dev/null 2>&1
fi

# --- grep formulae update function ---
update_grep() {
  if echo $outdatedFormulae | grep -q "^grep" 2>/dev/null; then
    brew upgrade grep -y > /dev/null 2>&1
  fi
}

# --- Check if grep is installed ----
if [ -f "/usr/bin/grep" ]; then
  update_grep
else
  brew install grep -y > /dev/null 2>&1
fi

# --- curl formulae update function ---
update_curl() {
  if echo $outdatedFormulae | grep -q "^curl" 2>/dev/null; then
    brew upgrade curl -y > /dev/null 2>&1
  fi
}

# --- Check if curl is installed ----
if which curl > /dev/null 2>&1; then
  update_curl
else
  brew install curl -y > /dev/null 2>&1
fi

# --- jq formulae update function ---
update_jq() {
  if echo $outdatedFormulae | grep -q "^jq" 2>/dev/null; then
    brew upgrade jq -y > /dev/null 2>&1
  fi
}

# --- Check if jq is installed ---
if which jq > /dev/null 2>&1; then
    update_jq  # Check jq furmulae updates by calling the function
else
    brew install jq -y > /dev/null 2>&1
fi

# --- unzip formulae update function ---
update_unzip() {
  if echo $outdatedFormulae | grep -q "^unzip" 2>/dev/null; then
    brew upgrade unzip -y > /dev/null 2>&1
  fi
}

# --- Check if unzip is installed ---
if which unzip > /dev/null 2>&1; then
    update_unzip  # Check unzip furmulae updates by calling the function
else
    brew install unzip -y > /dev/null 2>&1
fi

# --- bc formulae update function ---
update_bc() {
  if echo $outdatedFormulae | grep -q "^bc" 2>/dev/null; then
    brew upgrade bc -y > /dev/null 2>&1
  fi
}

# --- Check if basicCalculator is installed ---
if which bc > /dev/null 2>&1; then
    update_bc  # Check bc furmulae updates by calling the function
else
    brew install bc -y > /dev/null 2>&1
fi

# --- install Chromium function ---
crInstall() {
  if [ -f "/Applications/Chromium.app" ]; then
    sudo cp -R $HOME/chrome-mac/Chromium.app /Applications/  # Copy with replace an app
    rm -rf "$HOME/chrome-mac"
  else
    sudo cp -Rn ~/chrome-mac/Chromium.app /Applications/  # Skips if already exists
    curl -o "$HOME/top-50.sh" https://raw.githubusercontent.com/arghya339/crdl/main/Extensions/top-50.sh > /dev/null 2>&1 && bash "$HOME/top-50.sh" && rm "$HOME/top-50.sh"
  fi
  echo -e "$good Chromium_v$crVersion.dmg successfully installed! Please restart Chromium.app to take effect." && sleep 3
}

# --- Direct Download Function ---
directDl() {
downloadUrl="https://commondatastorage.googleapis.com/chromium-browser-snapshots/$snapshotPlatform/$branchPosition/chrome-mac.zip"
# Prefer the direct download link if available
if [ -n "$downloadUrl" ] && [ "$downloadUrl" != "null" ]; then
    echo -e "${good} Found valid snapshot at: $pos"
    if [ "$installedVersion" == "$branchPosition" ]; then
        echo -e "$notice Already installed: $installedVersion"
        sleep 3 && printf '\033[2J\033[3J\033[H' && exit 0
    else
        echo -e "$running Direct Downloading Chromium $crVersion form $downloadUrl"
        curl -L -o "$HOME/${snapshotPlatform}_${branchPosition}_chrome-mac.zip" "$downloadUrl"
        echo -e "$running Extrcting ${snapshotPlatform}_${branchPosition}_chrome-mac.zip"
        unzip -o "$HOME/${snapshotPlatform}_${branchPosition}_chrome-mac.zip" -d "$HOME/" > /dev/null 2>&1 && rm "$HOME/${snapshotPlatform}_${branchPosition}_chrome-mac.zip"
        echo -e "$question Are you want to install Chromium_v$crVersion.apk? [Y/n]"
        read -r -p "Select: " opt
              case $opt in
                y*|Y*|"")
                  crInstall && touch "$LAST_INSTALL" && echo "$branchPosition" > "$LAST_INSTALL"
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
            echo -e "${good} Found valid snapshot at: $pos"
            if [ "$installedVersion" == "$pos" ]; then
                echo -e "$notice Already installed: $installedVersion"
                sleep 3 && printf '\033[2J\033[3J\033[H' && exit 0
            else
                echo -e "$running Downloading Chromium $crVersion from: $checkUrl"
                curl -L -o "$HOME/chrome-mac.zip" "$checkUrl"
                echo -e "$running Extracting chrome-mac.zip"
                unzip -o "$HOME/chrome-mac.zip" -d "$HOME" > /dev/null 2>&1 && rm "$HOME/chrome-mac.zip"
                echo -e "$question Are you want to install Chromium_v$crVersion.apk? [Y/n]"
                read -r -p "Select: " opt
                case $opt in
                    y*|Y*|"")
                      crInstall && echo "$pos" | tee "$LAST_INSTALL" > /dev/null
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
    crVersion=$(echo "$branchData" | jq -r '.[0].version' | sed -E 's/([0-9])([0-9]{3})\.[0-9]+/\1XXX\.XXX/')
    branchPosition=$(curl -s "$branchUrl/$snapshotPlatform/LAST_CHANGE")
    echo -e "$info Last Chromium Canary Test Version: $crVersion at branch position: $branchPosition"
}

# --- Main Menu ---
while true; do
  printf '\033[2J\033[3J\033[H'  # fully clear the screen and reset scrollback
  print_crdl  # Call the print crdl shape function
  echo -e "E. Extended \nS. Stable \nB. Beta \nD. Dev \nC. Canary \nT. Canary Test \nQ. Quit \n"
  read -r -p "Select Chromium Channel: " channel
        case "$channel" in
          [Ee]*)
            channel="Extended"
            eInfo  # Call the Chromium Extended info function
            findValidSnapshot "$branchPosition" $LAST_CHANGE  # Call the find valid snapshot function and pass the value
            ;;
          [Ss]*)
            channel="Stable"
            sInfo  # Call the Chromium Stable info function
            findValidSnapshot "$branchPosition" $LAST_CHANGE  # Call the find valid snapshot function and pass the value
            ;;
          [Bb]*)
            channel="Beta"
            bInfo
            findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Dd]*)
            channel="Dev"
            dInfo
            findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Cc]*)
            channel="Canary"
            cInfo
            findValidSnapshot "$branchPosition" $LAST_CHANGE
            ;;
          [Tt]*)
            tInfo
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