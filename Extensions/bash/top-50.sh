#!/bin/bash

urls=(
  #"https://chromewebstore.google.com/detail/chrome-web-store-launcher/gecgipfabdickgidpmbicneamekgbaej"  # Chrome Web Store Launcher (by Google) MV2
  #"https://github.com/prem-k-r/CRXtract"  # download the extension CRX file
  "https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh"  # uBlock Origin Lite
  "https://chromewebstore.google.com/detail/adguard-adblocker/bgnkhhnnamicmpeenaelnjfhikgbkllg"  # AdGuard AdBlocker
  "https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh"  # Dark Reader
  "https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb"  # Bitwarden Password Manager
  "https://chromewebstore.google.com/detail/proton-pass-free-password/ghmbeldphafepmbegfdlkpapadhbakde"  # Proton Pass
  "https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo"  # Tampermonkey
  "https://greasyfork.org/en/scripts/10096-general-url-cleaner"  # General URL Cleaner
  "https://chromewebstore.google.com/detail/sponsorblock-for-youtube/mnjggcdmjocbbbhaepdhchncahnbgone"  # SponsorBlock for YouTube
  "https://chromewebstore.google.com/detail/google-translate/aapbdbdomjkkjkaonfhkkikfgjllcleb"  # Google Translate
  "https://chromewebstore.google.com/detail/twp-translate-beta/gkkkcomfmldkigajkmljnbpiajbpbgdg"  # TWP - Translate
  "https://chromewebstore.google.com/detail/search-by-image/cnojnbdhbhnkbcieeekonklommdnndci"  # Search by Image
  "https://chromewebstore.google.com/detail/user-agent-switcher-and-m/bhchdcejhohfmigjafbampogmaanbfkg"  # User-Agent Switcher and Manager
  "https://chromewebstore.google.com/detail/adguard-vpn-%E2%80%94-free-secure/hhdobjgopfphlmjbmnpglhfcgppchgje"  # AdGuard VPN
  "https://chromewebstore.google.com/detail/proton-vpn-fast-secure/jplgfhpmjnbigmhklmmbgecoobifkmpa"  # Proton VPN
  "https://chromewebstore.google.com/detail/read-aloud-a-text-to-spee/hdhinadidafjejdhmfkjgnolgimiaplp"  # Read Aloud
  #"https://chromewebstore.google.com/detail/clearurls/lckanjgmijmafbedllaakclkaicjfmnk"  # ClearURLs MV2
  #"https://chromewebstore.google.com/detail/linkumori-urls-cleaner/kcpfnbjlimolkcjllfooaipdpdjmjigg"  # Clean URLs MV3 by Linkumori
  "https://chromewebstore.google.com/detail/keepa-amazon-price-tracke/neebplgakaahbhdphmkckjjcegoiijjo"  # Keepa
  "https://chromewebstore.google.com/detail/popup-blocker-strict/aefkmifgmaafnojlojpnekbpbmjiiogg"  # Popup Blocker (strict)
  "https://chromewebstore.google.com/detail/unhook-remove-youtube-rec/khncfooichmfjbepaaaebmommgaepoid"  # Unhook
  #"https://chromewebstore.google.com/detail/absolute-enable-right-cli/jdocbkpgdakpekjlhemmfcncgdjeiika"  # Absolute Enable Right Click & Copy MV2
  "https://chromewebstore.google.com/detail/activate-enable-right-cli/pkoccklolohdacbfooifnpebakpbeipc"  # Activate Enable Right Click & Copy MV3
  #"https://chromewebstore.google.com/detail/firefox-relay/lknpoadjjkjcmjhbjpcljdednccbldeb"  # Firefox Relay MV2
  "https://chromewebstore.google.com/detail/onetab/chphlpgkkbolifaimnlloiipkdnihall"  # OneTab
  "https://chromewebstore.google.com/detail/blocksite-block-websites/eiimnmioipafcokbfikbljfdeojpcgbh"  # BlockSite: Block Websites
  #"https://chromewebstore.google.com/detail/cookie-autodelete/fhcgjolkccmbidfldomjliifgaodjagh"  # Cookie AutoDelete MV2
  "https://github.com/median-dxz/Cookie-AutoDelete-MV3/releases"  # Cookie-AutoDelete-MV3
  "https://chromewebstore.google.com/detail/enhancer-for-youtube/ponfpcnoihfmfllpaingbgckeeldkhle"  # Enhancer for YouTube
  "https://chromewebstore.google.com/detail/buster-captcha-solver-for/mpbjkejclgfgadiemmefgebjfooflfhl"  # Buster: Captcha Solver
  "https://chromewebstore.google.com/detail/h264ify/aleakchihdccplidncghkekgioiakgal"  # h264ify
  "https://chromewebstore.google.com/detail/ultrawideo/bfbnagnphiehemkdgmmficmjfddgfhpl"  # UltraWideo
  "https://chromewebstore.google.com/detail/ublacklist/pncfbmialoiaghdehhbnbhkkgmjanfhe"  # uBlacklist
  #"https://chromewebstore.google.com/detail/dont-f-with-paste/nkgllhigpcljnhoakjkgaieabnkmgdkb"  # Don't F*** With Paste
  "https://chromewebstore.google.com/detail/temp-mail-disposable-temp/inojafojbhdpnehkhhfjalgjjobnhomj"  # Temp Mail - Disposable Temporary Email
  "https://chromewebstore.google.com/detail/google-analytics-opt-out/fllaojicojecljbmefodhfapmkghcbnh"  # Google Analytics Opt-out Add-on (by Google)
  "https://chromewebstore.google.com/detail/video-roll-all-in-one-vid/cokngoholafkeghnhhdlmiadlojpindm"  # Video Roll
  "https://chromewebstore.google.com/detail/scroll-to-top/hegiignepmecppikdlbohnnbfjdoaghj"  # Scroll To Top
  "https://chromewebstore.google.com/detail/video-resumer/bongjkoajofkfpofginnhecihgaeldpe"  # Video Resumer
  "https://chromewebstore.google.com/detail/thumbnail-rating-bar-for/cmlddjbnoehmihdmfhaacemlpgfbpoeb"  # Thumbnail Rating Bar for YouTube
  "https://chromewebstore.google.com/detail/url-shortener/oodfdmglhbbkkcngodjjagblikmoegpa"  # Url Shortener
  "https://chromewebstore.google.com/detail/seedr/abfimpkhacgimamjbiegeoponlepcbob"  # Seedr
  "https://chromewebstore.google.com/detail/webtorio-watch-torrents-o/ngkpdaefpmokglfnmienfiaioffjodam"  # Webtor.io - Watch torrents online
  "https://chromewebstore.google.com/detail/return-youtube-dislike/gebbhagfogifgggkldgodflihgfeippi"  # Return YouTube Dislike
  "https://chromewebstore.google.com/detail/video-speed-controller/nffaoalbilbmmfgbnbgppjihopabppdk"  # Video Speed Controller
  "https://chromewebstore.google.com/detail/honey-automatic-coupons-r/bmnlcjabgnpnenekpadlanbbkooimhnj"  # Honey: Automatic Coupons
  #"https://chromewebstore.google.com/detail/imagus/immpkjjlgappgfkkfieppnmlhakdmaab"  # Imagus MV2
  "https://chromewebstore.google.com/detail/tineye-reverse-image-sear/haebnnbpedcbhciplfhjjkbafijpncjl"  # TinEye Reverse Image Search
  "https://chromewebstore.google.com/detail/wot-website-security-safe/bhmmomiinigofkjcapegjjndpbikblnp"  # WOT: Website Security & Safety Checker
  "https://chromewebstore.google.com/detail/floccus-bookmarks-sync/fnaicdffflnofjppbagibeoednhnbjhg"  # floccus bookmarks sync
  "https://chromewebstore.google.com/detail/audio-only-youtube/pkocpiliahoaohbolmkelakpiphnllog"  # Audio Only Youtube
  "https://chromewebstore.google.com/detail/similar-sites-discover-re/necpbmbhhdiplmfhmjicabdeighkndkn"  # Similar Sites - Discover Related Websites
  "https://chromewebstore.google.com/detail/mute-tab/ogbpneobokibiimcnecppphklbpcibfo"  # Mute Tab
  "https://chromewebstore.google.com/detail/ai-grammar-checker-paraph/oldceeleldhonbafppcapldpdifcinji"  # AI Grammar Checker
  "https://chromewebstore.google.com/detail/chatgpt-for-google/jgjaeacdkonaoafenlfkkkmbaopkbilf"  # ChatGPT for Google
  "https://chromewebstore.google.com/detail/i-dont-care-about-cookies/fihnjjcciajhdojfnbdddfaoknhalnja"  # I don't care about cookies
  "https://chromewebstore.google.com/detail/picture-in-picture-extens/hkgfoiooedgoejojocmhlaklaeopbecg"  # Picture-in-Picture Extension (by Google)
  #"https://chromewebstore.google.com/detail/tabcloud/npecfdijgoblfcgagoijgmgejmcpnhof"  # TabCloud MV2
  "https://chromewebstore.google.com/detail/uautopagerize/kdplapeciagkkjoignnkfpbfkebcfbpb"  # uAutoPagerize
  "https://chromewebstore.google.com/detail/wa-web-plus-by-elbruz-tec/ekcgkejcjdcmonfpmnljobemcbpnkamh"  # WA Web Plus by Elbruz Technologies
  "https://chromewebstore.google.com/detail/noscript/doojmbjmlfjjnbmnoijecmcbfeoakpjm"  # NoScript
)

# Open first URL in a *new* window, then others as tabs in the same window
open -na "/Applications/Chromium.app" --args --new-window "${urls[0]}"
sleep 1  # Small delay to ensure the window opens
for url in "${urls[@]:1}"; do
  open -a "/Applications/Chromium.app" "$url"  # Opens subsequent URLs as tabs in the existing window
done