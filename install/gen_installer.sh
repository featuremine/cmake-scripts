#!/bin/sh

# COPYRIGHT (c) 2019-2023 by Featuremine Corporation.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

set -e

INSTALLER_LINES=$(($(cat "$1" | wc -l)+1))
DIR="$(dirname "$3")"

mkdir -p "$DIR"
(
  cat "$1" | sed \
    -e "s/INSTALLER_LINES=/INSTALLER_LINES=$INSTALLER_LINES/g" \
    -e "s/PROJECT_NAME=/PROJECT_NAME=\"$PROJECT_NAME\"/g" \
    -e "s/PROJECT_VERSION=/PROJECT_VERSION=\"$PROJECT_VERSION\"/g"
  cat "$2"
)>"$3"
chmod +x "$3"
