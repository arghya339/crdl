#!/usr/bin/bash

urls=(
  "https://github.com/prem-k-r/CRXtract"  # download the extension CRX file
  "https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh"  # uBlock Origin Lite
  #"https://chromewebstore.google.com/detail/popup-blocker-strict/aefkmifgmaafnojlojpnekbpbmjiiogg"  # Popup Blocker (strict)
  #"https://chromewebstore.google.com/detail/floccus-bookmarks-sync/fnaicdffflnofjppbagibeoednhnbjhg"  # floccus bookmarks sync
  "https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh"  # Dark Reader
  #"https://chromewebstore.google.com/detail/scroll-to-top/hegiignepmecppikdlbohnnbfjdoaghj"  # Scroll To Top
  #"https://chromewebstore.google.com/detail/ultrawideo/bfbnagnphiehemkdgmmficmjfddgfhpl"  # UltraWideo
  #"https://chromewebstore.google.com/detail/user-agent-switcher-and-m/bhchdcejhohfmigjafbampogmaanbfkg"  # User-Agent Switcher and Manager
  "https://chromewebstore.google.com/detail/buster-captcha-solver-for/mpbjkejclgfgadiemmefgebjfooflfhl"  # Buster: Captcha Solver
  #"https://chromewebstore.google.com/detail/keepa-amazon-price-tracke/neebplgakaahbhdphmkckjjcegoiijjo"  # Keepa
  #"https://chromewebstore.google.com/detail/dont-f-with-paste/nkgllhigpcljnhoakjkgaieabnkmgdkb"  # Don't F*** With Paste
)

# Launch Chromium if not already running
am start -n org.chromium.chrome/org.chromium.chrome.browser.ChromeTabbedActivity > /dev/null 2>&1

# Wait for Chromium to initialize
sleep 1

# Open URLs in new tabs using Android's intent system
for url in "${urls[@]}"; do
    am start -n org.chromium.chrome/org.chromium.chrome.browser.ChromeTabbedActivity \
        -a android.intent.action.VIEW \
        -d "$url" > /dev/null 2>&1
    sleep 0.5
done
