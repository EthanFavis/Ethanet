# Homepage (CT 110)

A single landing page that links to every service in the lab, with health
checks and live stats pulled from each app's API.

## Container

| | |
|---|---|
| CTID | 110 |
| Hostname | `homepage` |
| OS | Debian 13 |
| Cores | 2 |
| Memory | 4 GB |
| Disk | 6 GB rootfs |
| Tailnet | `homepage` |

## How it's reached

- **Tailnet:** `http://homepage:3000`
- The default browser homepage on every device in the household

## Notes

Homepage's config is YAML — when I move the lab to IaC, this is a high-value
target for version control. The config currently lives inside the container
rootfs and is captured by container-level backups.

## Upstream

- Project: <https://gethomepage.dev/>
- Source: <https://github.com/gethomepage/homepage>
- Install script: <https://community-scripts.org/scripts/homepage>
