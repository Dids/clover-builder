#!/usr/bin/env bash

## TODO: Implement a custom exit handler/signal trap with appropriate logic


# Setup error handling
set -o errexit   # Exit when a command fails (set -e)
set -o nounset   # Exit when using undeclared variables (set -u)
set -o pipefail  # Exit when piping fails
set -o xtrace    # Enable debugging (set -x)

## TODO: Create a custom logger (with timestamps and logging everything to a log file + to the screen)

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
  echo "Checking out a fresh copy of UDK2018.."
  git clone "${UDK2018_REPO}" -b "${UDK2018_BRANCH}" --depth 1 "${UDK2018_PATH}"
fi
echo "Checking for updates to UDK2018.."
cd "${UDK2018_PATH}"
git pull
git clean -fdx --exclude="Clover/"

# Install or update Clover
CLOVER_REPO="https://svn.code.sf.net/p/cloverefiboot/code"
CLOVER_PATH="$(echo ${UDK2018_PATH}/Clover)"
if [ ! -d "${CLOVER_PATH}/.git" ]; then
  echo "Checking out a fresh copy of Clover.."
  svn co "${CLOVER_REPO}" "${CLOVER_PATH}"
fi
echo "Checking for updates to Clover.."
cd "${CLOVER_PATH}"
svn up -r${CLOVER_REVISION:-HEAD}
svn revert -R .
svn cleanup --remove-unversioned

# Switch back to the UDK root
cd "${UDK2018_PATH}"

# Export the toolchain directory
export TOOLCHAIN_DIR="$(echo ${SRC}/opt/local)"

# Compile the base tools
echo "Building base tools.."
make -C BaseTools/Source/C

# Setup UDK
echo "Setting up UDK2018.."
set +o nounset
#. edksetup.sh
#${UDK2018_PATH} edksetup.sh
#./edksetup.sh
source edksetup.sh
set -o nounset

# Switch to the Clover root
cd "${CLOVER_PATH}"

# Build gettext, mtoc and nasm (only if necessary)
if [ ! -f "${SRC}/opt/local/bin/gettext" ]; then ./buildgettext.sh; fi
if [ ! -f "${SRC}/opt/local/bin/mtoc.NEW" ]; then ./buildmtoc.sh; fi
if [ ! -f "${SRC}/opt/local/bin/nasm" ]; then ./buildnasm.sh; fi

# Install UDK patches
echo "Installing UDK2018 patches.."
cp -R Patches_for_UDK2018/* ../

# Build Clover (clean & build)
echo "Building Clover.."
./ebuild.sh -cleanall
./ebuild.sh -fr

# Modify the package credits
CREDITS_ORIGINAL="Chameleon team, crazybirdy, JrCs."
CREDITS_MODIFIED="Chameleon team, crazybirdy, JrCs, Dids."
sed -i '' -e "s/.*${CREDITS_ORIGINAL}.*/${CREDITS_MODIFIED}/" "${CLOVER_PATH}/CloverPackage/CREDITS"

# Switch to the EFI driver folder
cd "${CLOVER_PATH}/CloverPackage/CloverV2/drivers-Off"

# Integrate the ApfsSupportPkg, which replaces the need for a separate apfs.efi file
if [ ! -e "$(pwd)/drivers64UEFI/APFSDriverLoader.efi" ]; then
  echo "Adding ApfsSupportPkg.."
  APFSSUPPORTPKG_URL=$(curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk https://api.github.com/repos/acidanthera/ApfsSupportPkg/releases/latest | grep "browser_download_url.*zip" | cut -d '"' -f 4)
  curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk $APFSSUPPORTPKG_URL > /tmp/ApfsSupportPkg.zip && \
    unzip /tmp/ApfsSupportPkg.zip -d /tmp/ApfsSupportPkg && \
    cp -f /tmp/ApfsSupportPkg/RELEASE/APFSDriverLoader.efi drivers64/APFSDriverLoader-64.efi && \
    cp -f /tmp/ApfsSupportPkg/RELEASE/*.efi drivers64UEFI/ && \
    rm -fr /tmp/ApfsSupportPkg
else
  echo "Skipping ApfsSupportPkg, already exists.."
fi

# Integrate the AptioFixPkg, which fixes issues with NVRAM
if [ ! -e "$(pwd)/drivers64UEFI/AptioMemoryFix.efi" ]; then
  echo "Adding AptioFixPkg.."
  APTIOFIXTPKG_URL=$(curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk https://api.github.com/repos/acidanthera/AptioFixPkg/releases/latest | grep "browser_download_url.*zip" | cut -d '"' -f 4)
  curl -u $GITHUB_USERNAME:$GITHUB_TOKEN -sSLk $APTIOFIXTPKG_URL > /tmp/AptioFixPkg.zip && \
    unzip /tmp/AptioFixPkg.zip -d /tmp/AptioFixPkg && \
    cp -f /tmp/AptioFixPkg/Drivers/AptioInputFix.efi drivers64/AptioInputFix-64.efi && \
    cp -f /tmp/AptioFixPkg/Drivers/AptioMemoryFix.efi drivers64/AptioMemoryFix-64.efi && \
    cp -f /tmp/AptioFixPkg/RELEASE/*.efi drivers64UEFI/ && \
    rm -fr /tmp/AptioFixPkg
else
  echo "Skipping AptioFixPkg, already exists.."
fi

# Download extra EFI drivers (apfs.efi, ntfs.efi, hfsplus.efi)
echo "Downloading extra EFI drivers.."
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
echo "Creating patches apfs.efi drivers.."
cp -f drivers64/apfs-64.efi drivers64/apfs_patched-64.efi
cp -f drivers64UEFI/apfs.efi drivers64UEFI/apfs_patched.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64/apfs_patched-64.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64UEFI/apfs_patched.efi

## TODO: Refactor or restructure better, so this is more readable and more easily editable/appendable
## TODO: Add more missing descriptions, which there are still plenty of, unfortunately
# Add missing descriptions
echo "Adding missing Clover EFI driver descriptions.."
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
echo "Creating the Clover installer package.."
cd "${CLOVER_PATH}/CloverPackage"
./makepkg
