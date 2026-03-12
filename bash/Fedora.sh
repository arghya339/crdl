#!/bin/bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

CreateBinaryLauncherShortcuts() {
  shortcutLabel=${1}
  iconPath=${2}
  binaryPath=${3}
  Interactive=${4:-true}
  PolicyKit=${5:-false}
  Categories=${6:-Utility}
  [ $PolicyKit == true ] && polkit="pkexec " || polkit=""
  cat > "$USER_HOME/.local/share/applications/${shortcutLabel}.desktop" <<EOL
[Desktop Entry]
Name=${shortcutLabel}
Icon=${iconPath}
Exec=${polkit}${binaryPath}
Terminal=${Interactive}
Type=Application
Categories=${Categories};
EOL
}
[ ! -f "$crdl/ChromiumSetup.png" ] && curl -L --progress-bar -C - -o "$crdl/ChromiumSetup.png" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/.Icon/ChromiumSetup.png"
[ ! -f "$USER_HOME/.local/share/applications/crdl.desktop" ] && CreateBinaryLauncherShortcuts "crdl" "$crdl/ChromiumSetup.png" "$USER_HOME/.crdl.sh" "true"
[ ! -f "$USER_HOME/.local/share/applications/crup.desktop" ] && CreateBinaryLauncherShortcuts "crup" "$crdl/ChromiumSetup.png" "$crdl/crup.sh" "false" "true"

crZIP="chrome-linux"
platform=Linux
if [ $(uname -m) == "x86_64" ]; then
  snapshotPlatform="Linux_x64"
elif [[ $(uname -m) == i*86 ]]; then
  snapshotPlatform="Linux"
elif [[ $(uname -m) == arm* ]] || [ $(uname -m) == "aarch64" ]; then
  snapshotPlatform="Linux_ARM_Cross-Compile"
fi
[ -f "$crdlJson" ] && AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$crdlJson" 2>/dev/null) || AutoUpdatesDependencies=true

dnfUpdate() {
  dnf=${1}
  if grep -q "^$dnf" <<< "$dnfUpgradesList" 2>/dev/null; then
    echo -e "$running Upgrading $dnf package.."
    sudo dnf update "$dnf" -y >/dev/null 2>&1
  fi
}

dnfInstall() {
  dnf=${1}
  if grep -q "^$dnf" <<< "$dnfList" 2>/dev/null; then
    dnfUpdate "$dnf"
  else
    echo -e "$running Installing $dnf package.."
    sudo dnf install "$dnf" -y >/dev/null 2>&1
  fi
}

dnfRemove() {
  dnf=${1}
  dnfList=$(dnf list --installed 2>/dev/null)
  if grep -q "^$dnf" <<< "$dnfList" 2>/dev/null; then
    echo -e "$running Uninstalling $dnf package.."
    sudo dnf remove "$dnf" -y >/dev/null 2>&1
  fi
}

dependencies() {
  dnfList=$(dnf list --installed 2>/dev/null)
  dnfUpgradesList=$(dnf --refresh list --upgrades 2>/dev/null)
  dnfInstall "bash"
  dnfInstall "grep"
  dnfInstall "gawk"
  dnfInstall "sed"
  dnfInstall "curl"
  dnfInstall "aria2"
  dnfInstall "jq"
  dnfInstall "bsdtar"
  dnfInstall "pv"
  if ! pup --version &>/dev/null; then
    if [ $(uname -m) == "x86_64" ]; then
      arch="amd64"
    elif [ $(uname -m) == "aarch64" ] || [ $(uname -m) == "arm64" ]; then
      arch="arm64"
    elif [[ $(uname -m) == i*86 ]]; then
      arch="386"
    fi
    curl -L --progress-bar -C - -o "$Download/pup_v0.4.0_linux_${arch}.zip" "https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_${arch}.zip"
    pv "$Download/pup_v0.4.0_linux_${arch}.zip" | sudo bsdtar -xf - -C "/usr/local/bin"
    [ -x "/usr/local/bin/pup" ] || sudo chmod +x /usr/local/bin/pup
    rm -f "$Download/pup_v0.4.0_linux_${arch}.zip"
  fi
}
[ "$AutoUpdatesDependencies" == true ] && checkInternet && dependencies

appInstall() {
  local filePath=${1}
  [ -d /opt/$crZIP/ ] && pkill chromium
  if [ -t 0 ]; then
    sudo cp -R $filePath /opt/$crZIP/ 2>/dev/null && { installStatus=0; sudo bash -c "ln -sf /opt/$crZIP/chrome /usr/local/bin/chromium && chmod +x /usr/local/bin/chromium"; } || installStatus=1
  else
    cp -R $filePath /opt/$crZIP/ 2>/dev/null && { installStatus=0; ln -sf /opt/$crZIP/chrome /usr/local/bin/chromium && chmod +x /usr/local/bin/chromium; } || installStatus=1
    if [ $installStatus -eq 1 ]; then
      pkexec bash -c "cp -R $filePath /opt/$crZIP/" && installStatus=0 || installStatus=1
    fi
  fi
  if [ ! -f "$USER_HOME/.local/share/applications/Chromium.desktop" ] && [ $installStatus -eq 0 ]; then
    [ ! -f "$crdl/logo_chrome_chromium_512dp.png" ] && curl -L --progress-bar -C - -o "$crdl/logo_chrome_chromium_512dp.png" "https://chromiumdash.appspot.com/static/images/logo_chrome_chromium_512dp.png"
    CreateBinaryLauncherShortcuts "Chromium" "$crdl/logo_chrome_chromium_512dp.png" "/opt/$crZIP/chrome" "false" "WebBrowser"
  fi
}

systemdService() {
  systemctl list-timers --all --no-pager | grep -q "crup.service" && sudo systemctl stop crup.service
  sudo tee "/etc/systemd/system/crup.service" > /dev/null <<EOL
[Unit]
Description=Chromium Update Task
After=network.target

[Service]
Type=oneshot
EOL
  sudo tee -a "/etc/systemd/system/crup.service" > /dev/null <<EOL
ExecStart=/usr/bin/bash /usr/local/bin/crup
User=root
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

[Install]
WantedBy=multi-user.target
EOL
  
  if [ "$Scheduler" != "None" ] || [ "$Timer" != "None" ]; then
    systemctl list-timers --all --no-pager | grep -q "crup.timer" && sudo systemctl stop crup.timer
    sudo tee "/etc/systemd/system/crup.timer" > /dev/null <<EOL
[Unit]
Description=Timer for Chromium Update

[Timer]
EOL
    [ "$Scheduler" != "None" ] && echo -e "OnActiveSec=5s\nOnUnitActiveSec=$Scheduler" | sudo tee -a "/etc/systemd/system/crup.timer" > /dev/null
    [ "$Timer" != "None" ] && echo "OnCalendar=*-*-* $Timer:00" | sudo tee -a "/etc/systemd/system/crup.timer" > /dev/null
    sudo tee -a "/etc/systemd/system/crup.timer" > /dev/null <<EOL
Persistent=true

[Install]
WantedBy=timers.target
EOL
  fi
  sudo systemctl daemon-reload
  sudo systemctl enable crup.service
  ([ "$Scheduler" != "None" ] || [ "$Timer" != "None" ]) && sudo systemctl enable --now crup.timer
  sudo systemctl start crup.service; sudo systemctl status crup.service --no-pager
  ([ "$Scheduler" != "None" ] || [ "$Timer" != "None" ]) && { sudo systemctl start crup.timer; sudo systemctl status crup.timer --no-pager; }
}
