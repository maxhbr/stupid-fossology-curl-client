#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq
# Copyright 2019 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

set -euo pipefail

REST_SERVER_URL=${REST_SERVER_URL:-http://localhost:8081}
REST_SERVER_API="${REST_SERVER_URL}/repo/api/v1"
FOSS_USER=${FOSS_USER:-fossy}
FOSS_PW=${FOSS_PW:-fossy}

log() { >&2 echo "$(tput setaf 3)$@$(tput sgr0)"; }
have() { type "$1" &> /dev/null; }
have jq && prettyfyCmd="jq" || prettyfyCmd="cat"
prettyfyCmd="cat"

curlCmd="curl -k -s -S --write-out HTTP_STATUS=%{http_code} -u $FOSS_USER:$FOSS_PW"
GETCmd="$curlCmd -X GET"
POSTCmd="$curlCmd -X POST"
PATCHCmd="$curlCmd -X PATCH"
DELETECmd="$curlCmd -X DELETE"
PUTCmd="$curlCmd -X PUT"

handleResponse() {
    local response=$(cat)
    local HTTP_STATUS=$(echo "${response}" | sed 's/.*\HTTP_STATUS=//')
    log " --> HTTP_STATUS=$HTTP_STATUS"
    echo ${response%HTTP_STATUS=*} | $prettyfyCmd || \
        echo ${response%HTTP_STATUS=*}

    if [[ $# -eq 1 ]]; then
        local expectedHttpStatus=$1
        if [[ "${HTTP_STATUS}" -ne "$expectedHttpStatus" ]]; then
            log "... fail due to unexpected HTTP_STATUS"
            exit 1
        fi
    elif [[ "${HTTP_STATUS}" -gt 399 ]]; then
        log "... fail due to HTTP_STATUS > 399"
        exit 1
    fi
}

GET() {
    local path=$1; shift
    (set -x;
     $GETCmd "$REST_SERVER_API/$path" \
             $@
    ) | handleResponse
}

POST() {
    local path=$1; shift
    (set -x;
     $POSTCmd "$REST_SERVER_API/$path" \
              $@
    ) | handleResponse
}

PATCH() {
    local path=$1; shift
    (set -x;
     $PATCHCmd "$REST_SERVER_API/$path" \
               $@
    ) | handleResponse
}

DELETE() {
    local path=$1; shift
    (set -x;
     $DELETECmd "$REST_SERVER_API/$path" \
                $@
    ) | handleResponse
}

PUT() {
    local path=$1; shift
    (set -x;
     $PUTCmd "$REST_SERVER_API/$path" \
             $@
    ) | handleResponse
}

################################################################################
################################################################################
################################################################################

auth() {
    GET "auth?username=${FOSS_USER}&password=${FOSS_PW}"
}

uploadFile() {
    local fileToUpload=$(readlink -f $1)
    local folderId=${2:-1}
    local uploadDescription="created by REST"
    local public=public
    (set -x;
     $POSTCmd "$REST_SERVER_API/uploads" \
              -H "folderId: $folderId" \
              -H "uploadDescription: $uploadDescription" \
              -H "public: $public" \
              -H "Content-Type: multipart/form-data" -F "fileInput=@\"${fileToUpload}\";type=application/octet-stream"
    ) | handleResponse
}

deleteUpload() {
    local uploadId=$1
    DELETE "uploads/$uploadId"
}

scheduleJobs() {
    local folderId=$1
    local uploadId=$2

    local data=$(cat <<-EOF
{
  "analysis": {
    "bucket": true,
    "copyright_email_author": true,
    "ecc": true,
    "keyword": true,
    "mime": true,
    "monk": true,
    "nomos": true,
    "package": true
  },
  "decider": {
    "nomos_monk": true,
    "bulk_reused": true,
    "new_scanner": true
  }
}
EOF
           )
    (set -x;
     $POSTCmd "$REST_SERVER_API/jobs" \
              -H "folderId: $folderId" \
              -H "uploadId: $uploadId" \
              -H "Content-Type: application/json" \
              --data "$data"
    ) | handleResponse
}

scheduleReport() {
    local uploadId=$1
    local format=${2:-spdx2}
    (set -x;
     $GETCmd "$REST_SERVER_API/report" \
              -H "uploadId: $uploadId" \
              -H "reportFormat: $format"
    ) | handleResponse
}

downloadReport() {
    local reportId=$1
    (set -x;
     $GETCmd "$REST_SERVER_API/report/$reportId" \
             -H "accept: text/plain"
    ) | handleResponse
}

createFolder() {
    local name=$1
    local parent=${2:-1}
    (set -x;
     $POSTCmd "$REST_SERVER_API/folders" \
              -H "parentFolder: $parent" \
              -H "folderName: $name"
    ) | handleResponse
}

################################################################################
################################################################################
################################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # cli usage
    if [[ ! -n "$(type -t $1)" ]] || [[ "$(type -t $1)" != "function" ]]; then
        log "$1 not found, fall back to generic..."
        GET $1 | jq
    else
        $@ | jq
    fi
fi

