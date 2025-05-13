#!/bin/bash

# Make sure only root can run our script
if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Remove the existing xdma kernel module if it's loaded
lsmod | grep xdma
if [ $? -eq 0 ]; then
   rmmod xdma
fi

echo -n "Loading xdma driver..."

# Load the driver in default (interrupt-driven) mode
insmod ../xdma/xdma.ko

# Check if the driver loaded successfully
if [ $? -ne 0 ]; then
  echo "Error: Kernel module did not load properly."
  echo " FAILED"
  exit 1
fi

# Check to see if the xdma devices were recognized
echo ""
cat /proc/devices | grep xdma > /dev/null
returnVal=$?
if [ $returnVal -eq 0 ]; then
  # Installed devices were recognized.
  echo "The Kernel module installed correctly and the xdma devices were recognized."
else
  # No devices were installed.
  echo "Error: The Kernel module installed correctly, but no devices were recognized."
  echo " FAILED"
  exit 1
fi

echo " DONE"
