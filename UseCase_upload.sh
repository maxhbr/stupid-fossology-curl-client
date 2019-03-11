#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq
# Copyright 2019 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

set -e

. fossologyRestClient.sh

echo "#########################################################################"
echo "## create a new folder Test"
createFolder rest

echo "#########################################################################"
echo "## list folders"
folders=$(GET folders)
folderId=$(echo $folders | jq -r 'map(select(.name == "rest")) | map(.id)[0]')

echo "#########################################################################"
echo "## upload to the new folder"
mkdir -p "_tmp"
wget -nc -O "_tmp/zlib-1.2.11.tar.gz" https://www.zlib.net/zlib-1.2.11.tar.gz || true
response=$(uploadFile "_tmp/zlib-1.2.11.tar.gz" $folderId)
uploadId=$(echo $response | jq -r '.message')

sleep 10
scheduleJobs $folderId $uploadId

sleep 100
reportId=$(basename $(scheduleReport $uploadId | jq -c '.message'))

sleep 10
downloadReport $reportId > _tmp/report.rdf.xml

