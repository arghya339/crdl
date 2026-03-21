#!/bin/bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

CreateAppIcon() {
  source="$crdl/ChromiumSetup.png"
  [ ! -f "$source" ] && curl -L --progress-bar -C - -o "$source" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/.Icon/ChromiumSetup.png"
  PointSizeNames=("16x16" "16x16@2x" "32x32" "32x32@2x" "128x128" "128x128@2x" "256x256" "256x256@2x" "512x512" "512x512@2x")
  PixelResolutions=("16" "32" "32" "64" "128" "256" "256" "512" "512" "1024")
  iconset="$crdl/ChromiumSetup.iconset"
  mkdir -p $iconset
  for ((i=0; i<${#PointSizeNames[@]}; i++)); do
    [ ${PixelResolutions[i]} -eq 1024 ] && cp $source $iconset/icon_${PointSizeNames[i]}.png || sips -z ${PixelResolutions[i]} ${PixelResolutions[i]} $source --out $iconset/icon_${PointSizeNames[i]}.png
  done
  iconutil -c icns $iconset -o $crdl/ChromiumSetup.icns && rm -rf $iconset
}
CreateScriptLaunchpadShortcuts() {
  shortcutLabel=${1}
  scriptPath=${2}
  Interactive=${3:-true}
  [ ! -f "$crdl/ChromiumSetup.icns" ] && CreateAppIcon
  mkdir -p "/Applications/${shortcutLabel}.app/Contents/Resources"
  cp "$crdl/ChromiumSetup.icns" "/Applications/${shortcutLabel}.app/Contents/Resources/ChromiumSetup.icns"
  mkdir -p "/Applications/${shortcutLabel}.app/Contents/MacOS"
  [ $Interactive == true ] && echo -e "#!/bin/bash\nosascript -e 'tell application \"Terminal\" to do script \"bash ${scriptPath}\"'\nosascript -e 'tell application \"System Events\" to set frontmost of process \"Terminal\" to true'" > "/Applications/${shortcutLabel}.app/Contents/MacOS/launcher" || echo -e "#!/bin/bash\nexport PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"\nsource ${scriptPath}" > "/Applications/${shortcutLabel}.app/Contents/MacOS/launcher"
  chmod +x "/Applications/${shortcutLabel}.app/Contents/MacOS/launcher"
  cat > "/Applications/${shortcutLabel}.app/Contents/Info.plist" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>ChromiumSetup</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOL
  touch /Applications/${shortcutLabel}.app
  killall Dock
}
[ ! -d "/Applications/crdl.app/" ] && CreateScriptLaunchpadShortcuts "crdl" "$HOME/.crdl.sh"
[ ! -d "/Applications/crup.app/" ] && CreateScriptLaunchpadShortcuts "crup" "$crdl/crup.sh" "false"

# Chromium required macOS 12 (Monterey) or later
productVersion=$(sw_vers -productVersion | cut -d '.' -f1)
[ $productVersion -lt 12 ] && { echo -e "$bad ${Red}macOS $productVersion is not supported by Chromium !!${Reset}"; open "https://www.firefox.com/"; exit 1; }  # Chromium: macOS 12+ || FireFox: macOS 10.15+
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
  cp -R $filePath /Applications/ 2>/dev/null && { installStatus=0; open -a "Chromium"; } || installStatus=1
}

# https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
LaunchAgents() {
  mkdir -p $HOME/Library/LaunchAgents/
  cat > "$HOME/Library/LaunchAgents/com.${USER}.crup.plist" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.${USER}.crup</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/${USER}/.crdl/crup.sh</string>
    </array>

    <key>KeepAlive</key>
    <dict>
        <key>NetworkState</key>
        <true/>
    </dict>

    <key>RunAtLoad</key>
    <${Boot}/>
EOL
  if [ "$Scheduler" != "None" ]; then
    if [ -z "$SchedulerS" ]; then
      case "$Scheduler" in
        15min) SchedulerS=$((60 * 15)) ;;
        30min) SchedulerS=$((60 * 30)) ;;
        1h) SchedulerS=$((60 * 60)) ;;
        3h) SchedulerS=$((60 * 60 * 3)) ;;
        6h) SchedulerS=$((60 * 60 * 6)) ;;
        9h) SchedulerS=$((60 * 60 * 9)) ;;
        12h) SchedulerS=$((60 * 60 * 12)) ;;
      esac
    fi
    cat >> "$HOME/Library/LaunchAgents/com.${USER}.crup.plist" <<EOL

    <key>StartInterval</key>
    <integer>${SchedulerS}</integer>
EOL
  fi
  if [ "$Timer" != "None" ]; then
    HH="${Timer%:*}"
    MM="${Timer#*:}"
    cat >> "$HOME/Library/LaunchAgents/com.${USER}.crup.plist" <<EOL

    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key>
        <integer>${MM}</integer>
        <key>Hour</key>
        <integer>${HH}</integer>
    </dict>
EOL
  fi
  cat >> "$HOME/Library/LaunchAgents/com.${USER}.crup.plist" <<EOL

    <key>StandardOutPath</key>
    <string>/tmp/crup.stdout</string>
    <key>StandardErrorPath</key>
    <string>/tmp/crup.stderr</string>
</dict>
</plist>
EOL
  launchctl unload $HOME/Library/LaunchAgents/com.${USER}.crup.plist
  launchctl load $HOME/Library/LaunchAgents/com.${USER}.crup.plist
  launchctl list | grep crup
}
