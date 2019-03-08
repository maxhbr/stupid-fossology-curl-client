#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq
# Copyright 2019 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

set -e

. fossologyRestClient.sh

echo "#########################################################################"
echo "## create a new folder Test"
createFolder test

echo "#########################################################################"
echo "## list folders"
GET folders

