#!/bin/bash

set -e

trap "trap_ctrlc" 2

ROOT_DIR=$(pwd)
SKIP_BROWSER="0"
SKIP_PREDIX_SERVICES=false
LOGIN=1
function local_read_args() {
  while (( "$#" )); do
  opt="$1"
  case $opt in
    -h|-\?|--\?--help)
      PRINT_USAGE=1
      QUICKSTART_ARGS="$SCRIPT $1"
      break
    ;;
    -b|--branch)
      BRANCH="$2"
      QUICKSTART_ARGS+=" $1 $2"
      shift
    ;;
    -o|--override)
      RECREATE_TAR="1"
      QUICKSTART_ARGS=" $SCRIPT"
    ;;
    --skip-setup)
      SKIP_SETUP=true
    ;;
    -skip-predix-services|--skip-predix-services)
      SKIP_PREDIX_SERVICES="true"
      LOGIN=0
    ;;
    *)
      QUICKSTART_ARGS+=" $1"
      #echo $1
    ;;
  esac
  shift
  done

  if [[ -z $BRANCH ]]; then
    echo "Usage: $0 -b/--branch <branch> [--skip-setup]"
    exit 1
  fi
}

# default settings
BRANCH="master"
PRINT_USAGE=0
SKIP_SETUP=false

IZON_SH="https://raw.githubusercontent.com/PredixDev/izon/1.2.0/izon2.sh"
#ASSET_MODEL="-amrmd predix-ui-seed/server/sample-data/predix-asset/asset-model-metadata.json predix-ui-seed/server/sample-data/predix-asset/asset-model.json"
#SCRIPT="-script build-basic-app.sh -script-readargs build-basic-app-readargs.sh"
SCRIPT="-script edge-starter-deploy.sh -script-readargs edge-starter-deploy-readargs.sh"
VERSION_JSON="version.json"
PREDIX_SCRIPTS=predix-scripts
REPO_NAME=predix-edge-ref-app
SCRIPT_NAME="quickstart-edge-ref-app-edgeos.sh"
GITHUB_RAW="https://raw.githubusercontent.com/PredixDev"
APP_DIR="edge-ref-app-local"
APP_NAME="Predix Edge Reference App - predix edgeos"
TOOLS="Docker, VMWare Fusion"
TOOLS_SWITCHES="--docker --vmware"
TIMESERIES_CHART_ONLY="true"


# Process switches
local_read_args $@

#variables after processing switches
SCRIPT_LOC="$GITHUB_RAW/$REPO_NAME/$BRANCH/scripts/$SCRIPT_NAME"
VERSION_JSON_URL="$GITHUB_RAW/$REPO_NAME/$BRANCH/version.json"

echo "SKIP_PREDIX_SERVICES : $SKIP_PREDIX_SERVICES"
if [[ "$SKIP_PREDIX_SERVICES" == "true" ]]; then
  QUICKSTART_ARGS="$QUICKSTART_ARGS -repo-name $REPO_NAME -app-name $REPO_NAME -p -create-packages -deploy-edge-app $SCRIPT"
else
  QUICKSTART_ARGS="$QUICKSTART_ARGS -repo-name $REPO_NAME -app-name $REPO_NAME -p -create-packages -deploy-edge-app $SCRIPT"
fi

function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://google.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    echo "If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables."
    exit 1
  fi
  echo "OK"
  echo ""
}

function init() {
  currentDir=$(pwd)
  if [[ $currentDir == *"scripts" ]]; then
    echo 'Please launch the script from the root dir of the project'
    exit 1
  fi
  if [[ ! $currentDir == *"$REPO_NAME" ]]; then
    mkdir -p $APP_DIR
    cd $APP_DIR
  fi

  check_internet

  #get the script that reads version.json
  if [[ -n $GITHUB_BUILD_TOKEN && $IZON_SH = *"github.build.ge"* ]]; then
    IZON_SH="https://$GITHUB_BUILD_TOKEN@raw.githubusercontent.com/PredixDev/izon/$BRANCH/izon.sh"
  fi
  echo "IZON_SH : $IZON_SH"

  eval "$(curl -s -L $IZON_SH)"
  getUsingCurl $SCRIPT_LOC
  chmod 755 $SCRIPT_NAME;
  getVersionFile
  getLocalSetupFuncs $GITHUB_RAW
}

if [[ $PRINT_USAGE == 1 ]]; then
  init
  __print_out_standard_usage
else
  if $SKIP_SETUP; then
    init
  else
    init
    __standard_mac_initialization
  fi
fi

getPredixScripts
#clone the repo itself if running from oneclick script
getCurrentRepo

echo "quickstart_args=$QUICKSTART_ARGS"
source $PREDIX_SCRIPTS/bash/quickstart.sh $QUICKSTART_ARGS

echo "sleep 20 seconds"
sleep 20
echo "Open in Browser at http://$DEVICE_IP_ADDRESS:5000"
# Automagically open the application in browser, based on OS
if [[ $SKIP_BROWSER == 0 ]]; then
  app_url="http://$DEVICE_IP_ADDRESS:5000"

  case "$(uname -s)" in
     Darwin)
       # OSX
       open $app_url
       ;;
     Linux)
       # OSX
       if [[ $( which xdg-open | wc -l ) == 1 ]]; then
         xdg-open $app_url
       fi
       echo "Please open the browser on VM Host(not DevBox) and point to $app_url" >> $SUMMARY_TEXTFILE
       ;;
     CYGWIN*|MINGW32*|MINGW64*|MSYS*)
       # Windows
       start "" $app_url
       ;;
  esac
fi

cat $SUMMARY_TEXTFILE
__append_new_line_log "" "$logDir"
__append_new_line_log "Deployed Predix Edge Reference Application to Predix Edge OS!" "$quickstartLogDir"
__append_new_line_log "" "$logDir"
