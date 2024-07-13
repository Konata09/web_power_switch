#!/bin/bash

PLATFORM="unknown"

# OS Checking
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  PLATFORM="darwin"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
  PLATFORM="bsd"
elif [[ "$OSTYPE" == "openbsd"* ]]; then
  PLATFORM="bsd"
elif [[ "$OSTYPE" == "netbsd"* ]]; then
  PLATFORM="bsd"
elif [[ "$OSTYPE" == "solaris"* ]]; then
  PLATFORM="solaris"
fi

GREP="grep -E"

if [[ "$PLATFORM" == "linux" ]]; then
  GREP="grep -P"
fi

HOST="192.168.10.3"       # IP Address
USER=admin                # Username
PASSWORD=$WPS_PASSWORD    # Password

# $1=HEX number
# $2=Position in BIN number
function get_bit() {
    local hex_number="$1"
    local bit_position="$2"

    local decimal_number=$((16#$hex_number))

    local bit_value=$(( (decimal_number >> bit_position) & 1 ))

    echo "$bit_value"
}

# $1=Outlet number
function GetStatusByOutlet() {
  htmlText=$(curl -s http://$USER:"$PASSWORD"@$HOST/status)

  state=$(echo "$htmlText" | $GREP -o '(?<=div id="state">)[^<]+')
#  lock=$(echo "$htmlText" | $GREP -o '(?<=div id="lock">)[^<]+')
#  perm=$(echo "$htmlText" | $GREP -o '(?<=div id="perm">)[^<]+')

  bit_position=$(($1 - 1))
  bit_value=$(get_bit "$state" "$bit_position")
  echo $bit_value
}

# $1=Outlet number
function TurnOn() {
  curl -s --no-progress-meter http://$USER:"$PASSWORD"@"$HOST"/outlet?"$1"=ON > /dev/null
}
# $1=Outlet number
function TurnOff() {
  curl -s --no-progress-meter http://$USER:"$PASSWORD"@"$HOST"/outlet?"$1"=OFF > /dev/null
}
# $1=Outlet number
function Cycle() {
  curl -s --no-progress-meter http://$USER:"$PASSWORD"@"$HOST"/outlet?"$1"=CCL > /dev/null
}

# $1=Script line
function RunScript() {
  NUM=$(printf "%03d" "$1")
  curl -s --no-progress-meter http://$USER:"$PASSWORD"@"$HOST"/script?run"$NUM" > /dev/null
}

function PrintUsage() {
  echo "Usage: web_power_switch.sh COMMAND OUTLET/LINE [ACTION]"
  echo ""
  echo "  COMMAND: "
  echo "    set       Perform an action on outlet"
  echo "    get       Get outlet status"
  echo "    run       run script line configured in switch"
  echo "  OUTLET/LINE: "
  echo "    <number>  Outlet number (0~8) or Script line number"
  echo "  ACTION: "
  echo "    on        turn outlet on"
  echo "    off       turn outlet off"
  echo "    cycle     cycle a outlet"
}

if [[ "$1" == get ]]; then
  if [[ -z "$2" ]]; then
    PrintUsage
  else
    GetStatusByOutlet "$2"
  fi
elif [[ "$1" == set ]]; then
  if [[ -z "$2" ]]; then
    PrintUsage
  else
    if [[ "$3" == on ]]; then
      TurnOn "$2"
    elif [[ "$3" == off ]]; then
      TurnOff "$2"
    elif [[ "$3" == cycle ]]; then
      Cycle "$2"
    else
      PrintUsage
    fi
  fi
elif [[ "$1" == run ]]; then
  if [[ -z "$2" ]]; then
    PrintUsage
  else
    RunScript "$2"
  fi
else
  PrintUsage
fi
