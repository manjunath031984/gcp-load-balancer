#!/usr/bin/env bash
# =============================================================================
# Runs a command inside the pipeline's toolchain image (built from the repo
# Dockerfile) without requiring the Jenkins "Docker Pipeline" plugin.
# Requires only the `docker` CLI + socket access on the Jenkins agent.
#
# Usage: docker-run.sh <image> <command-to-run-inside-container>
# =============================================================================
set -euo pipefail

IMAGE="$1"
shift
COMMAND="$*"
CURRENT_DIR="$(pwd)"

ARGS=(--rm -v "${WORKSPACE}:${WORKSPACE}" -w "${CURRENT_DIR}" -e GOOGLE_CLOUD_PROJECT)

if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    ARGS+=(-e GOOGLE_APPLICATION_CREDENTIALS
           -v "${GOOGLE_APPLICATION_CREDENTIALS}:${GOOGLE_APPLICATION_CREDENTIALS}:ro")
fi

exec docker run "${ARGS[@]}" "${IMAGE}" bash -c "${COMMAND}"
