#!/usr/bin/env bash

# Set a default config file location if not provided
if [ -z ${CONFIG} ]; then
  CONFIG="/config/zrepl.yml"
  echo "* Default Config File Set: ${CONFIG}"
fi

# Confirm config file is present.
if [ -f "${CONFIG}" ]; then
  echo  "* Config location verified."
else
  echo "error: configuration file not found: ${CONFIG}"
  exit 1
fi

# Determine pool/dataset defined by root_fs value in the zrepl.yml config file
ROOT_FS=$(awk -F ":" '/root_fs:/ {gsub (" ", "", $0); gsub ("\"", "", $0); print $2}' "${CONFIG}")

# Test ROOT_FS is a valid ZFS pool/dataset
if [ -n "${ROOT_FS}" ]; then
  echo "* root_fs value for sink pool: ${ROOT_FS}"
  echo
  if ! zfs list "${ROOT_FS}"
  then
    exit 1
  fi
else
  echo "error: unable to determine root_fs value in config file: ${CONFIG}"
  exit 1
fi

echo
echo "Attempting zrepl config check..."

# zrepl daemon seems to ignore the "--config" statement, workaround copy where zrepl expects it
cp "${CONFIG}" /etc/zrepl/zrepl.yml
CONFIG="/etc/zrepl/zrepl.yml"

if /usr/bin/zrepl --config "${CONFIG}" configcheck
then
  echo "Attempting to start zrepl daemon..."
  if ! /usr/bin/zrepl --config "${CONFIG}" daemon
  then
    echo "error: unable to start zrepl daemon"
    exit 1
  fi
else
  echo "error: zrepl configuration file check failed: ${CONFIG}"
  exit 1
fi
