#!/bin/bash

function trap_exit() {
  echo "stopping... $(jobs -p)"
  kill $(jobs -p) > /dev/null 2>&1 || echo "already killed."
  if [ "$DISABLE_PCSCD" != "1" ] && [ -e "/etc/init.d/pcscd" ]; then
    /etc/init.d/pcscd stop
  fi
  sleep 1
  echo "exit."
}
trap "exit 0" 2 3 15
trap trap_exit 0

if [ "$DISABLE_PCSCD" != "1" ] && [ -e "/etc/init.d/pcscd" ]; then
  while :; do
    # Only modify /etc/default/pcscd for version 2.0.0 and above
    PCSCD_VERSION=$(pcscd --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    PCSCD_MAJOR=$(echo "$PCSCD_VERSION" | cut -d. -f1 2>/dev/null)
    echo "pcscd version: ${PCSCD_VERSION:-unknown}"
    if [ "$PCSCD_MAJOR" -ge 2 ] 2>/dev/null; then
      echo "DAEMON_ARGS=\"--disable-polkit\"" > /etc/default/pcscd
      echo "polkit disabled in /etc/default/pcscd"
    else
      echo "skipping /etc/default/pcscd modification (version < 2.0.0)"
    fi
    echo "starting pcscd..."
    /etc/init.d/pcscd start
    sleep 1
    timeout 2 pcsc_scan | grep -A 50 "Using reader plug'n play mechanism"
    if [ $? = 0 ]; then
      break;
    fi
    echo "failed!"
  done
fi

echo "Start a dantto4k..."
DANTTO4K_ARGS="${DANTTO4K_ARGS:-- -}"
if [ -z "$DANTTO4K_ARGS" ]; then
  echo "No arguments provided for dantto4k, using default: - -"
else
  echo "Using provided arguments for dantto4k: $DANTTO4K_ARGS"
fi

function start() {
<<<<<<< HEAD
  socat tcp-listen:40775,fork,reuseaddr,keepalive,keepidle=10,keepintvl=10,keepcnt=3 "system:/usr/local/bin/dantto4k $DANTTO4K_ARGS" &
=======
  socat tcp-listen:40775,fork,reuseaddr,keepalive,keepidle=5,keepintvl=10,keepcnt=3,so-rcvtimeo=5,so-sndtimeo=5 "system:/usr/local/bin/dantto4k $DANTTO4K_ARGS" &
>>>>>>> 2b66dee (改善: socatコマンドのtimeoutオプションを詳細なkeepalive設定に変更)
  wait
}

function restart() {
  echo "restarting... $(jobs -p)"
  kill $(jobs -p) > /dev/null 2>&1 || echo "already killed."
  sleep 1
  start
}
trap restart 1

start
