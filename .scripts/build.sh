#!/usr/bin/env bash

## TODO: Implement a custom exit handler/signal trap with appropriate logic

# Setup error handling
set -o errexit   # Exit when a command fails (set -e)
set -o nounset   # Exit when using undeclared variables (set -u)
set -o pipefail  # Exit when piping fails
set -o xtrace    # Enable debugging (set -x)

## TODO: Create a custom logger (with timestamps and logging everything to a log file + to the screen)


# Make sure the working directory exists and switch to it
mkdir -p ~/src
cd ~/src

# Install or update UDK2018
UDK2018_REPO="https://github.com/tianocore/edk2"
UDK2018_BRANCH="UDK2018"
UDK2018_PATH="~/src/UDK2018"
if [ ! -d "${UDK2018_PATH}/.git" ]; then
  echo "Checking out a fresh copy of UDK2018.."
  git clone "${UDK2018_REPO}" -b "${UDK2018_BRANCH}" --depth 1 "${UDK2018_PATH}"
fi
echo "Checking for updates to UDK2018.."
cd "${UDK2018_PATH}"
git pull

# Install or update Clover
CLOVER_REPO="https://svn.code.sf.net/p/cloverefiboot/code"
CLOVER_PATH="~/src/UDK2018/Clover"
if [ ! -d "${CLOVER_PATH}/.git" ]; then
  echo "Checking out a fresh copy of Clover.."
  svn co "${CLOVER_REPO}" "${CLOVER_PATH}"
fi
echo "Checking for updates to Clover.."
cd "${CLOVER_PATH}"
svn up -r${CLOVER_REVISION:-HEAD}

# Switch back to the UDK root
cd "${UDK2018_PATH}"

# Compile the base tools
make -C BaseTools/Source/C

# Setup UDK
. edksetup.sh

# Switch to the Clover root
cd "${CLOVER_PATH}"

# Build gettext, mtoc and nasm
./buildgettext.sh
./buildmtoc.sh
./buildnasm.sh

# Install UDK patches
cp -R Patches_for_UDK2018/* ../

# Build Clover (clean & build)
./ebuild.sh clean
./ebuild.sh -fr

# Modify the package credits
CREDITS_ORIGINAL="Chameleon team, crazybirdy, JrCs."
CREDITS_MODIFIED="Chameleon team, crazybirdy, JrCs, Dids."
sed -i '' -e "s/.*${CREDITS_ORIGINAL}.*/${CREDITS_MODIFIED}/" "${HOME}/src/edk2/Clover/CloverPackage/CREDITS"

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

## TODO: Download EFI drivers (apfs.efi, ntfs.efi, hfsplus.efi)


# Create patched APFS EFI drivers
ls drivers64/
ls drivers64UEFI/
cp -f drivers64/apfs-64.efi drivers64/apfs_patched-64.efi
cp -f drivers64UEFI/apfs.efi drivers64UEFI/apfs_patched.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64/apfs_patched-64.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64UEFI/apfs_patched.efi

## FIXME: Check which ones are actually missing and add them back one by one
# Add missing descriptions
#cd "${CLOVER_PATH}/CloverPackage/package/Resources/templates"
#echo '"OsxAptioFix2Drv-64_description" = "64bit driver to fix Memory problems on UEFI firmware such as AMI Aptio.";' >> Localizable.strings
#echo '"HFSPlus_description" = "Adds support for HFS+ partitions.";' >> Localizable.strings
#echo '"Fat-64_description" = "Adds support for exFAT (FAT64) partitions.";' >> Localizable.strings
#echo '"NTFS_description" = "Adds support for NTFS partitions.";' >> Localizable.strings
#echo '"apfs_description" = "OBSOLETE: Use APFSDriverLoader instead!\n\nAdds support for APFS partitions.";' >> Localizable.strings
#echo '"apfs_patched_description" = "OBSOLETE: Use APFSDriverLoader instead!\n\nAdds support for APFS partitions.\nPatched version which removes verbose logging on startup.\n\nWARNING: Do NOT enable multiple apfs.efi drivers!";' >> Localizable.strings
#echo '"APFSDriverLoader_description" = "Loads apfs.efi from ApfsContainer located on block device.\n\nWARNING: This replaces the separate apfs.efi driver.";' >> Localizable.strings
#echo '"AptioMemoryFix_description" = "Fork of the original OsxAptioFix2 driver with a cleaner (yet still terrible) codebase and improved stability and functionality.\n\nWARNING: Do NOT use in combination with older AptioFix drivers.\nThis is an experimental driver by vit9696 (https://github.com/vit9696/AptioFixPkg).";' >> Localizable.strings
#echo '"AptioInputFix_description" = "Reference driver to shim AMI APTIO proprietary mouse & keyboard protocols for File Vault 2 GUI input support.\n\nWARNING: Do NOT use in combination with older AptioFix drivers.\nThis is an experimental driver by vit9696 (https://github.com/vit9696/AptioFixPkg).";' >> Localizable.strings
#echo '"OsxAptioFix3Drv-64_description" = "64bit driver to fix Memory problems on UEFI firmware such as AMI Aptio.";' >> Localizable.strings
#echo '"OsxFatBinaryDrv-64_description" = "Enables starting of FAT modules like boot.efi.";' >> Localizable.strings

# Build the Clover installer package
cd "${CLOVER_PATH}/CloverPackage"
./makepkg
