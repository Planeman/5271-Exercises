#!/bin/bash

# Purpose is to package the homework into a tar file for submission/testing

PACKAGE_DIR="hw_package"
TAR_NAME="5271_hw1"
ROOT_TAR_DIR="5271_hw1"  # When the tar file is opened this will be the extracted directory

HOME_DIR=`pwd`

# Create a fresh package directory
rm -rvf "${PACKAGE_DIR}"
mkdir -vp "${PACKAGE_DIR}/${ROOT_TAR_DIR}"
cd "${PACKAGE_DIR}/${ROOT_TAR_DIR}"


echo -e "\nHome Directory for hw1 sploits: $HOME_DIR"

# Gather all sploit scripts
find ../../ -regex ".*/sploit[0-9]/sploit[0-9].sh" -print -exec cp {} `pwd` \;


# Gather all sploit descriptions
find ../../ -regex ".*/sploit[0-9]/readme[0-9].txt" -print -exec cp {} `pwd` \;


# Add the design.txt file
cp ../../design.txt ./
cd ..

echo "Creating tarball: ${TAR_NAME}.tar.gz"
tar -cvzf ${TAR_NAME}.tar.gz ${ROOT_TAR_DIR}
