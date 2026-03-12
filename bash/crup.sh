#!/bin/bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

[ "$(uname)" == "Darwin" ] && PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/arghya/bin"
ping -c 1 -W 2 8.8.8.8 &>/dev/null || exit 1
crup=booted
if [ -f "/etc/os-release" ]; then
  USER_HOME="$(getent passwd 1000 | cut -d: -f6)"
else
  USER_HOME="$HOME"
fi
source $USER_HOME/.crdl.sh
case "$Channel" in
  Extended) fetchReleases "Extended" ;;
  Stable) fetchReleases "Stable" ;;
  Beta) fetchReleases "Beta" ;;
  Dev) fetchReleases "Dev" ;;
  Canary) fetchReleases "Canary" ;;
  Canary\ Test) fetchPreReleases ;;
esac
