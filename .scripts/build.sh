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

# Keep track of execution time
START_TIME=$(date +%s)

# Print useful information
timestamp echo "Target revision: ${CLOVER_REVISION:-HEAD}"
timestamp echo "Build log: ${LOG_PATH}"

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
git pull >> ${LOG_PATH} 2>&1
git clean -fdx --exclude="Clover/" >> ${LOG_PATH} 2>&1

# Install or update Clover
CLOVER_REPO="https://svn.code.sf.net/p/cloverefiboot/code"
CLOVER_PATH="$(echo ${UDK2018_PATH}/Clover)"
if [ ! -d "${CLOVER_PATH}/.svn" ]; then
  timestamp echo "Checking out a fresh copy of Clover.."
  svn co "${CLOVER_REPO}" "${CLOVER_PATH}" >> ${LOG_PATH} 2>&1
fi
timestamp echo "Checking for updates to Clover.."
cd "${CLOVER_PATH}"
svn up -r${CLOVER_REVISION:-HEAD} >> ${LOG_PATH} 2>&1
svn revert -R . >> ${LOG_PATH} 2>&1
svn cleanup --remove-unversioned >> ${LOG_PATH} 2>&1

# Switch back to the UDK root
cd "${UDK2018_PATH}"

# Export the toolchain directory
export TOOLCHAIN_DIR="$(echo ${SRC}/opt/local)"

# Compile the base tools
timestamp echo "Building base tools.."
make -C BaseTools/Source/C >> ${LOG_PATH} 2>&1

# Setup UDK
timestamp echo "Setting up UDK.."
set +o nounset
#. edksetup.sh
#${UDK2018_PATH} edksetup.sh
#./edksetup.sh
source edksetup.sh >> ${LOG_PATH} 2>&1
set -o nounset

# Switch to the Clover root
cd "${CLOVER_PATH}"

# Build gettext, mtoc and nasm (only if necessary)
if [ ! -f "${SRC}/opt/local/bin/gettext" ]; then echo "Building gettex.."; ./buildgettext.sh  >> ${LOG_PATH} 2>&1; fi
if [ ! -f "${SRC}/opt/local/bin/mtoc.NEW" ]; then echo "Building mtoc.."; ./buildmtoc.sh  >> ${LOG_PATH} 2>&1; fi
if [ ! -f "${SRC}/opt/local/bin/nasm" ]; then echo "Building nasm.."; ./buildnasm.sh  >> ${LOG_PATH} 2>&1; fi

# Install UDK patches
timestamp echo "Applying UDK patches.."
cp -R Patches_for_UDK2018/* ../ >> ${LOG_PATH} 2>&1

# Build Clover (clean & build)
timestamp echo "Cleaning Clover.."
./ebuild.sh -cleanall >> ${LOG_PATH} 2>&1
timestamp echo "Building Clover, this may take a while.."
./ebuild.sh -fr >> ${LOG_PATH} 2>&1

# Modify the package credits
CREDITS_ORIGINAL="Chameleon team, crazybirdy, JrCs."
CREDITS_MODIFIED="Chameleon team, crazybirdy, JrCs, Dids."
sed -i '' -e "s/.*${CREDITS_ORIGINAL}.*/${CREDITS_MODIFIED}/" "${CLOVER_PATH}/CloverPackage/CREDITS"

# Switch to the EFI driver folder
cd "${CLOVER_PATH}/CloverPackage/CloverV2/drivers-Off"

