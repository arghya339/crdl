#!/usr/bin/bash

urls=(
  "https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh"  # uBlock Origin Lite
  "https://chromewebstore.google.com/detail/adguard-adblocker/bgnkhhnnamicmpeenaelnjfhikgbkllg"  # AdGuard AdBlocker
  "https://chromewebstore.google.com/detail/adblocker-ultimate/ohahllgiabjaoigichmmfljhkcfikeof"  # AdBlocker Ultimate
  "https://chromewebstore.google.com/detail/sponsorblock-for-youtube/mnjggcdmjocbbbhaepdhchncahnbgone"  # SponsorBlock for YouTube
  "https://chromewebstore.google.com/detail/unhook-remove-youtube-rec/khncfooichmfjbepaaaebmommgaepoid"  # Unhook
  "https://chromewebstore.google.com/detail/enhancer-for-youtube/ponfpcnoihfmfllpaingbgckeeldkhle"  # Enhancer for YouTube
  #"https://chromewebstore.google.com/detail/h264ify/aleakchihdccplidncghkekgioiakgal"  # h264ify
  "https://chromewebstore.google.com/detail/return-youtube-dislike/gebbhagfogifgggkldgodflihgfeippi"  # Return YouTube Dislike
  "https://chromewebstore.google.com/detail/thumbnail-rating-bar-for/cmlddjbnoehmihdmfhaacemlpgfbpoeb"  # Thumbnail Rating Bar for YouTube
  "https://chromewebstore.google.com/detail/popup-blocker-strict/aefkmifgmaafnojlojpnekbpbmjiiogg"  # Popup Blocker (strict)
  "https://chromewebstore.google.com/detail/linkumori-urls-cleaner/kcpfnbjlimolkcjllfooaipdpdjmjigg"  # Clean URLs MV3 by Linkumori
  # "https://github.com/prem-k-r/CRXtract"  # download the extension CRX file
  # "https://microsoftedge.microsoft.com/addons/detail/redirect-amp-to-html/abjhjmfkmdfggjomfpojjfcehhkambcc"  # Redirect AMP to HTML MV2
  "https://chromewebstore.google.com/detail/floccus-bookmarks-sync/fnaicdffflnofjppbagibeoednhnbjhg"  # floccus bookmarks sync
  "https://chromewebstore.google.com/detail/bookmarkhub-sync-bookmark/fohimdklhhcpcnpmmichieidclgfdmol"  # BookmarkHub
  "https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb"  # Bitwarden Password Manager
  "https://chromewebstore.google.com/detail/proton-pass-free-password/ghmbeldphafepmbegfdlkpapadhbakde"  # Proton Pass
  # "https://chromewebstore.google.com/detail/tabcloud/npecfdijgoblfcgagoijgmgejmcpnhof"  # TabCloud MV2
  "https://chromewebstore.google.com/detail/twp-translate-beta/gkkkcomfmldkigajkmljnbpiajbpbgdg"  # TWP - Translate
  "https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh"  # Dark Reader
  "https://chromewebstore.google.com/detail/picture-in-picture-extens/hkgfoiooedgoejojocmhlaklaeopbecg"  # Picture-in-Picture
  "https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo"  # Tampermonkey
  "https://greasyfork.org/en/scripts/371641-video-background-play-fix/"  # Video Background Play Fix
  "https://chromewebstore.google.com/detail/uautopagerize/kdplapeciagkkjoignnkfpbfkebcfbpb"  # uAutoPagerize
  "https://chromewebstore.google.com/detail/wot-website-security-safe/bhmmomiinigofkjcapegjjndpbikblnp"  # WOT: Website Security Checker
  ##"https://chromewebstore.google.com/detail/chatgpt-for-google/jgjaeacdkonaoafenlfkkkmbaopkbilf"  # ChatGPT for Google
  #"https://chromewebstore.google.com/detail/ai-grammar-checker-paraph/oldceeleldhonbafppcapldpdifcinji"  # LT: AI Grammar Checker
  "https://chromewebstore.google.com/detail/block-site/lebiggkccaodkkmjeimmbogdedcpnmfb"  # Block Site
  "https://chromewebstore.google.com/detail/ublacklist/pncfbmialoiaghdehhbnbhkkgmjanfhe"  # uBlacklist
  "https://chromewebstore.google.com/detail/temp-mail-disposable-temp/inojafojbhdpnehkhhfjalgjjobnhomj"  # Temp Mail
  "https://chromewebstore.google.com/detail/scroll-to-top/hegiignepmecppikdlbohnnbfjdoaghj"  # Scroll To Top
  "https://chromewebstore.google.com/detail/ultrawideo/bfbnagnphiehemkdgmmficmjfddgfhpl"  # UltraWideo
  #"https://chromewebstore.google.com/detail/seedr/abfimpkhacgimamjbiegeoponlepcbob"  # Seedr
  "https://chromewebstore.google.com/detail/user-agent-switcher-and-m/bhchdcejhohfmigjafbampogmaanbfkg"  # User-Agent Switcher and Manager
  ##"https://chromewebstore.google.com/detail/adguard-vpn-%E2%80%94-free-secure/hhdobjgopfphlmjbmnpglhfcgppchgje"  # AdGuard VPN
  ##"https://chromewebstore.google.com/detail/proton-vpn-fast-secure/jplgfhpmjnbigmhklmmbgecoobifkmpa"  # Proton VPN
  "https://chromewebstore.google.com/detail/buster-captcha-solver-for/mpbjkejclgfgadiemmefgebjfooflfhl"  # Buster: Captcha Solver
  "https://chromewebstore.google.com/detail/keepa-amazon-price-tracke/neebplgakaahbhdphmkckjjcegoiijjo"  # Keepa
  #"https://chromewebstore.google.com/detail/honey-automatic-coupons-r/bmnlcjabgnpnenekpadlanbbkooimhnj"  # Honey: Automatic Coupons
  # "https://chromewebstore.google.com/detail/cookie-autodelete/fhcgjolkccmbidfldomjliifgaodjagh"  # Cookie AutoDelete MV2
  "https://chromewebstore.google.com/detail/i-dont-care-about-cookies/fihnjjcciajhdojfnbdddfaoknhalnja"  # I don't care about cookies
  # "https://chromewebstore.google.com/detail/absolute-enable-right-cli/jdocbkpgdakpekjlhemmfcncgdjeiika"  # Absolute Enable Right Click & Copy MV2
  "https://chromewebstore.google.com/detail/dont-f-with-paste/nkgllhigpcljnhoakjkgaieabnkmgdkb"  # Don't F*** With Paste
)

# Launch Chromium if not already running
am start -n org.chromium.chrome/org.chromium.chrome.browser.ChromeTabbedActivity > /dev/null 2>&1

# Wait for Chromium to initialize
sleep 1

# Open URLs in new tabs using Android's intent system
for url in "${urls[@]}"; do
    am start -n org.chromium.chrome/org.chromium.chrome.browser.ChromeTabbedActivity -a android.intent.action.VIEW -d "$url" > /dev/null 2>&1
    sleep 0.5
done
