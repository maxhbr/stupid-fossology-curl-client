#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq
# Copyright 2019 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

set -e

. fossologyRestClient.sh

echo "#########################################################################"
echo "## upload to the new folder"
wget -nc https://www.zlib.net/zlib-1.2.11.tar.gz
uploadFile zlib-1.2.11.tar.gz

