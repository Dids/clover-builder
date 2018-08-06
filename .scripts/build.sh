#!/usr/bin/env bash

# Setup error handling
set -o errexit   # Exit when a command fails (set -e)
set -o nounset   # Exit when using undeclared variables (set -u)
set -o pipefail  # Exit when piping fails
#set -o xtrace    # Enable debugging (set -x)

# Setup the log file
LOG_PATH="$(echo ~/Clover_Build.log)"
echo "" > ${LOG_PATH} 2>&1

# Simple function for generating at timestamp
function timestamp ()
{
  echo -ne "\033[33m$(date +%FT%T%Z)\033[39m ";
  $@
  echo -ne "\033[0m"
}

# Handle error signals
function error ()
{
  timestamp echo -e "\033[31mBuild failed!\033[0m\n\nSee the build log for more information: ${LOG_PATH}"
  echo ""
}
trap error ERR

# Stupid Clover ascii art function
function print_clover_banner ()
{
  cat << "EOF"

       (       )            (                 (   (   (         (     
   (   )\ ) ( /(            )\ )     (        )\ ))\ ))\ )      )\ )  
   )\ (()/( )\())(   (  (  (()/(   ( )\    ( (()/(()/(()/(  (  (()/(  
 (((_) /(_)|(_)\ )\  )\ )\  /(_))  )((_)   )\ /(_))(_))(_)) )\  /(_)) 
 )\___(_))   ((_|(_)((_|(_)(_))   ((_)_ _ ((_|_))(_))(_))_ ((_)(_))   
((/ __| |   / _ \ \ / /| __| _ \   | _ ) | | |_ _| |  |   \| __| _ \  
 | (__| |__| (_) \ V / | _||   /   | _ \ |_| || || |__| |) | _||   /  
  \___|____|\___/ \_/  |___|_|_\   |___/\___/|___|____|___/|___|_|_\

                    _          ____  _   _     
                   | |_ _ _   |    \|_|_| |___ 
                   | . | | |  |  |  | | . |_ -|
                   |___|_  |  |____/|_|___|___|
                       |___|                   

EOF
}

# Keep track of execution time
START_TIME=$(date +%s)

# Print a Clover ascii art logo
echo ""
print_clover_banner
echo ""

# Print useful information
echo -e "\033[95mTarget revision:\033[39m ${CLOVER_REVISION:-HEAD}"
echo -e "\033[95mBuild log:\033[39m ${LOG_PATH}"
echo ""

# Setup the root path
SRC="$(echo ~/src)"

# Make sure the working directory exists and switch to it
mkdir -p "${SRC}"
cd "${SRC}"

# Install or update UDK2018
UDK2018_REPO="https://github.com/tianocore/edk2"
UDK2018_BRANCH="UDK2018"
UDK2018_PATH="$(echo ${SRC}/UDK2018)"
if [ ! -d "${UDK2018_PATH}/.git" ]; then
  timestamp echo "Checking out a fresh copy of UDK.."
  git clone "${UDK2018_REPO}" -b "${UDK2018_BRANCH}" --depth 1 "${UDK2018_PATH}" >> ${LOG_PATH} 2>&1
fi
timestamp echo "Checking for updates to UDK.."
cd "${UDK2018_PATH}"
git clean -fdx --exclude="Clover/" >> ${LOG_PATH} 2>&1
git pull >> ${LOG_PATH} 2>&1

# Install or update Clover
CLOVER_REPO="https://svn.code.sf.net/p/cloverefiboot/code"
CLOVER_PATH="$(echo ${UDK2018_PATH}/Clover)"
if [ ! -d "${CLOVER_PATH}/.svn" ]; then
  timestamp echo "Checking out a fresh copy of Clover.."
  svn co "${CLOVER_REPO}" "${CLOVER_PATH}" >> ${LOG_PATH} 2>&1
fi
timestamp echo "Checking for updates to Clover.."
cd "${CLOVER_PATH}"
svn revert -R . >> ${LOG_PATH} 2>&1
svn cleanup --remove-unversioned >> ${LOG_PATH} 2>&1
svn up -r${CLOVER_REVISION:-HEAD} >> ${LOG_PATH} 2>&1

# Switch back to the UDK root
cd "${UDK2018_PATH}"

# Export the toolchain directory
export TOOLCHAIN_DIR="$(echo ${SRC}/opt/local)"

# Compile the base tools
timestamp echo "Building base tools.."
make -C ${UDK2018_PATH}/BaseTools/Source/C >> ${LOG_PATH} 2>&1

# Setup UDK
timestamp echo "Setting up UDK.."
set +o nounset
#source ${UDK2018_PATH}/edksetup.sh >> ${LOG_PATH} 2>&1
source edksetup.sh >> ${LOG_PATH} 2>&1
set -o nounset

# Switch to the Clover root
cd "${CLOVER_PATH}"

# Build gettext, mtoc and nasm (only if necessary)
if [ ! -f "${SRC}/opt/local/bin/gettext" ]; then timestamp echo "Building gettext, this may take a while.."; ./buildgettext.sh  >> ${LOG_PATH} 2>&1; fi
if [ ! -f "${SRC}/opt/local/bin/mtoc.NEW" ]; then timestamp echo "Building mtoc, this may take a while.."; ./buildmtoc.sh  >> ${LOG_PATH} 2>&1; fi
if [ ! -f "${SRC}/opt/local/bin/nasm" ]; then timestamp echo "Building nasm, this may take a while.."; ./buildnasm.sh  >> ${LOG_PATH} 2>&1; fi

# Install UDK patches
timestamp echo "Applying UDK patches.."
cp -R ${CLOVER_PATH}/Patches_for_UDK2018/* ../ >> ${LOG_PATH} 2>&1

# Build Clover (clean & build with extras)
timestamp echo "Cleaning Clover.."
./ebuild.sh -cleanall >> ${LOG_PATH} 2>&1
timestamp echo "Building Clover, this may take a while.."
./ebuild.sh -fr --x64-mcp --ext-co >> ${LOG_PATH} 2>&1

# Modify the package credits to differentiate between
# the official packges and custom-built ones
CREDITS_ORIGINAL="Chameleon team, crazybirdy, JrCs."
CREDITS_MODIFIED="Chameleon team, crazybirdy, JrCs. Custom package by Dids."
sed -i '' -e "s/.*${CREDITS_ORIGINAL}.*/${CREDITS_MODIFIED}/" "${CLOVER_PATH}/CloverPackage/CREDITS"

# Build the Clover installer package
timestamp echo "Creating Clover installer.."
${CLOVER_PATH}/CloverPackage/makepkg >> ${LOG_PATH} 2>&1

# Calculate and show execution time in minutes
END_TIME=$(date +%s)
EXEC_TIME=$(( $END_TIME - $START_TIME ))
EXEC_RESULT=$(expr ${EXEC_TIME:-0} / 60)
timestamp echo -e "\033[32mFinished in $EXEC_RESULT minute(s)!\033[0m"
