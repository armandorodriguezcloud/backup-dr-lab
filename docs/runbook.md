# Backup & DR Runbook

## Schedule (cron on the PVE host)
```cron
# nightly backup at 02:00
0 2 * * *   /opt/homelab/scripts/backup.sh
# weekly restore drill, Sundays 04:00
0 4 * * 0   /opt/homelab/scripts/restore-test.sh etc.pxar hostname
```

## Retention policy
| Tier    | Keep | Rationale                         |
|---------|------|-----------------------------------|
| Daily   | 7    | Recent rollback points            |
| Weekly  | 4    | One month of weekly recovery      |
| Monthly | 6    | Longer-term / accidental deletion |

## RPO / RTO targets (lab)
- **RPO:** 24h (nightly backups)
- **RTO:** < 1h for a single VM / dataset restore

## Recovery procedure
1. Identify the snapshot: `proxmox-backup-client snapshot list --repository "$PBS_REPO"`.
2. Restore to scratch and verify (see `scripts/restore-test.sh`).
3. For full VM recovery, restore the `.pxar`/image to the PVE storage and
   re-register the VM, or use **Datacenter → Backup → Restore** in the PVE UI.
4. Validate the service, then document the drill outcome below.

## Drill log
| Date       | Archive   | Result | Notes                  |
|------------|-----------|--------|------------------------|
| 2026-06-21 | etc.pxar  | PASS   | 38s restore, verified  |
| 2026-06-14 | etc.pxar  | PASS   | 41s restore, verified  |
