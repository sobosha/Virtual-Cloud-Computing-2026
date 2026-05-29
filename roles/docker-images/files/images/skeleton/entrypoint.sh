#!/bin/sh
set -eu # exit on error and undefined variable

: "${SKELETON_ENV_VAR:='default value'}"

echo "Skeleton environment variable: ${SKELETON_ENV_VAR}"

tail -f /dev/null
