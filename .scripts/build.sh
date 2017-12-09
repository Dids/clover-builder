#!/bin/bash

set -e
set -o pipefail

# Build Clover and create the initial package
"${TRAVIS_BUILD_DIR}/Build_Clover.command"

# Create a patched apfs.efi
cd "${HOME}/src/edk2/Clover/CloverPackage/CloverV2/drivers-Off"
wget "https://github.com/Dids/Build_Clover/raw/work/Files/apfs.efi" -O "apfs_new.efi"
cp -f apfs_new.efi drivers64/apfs-64.efi
cp -f apfs_new.efi drivers64UEFI/apfs.efi
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

# Recreate the package
cd "${HOME}/src/edk2/Clover/CloverPackage"
make pkg