# Integrate the ApfsSupportPkg, which replaces the need for a separate apfs.efi file
if [ ! -e "$(pwd)/drivers64UEFI/APFSDriverLoader.efi" ]; then
  timestamp echo "Adding ApfsSupportPkg.."
  APFSSUPPORTPKG_URL=$(curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk https://api.github.com/repos/acidanthera/ApfsSupportPkg/releases/latest | grep "browser_download_url.*zip" | cut -d '"' -f 4)
  curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk $APFSSUPPORTPKG_URL > /tmp/ApfsSupportPkg.zip && \
    unzip /tmp/ApfsSupportPkg.zip -d /tmp/ApfsSupportPkg && \
    cp -f /tmp/ApfsSupportPkg/Drivers/APFSDriverLoader.efi drivers64/APFSDriverLoader-64.efi && \
    cp -f /tmp/ApfsSupportPkg/Drivers/*.efi drivers64UEFI/ && \
    rm -fr /tmp/ApfsSupportPkg
    if [ ! -e "$(pwd)/drivers64UEFI/APFSDriverLoader.efi" ]; then
      timestamp echo "Failed to install ApfsSupportPkg.."
      error
      exit 1
    fi
else
  timestamp echo "Skipping ApfsSupportPkg, already exists!"
fi

# Integrate the AptioFixPkg, which fixes issues with NVRAM
if [ ! -e "$(pwd)/drivers64UEFI/AptioMemoryFix.efi" ]; then
  timestamp echo "Adding AptioFixPkg.."
  APTIOFIXTPKG_URL=$(curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk https://api.github.com/repos/acidanthera/AptioFixPkg/releases/latest | grep "browser_download_url.*zip" | cut -d '"' -f 4)
  curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk $APTIOFIXTPKG_URL > /tmp/AptioFixPkg.zip && \
    unzip /tmp/AptioFixPkg.zip -d /tmp/AptioFixPkg && \
    cp -f /tmp/AptioFixPkg/Drivers/AptioInputFix.efi drivers64/AptioInputFix-64.efi && \
    cp -f /tmp/AptioFixPkg/Drivers/AptioMemoryFix.efi drivers64/AptioMemoryFix-64.efi && \
    cp -f /tmp/AptioFixPkg/Drivers/*.efi drivers64UEFI/ && \
    rm -fr /tmp/AptioFixPkg
    if [ ! -e "$(pwd)/drivers64UEFI/AptioMemoryFix.efi" ]; then
      timestamp echo "Failed to install AptioFixPkg.."
      error
      exit 1
    fi
else
  timestamp echo "Skipping AptioFixPkg, already exists!"
fi

# Download extra EFI drivers (apfs.efi, ntfs.efi, hfsplus.efi)
timestamp echo "Downloading additional EFI drivers.."
curl -sSLk https://github.com/Micky1979/Build_Clover/raw/work/Files/apfs.efi > drivers64UEFI/apfs.efi
curl -sSLk https://github.com/Micky1979/Build_Clover/raw/work/Files/NTFS.efi > drivers64UEFI/NTFS.efi
curl -sSLk https://github.com/Micky1979/Build_Clover/raw/work/Files/HFSPlus_x64.efi > drivers64UEFI/HFSPlus.efi

## TODO: What if we just use symlinks instead, or will Clover even work with those?

## TODO: Refactor this?
cp -f drivers64UEFI/apfs.efi drivers64/apfs-64.efi
cp -f drivers64UEFI/NTFS.efi drivers64/NTFS-64.efi
cp -f drivers64UEFI/HFSPlus.efi drivers64/HFSPlus-64.efi

## TODO: Refactor this?
# Create patched APFS EFI drivers
timestamp echo "Patching apfs.efi driver.."
cp -f drivers64/apfs-64.efi drivers64/apfs_patched-64.efi
cp -f drivers64UEFI/apfs.efi drivers64UEFI/apfs_patched.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64/apfs_patched-64.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64UEFI/apfs_patched.efi

## TODO: Refactor or restructure better, so this is more readable and more easily editable/appendable
## TODO: Add more missing descriptions, which there are still plenty of, unfortunately
# Add missing descriptions
timestamp echo "Adding missing Clover EFI driver descriptions.."
cd "${CLOVER_PATH}/CloverPackage/package/Resources/templates"
echo '"OsxAptioFix2Drv-64_description" = "64bit driver to fix Memory problems on UEFI firmware such as AMI Aptio.";' >> Localizable.strings
echo '"HFSPlus_description" = "Adds support for HFS+ partitions.";' >> Localizable.strings
echo '"Fat-64_description" = "Adds support for exFAT (FAT64) partitions.";' >> Localizable.strings
echo '"NTFS_description" = "Adds support for NTFS partitions.";' >> Localizable.strings
echo '"apfs_description" = "OBSOLETE: Use APFSDriverLoader instead!\n\nAdds support for APFS partitions.";' >> Localizable.strings
echo '"apfs_patched_description" = "OBSOLETE: Use APFSDriverLoader instead!\n\nAdds support for APFS partitions.\nPatched version which removes verbose logging on startup.\n\nWARNING: Do NOT enable multiple apfs.efi drivers!";' >> Localizable.strings
echo '"AptioInputFix_description" = "Reference driver to shim AMI APTIO proprietary mouse & keyboard protocols for File Vault 2 GUI input support.\n\nWARNING: Do NOT use in combination with older AptioFix drivers.\nThis is an experimental driver by vit9696 (https://github.com/vit9696/AptioFixPkg).";' >> Localizable.strings
echo '"OsxAptioFix3Drv-64_description" = "64bit driver to fix Memory problems on UEFI firmware such as AMI Aptio.";' >> Localizable.strings
echo '"OsxFatBinaryDrv-64_description" = "Enables starting of FAT modules like boot.efi.";' >> Localizable.strings

# Build the Clover installer package
timestamp echo "Creating Clover installer.."
cd "${CLOVER_PATH}/CloverPackage"
./makepkg >> ${LOG_PATH} 2>&1

# Calculate and show execution time in minutes
END_TIME=$(date +%s)
EXEC_TIME=$(( $END_TIME - $START_TIME ))
EXEC_RESULT=$(expr ${EXEC_TIME:-0} / 60)
timestamp echo -e "\033[32mFinished in $EXEC_RESULT minute(s)!\033[0m"
