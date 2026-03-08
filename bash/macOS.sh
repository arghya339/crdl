#!/bin/bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

# Chromium required macOS 10.14+ (Catalina)
productVersion=$(sw_vers -productVersion | cut -d '.' -f1)
[ $productVersion -le 10 ] && { echo -e "$bad ${Red}macOS $productVersion is not supported by Chromium.${Reset}"; exit 1; }
crZIP="chrome-mac"
[ $(uname -m) == "x86_64" ] && { snapshotPlatform="Mac"; Arch=amd64; } || { snapshotPlatform="Mac_Arm"; Arch=arm64; }
platform=Mac
[ -f "$crdlJson" ] && AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$crdlJson" 2>/dev/null) || AutoUpdatesDependencies=true

formulaeUpdate() {
  formulae=$1
  if echo "$outdatedFormulae" | grep -q "^$formulae" 2>/dev/null; then
    echo -e "$running Upgrading $formulae formulae.."
    brew upgrade "$formulae" > /dev/null 2>&1
  fi
}

formulaeInstall() {
  formulae=$1
  if echo "$formulaeList" | grep -q "$formulae" 2>/dev/null; then
    formulaeUpdate "$formulae"
  else
    echo -e "$running Installing $formulae formulae.."
    brew install "$formulae" > /dev/null 2>&1
  fi
}

formulaeUninstall() {
  formulaeList=$(brew list 2>/dev/null)
  formulae=$1
  if echo "$formulaeList" | grep -q "$formulae" 2>/dev/null; then
    echo -e "$running Uninstalling $formulae formulae.."
    brew uninstall "$formulae" > /dev/null 2>&1
  fi
}

dependencies() {
  brew --version &>/dev/null && brew update &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  formulaeList=$(brew list 2>/dev/null)
  outdatedFormulae=$(brew outdated 2>/dev/null)
  formulaeInstall "bash"  # bash update
  formulaeInstall "grep"  # grep update
  formulaeInstall "curl"  # curl update
  formulaeInstall "aria2"  # aria2 install/update
  formulaeInstall "ca-certificate"  # ca-certificate update
  formulaeInstall "jq"  # jq install/update
  formulaeInstall "pv"  # pv install/update
  formulaeInstall "pup"  # pup install/update
  # https://github.com/aria2/aria2/issues/1920
  aria2Executing=$(aria2c -q -d "$HOME" -o aria2Executing --ca-certificate="/etc/ssl/cert.pem" --async-dns=true --async-dns-server="$googleIP" "https://one.one.one.one/")
  if echo "$aria2Executing" | grep -q "--async-dns=true" 2>/dev/null; then
    curl -L --progress-bar -C - -o $Download/aria2c-macos-$Arch.tar https://github.com/tofuliang/aria2/releases/download/20240919/aria2c-macos-$Arch.tar
    pv "$Download/aria2c-macos-$Arch.tar" | tar -xf - -C "$Download" && rm -f "$Download/aria2c-macos-$Arch.tar"
    sudo mv $Download/aria2c /usr/local/bin/aria2c
    aria2c -v &>/dev/null && aria2c -v | head -1 | awk '{print $3}' || { sudo xattr -d com.apple.quarantine /usr/local/bin/aria2c && aria2c -v | head -1; }
    rm -f ~/aria2Executing
  else
    rm -f ~/aria2Executing
  fi
}
[ "$AutoUpdatesDependencies" == true ] && { checkInternet && dependencies; }

appInstall() {
  local filePath=${1}
  [ -d "/Applications/Chromium.app" ] && osascript -e 'quit app "Chromium"'
  sudo cp -R $filePath /Applications/ 2>/dev/null && { installStatus=0; open -a "Chromium"; } || installStatus=1
}
