<h1 align="center">cr >_dl</h1>
<p align="center">
A feature-rich command-line Chromium Downloader for Android/ macOS.
<br>
<br>
<img src="docs/images/Main.png">
<br>

## Purpose
- This script automates the process of downloading Chromium using shell script.

## Feature
- Downloads the latest version of Chromium.
- written in bash shell script.
- Custom channel support (e.g. stable, beta, dev, canary, last canary).
- Support macOS and Android 8+ (arm64-v8a, armeabi-v7a, x86_64), more platforms will be added soon..
- Built in Updating Checks feature.
- Auto Delete the downloaded file after installation complete.
- Support SU (ROOT and Shizuku) Installer method.
- Fallback to Session installer if SU installer not present.
- Prefer 32-bit apk if device is usually low on memory (lessthen 4GB RAM).
- User Friendly, Free and Open Source.
- Smaller size script (20 KB), allowing you to save space on your device.

## Prerequisites
- macOS computer with working internet connection.
- Android device with working internet connection.
- Android device with root access (optional).

## Usage
### Android
  - Open [Termux](https://github.com/termux/termux-app/releases/) and run the script with the following command:
  ```
  curl -o "$HOME/.crdl" https://raw.githubusercontent.com/arghya339/crdl/main/Termux/crdl.sh && bash "$HOME/.crdl"
  ```
  Run crdl with these commands in Termux:
  ```
  crdl
  ```
> This script was tested on an arm64-v8a device running Android 14 with Termux v0.118.2 with bash v5.2.37(1).

### macOS
  - Open macOS Terminal and run the script with the following command:
  ```
  curl -o "$HOME/.crdl" https://raw.githubusercontent.com/arghya339/crdl/main/macOS/crdl.sh && bash $HOME/.crdl
  ```
  Run crdl with these commands in Terminal:
  ```
  crdl
  ```
> This script was tested on an Intel Mac running macOS Sonoma (14) with Terminal v2.14(453) with bash v3.2.57.

## How it works (_[Demo on YouTube](https://youtube.com/)_)

![image](docs/images/Result_Android.png)

## Disclaimer
- Chromium is an open-source browser project, developed and maintained by Google.

## Devoloper info
- Powered by [Chromium](https://www.chromium.org/Home/)
- Inspired by [chromium-latest-linux](https://github.com/scheib/chromium-latest-linux)
- Developer: [@arghya339](https://github.com/arghya339)

## Keep cruising the web
