#!/bin/bash

# Setup error handling
set -e
set -o pipefail

# Enable debugging
#set -x

# Use our own fork for additional drivers (ours are usually much more up to date)
sed -i '' -e "s/Micky1979\/Build_Clover\/raw\/work\/Files/Dids\/Build_Clover\/raw\/work\/Files/g" "${TRAVIS_BUILD_DIR}/Build_Clover.command"

# Build Clover and create the initial package
"${TRAVIS_BUILD_DIR}/Build_Clover.command"

# Append myself to the credits
CREDITS_ORIGINAL="Chameleon team, crazybirdy, JrCs."
CREDITS_MODIFIED="Chameleon team, crazybirdy, JrCs, Dids."
sed -i '' -e "s/.*${CREDITS_ORIGINAL}.*/${CREDITS_MODIFIED}/" "${HOME}/src/edk2/Clover/CloverPackage/CREDITS"

# Create patched APFS EFI drivers
cd "${HOME}/src/edk2/Clover/CloverPackage/CloverV2/drivers-Off"
cp -f drivers64/apfs-64.efi drivers64/apfs_patched-64.efi
cp -f drivers64UEFI/apfs.efi drivers64UEFI/apfs_patched.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64/apfs_patched-64.efi
perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' drivers64UEFI/apfs_patched.efi

# Add missing descriptions
cd ${HOME}/src/edk2/Clover/CloverPackage/package/Resources/templates
echo '"OsxAptioFix2Drv-64_description" = "64bit driver to fix Memory problems on UEFI firmware such as AMI Aptio.";' >> Localizable.strings
echo '"HFSPlus_description" = "Adds support for HFS+ partitions.";' >> Localizable.strings
echo '"Fat-64_description" = "Adds support for exFAT (FAT64) partitions.";' >> Localizable.strings
echo '"NTFS_description" = "Adds support for NTFS partitions.";' >> Localizable.strings
echo '"apfs_description" = "Adds support for APFS partitions.";' >> Localizable.strings
echo '"apfs_patched_description" = "Adds support for APFS partitions.\nPatched version which removes verbose logging on startup.\n\nWARNING: Do NOT enable multiple apfs.efi drivers!";' >> Localizable.strings
#echo '"AptioMemoryFix_description" = "Fork of the original OsxAptioFix2 driver with a cleaner (yet still terrible) codebase and improved stability and functionality.\n\nWARNING: Do NOT use in combination with older AptioFix drivers.\nThis is an experimental driver by vit9696 (https://github.com/vit9696/AptioFixPkg).";' >> Localizable.strings
echo '"AptioInputFix_description" = "Reference driver to shim AMI APTIO proprietary mouse & keyboard protocols for File Vault 2 GUI input support.\n\nWARNING: Do NOT use in combination with older AptioFix drivers.\nThis is an experimental driver by vit9696 (https://github.com/vit9696/AptioFixPkg).";' >> Localizable.strings
echo '"OsxAptioFix3Drv-64_description" = "64bit driver to fix Memory problems on UEFI firmware such as AMI Aptio.";' >> Localizable.strings
echo '"OsxFatBinaryDrv-64_description" = "Enables starting of FAT modules like boot.efi.";' >> Localizable.strings

# Recreate the package
cd "${HOME}/src/edk2/Clover/CloverPackage"
make pkg
