#!/usr/bin/env bash
#
# backup.sh — push homelab VM/container backups to Proxmox Backup Server (PBS)
# and prune to a tiered retention. Intended to run from cron on the PVE host.
set -euo pipefail

PBS_REPO="${PBS_REPO:-backup@pbs@pbs.lab.local:homelab}"
NAMESPACE="${NAMESPACE:-pve}"
LOG="/var/log/homelab-backup.log"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

# Datastores/paths to protect (proxmox-backup-client backs up a snapshot)
declare -A TARGETS=(
  ["etc"]="/etc"
  ["docker-volumes"]="/var/lib/docker/volumes"
  ["vmstore"]="/mnt/vmstore"
)

log "Starting homelab backup to ${PBS_REPO} (ns=${NAMESPACE})"
for name in "${!TARGETS[@]}"; do
  path="${TARGETS[$name]}"
  log "Backing up ${name} (${path})"
  proxmox-backup-client backup "${name}.pxar:${path}" \
    --repository "${PBS_REPO}" \
    --ns "${NAMESPACE}" \
    --change-detection-mode=metadata
done

# Tiered retention: keep 7 daily, 4 weekly, 6 monthly
log "Pruning old snapshots"
proxmox-backup-client prune \
  --repository "${PBS_REPO}" --ns "${NAMESPACE}" \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 6

log "Backup run complete"
