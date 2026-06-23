#!/usr/bin/env bash
#
# restore-test.sh, automated restore drill. Restores the latest snapshot of a
# given backup into a scratch directory and verifies a known file exists, then
# cleans up. Proves recoverability on a schedule (run weekly from cron).
set -euo pipefail

PBS_REPO="${PBS_REPO:-backup@pbs@pbs.lab.local:homelab}"
NAMESPACE="${NAMESPACE:-pve}"
ARCHIVE="${1:-etc.pxar}"
SENTINEL="${2:-hostname}"   # file expected to exist under the restored tree
SCRATCH="$(mktemp -d /tmp/restore-test.XXXXXX)"

cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

echo "Restoring latest ${ARCHIVE} from ${PBS_REPO} -> ${SCRATCH}"
proxmox-backup-client restore "host/$(hostname)/$(date +%Y)*" "${ARCHIVE}" "${SCRATCH}" \
  --repository "${PBS_REPO}" --ns "${NAMESPACE}" || {
    echo "RESTORE FAILED"; exit 1;
  }

if [[ -e "${SCRATCH}/${SENTINEL}" ]]; then
  echo "PASS: restored data verified (${SENTINEL} present)."
  exit 0
else
  echo "FAIL: sentinel ${SENTINEL} not found in restored data."
  exit 2
fi
