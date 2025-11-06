#!/usr/bin/env bash
set -ueo pipefail

readonly HASH=$(pwd | sha1sum | cut -d' ' -f1)
readonly STATE_PATH="${HOME}/.crush/projects/${HASH}"

crush -D "${STATE_PATH}" "$@"
