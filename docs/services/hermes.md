# Hermes (CT 112)

The lab's **AI assistant agent** — "Hermes." Runs as its own unprivileged
LXC so the agent and its dependencies stay isolated from the rest of the
stack, reachable over the tailnet like every other service.

## Container

| | |
|---|---|
| CTID | 112 |
| Hostname | `hermes` |
| OS | Ubuntu 24.04 LTS |
| Cores | 2 |
| Memory | 2 GB |
| Disk | 8 GB rootfs |
| Tailnet | `hermes` |

## What it does

- Runs the Hermes AI assistant agent
- Reachable on the tailnet by its MagicDNS name (`hermes`); no public ingress

## Notes

Like the other containers, Hermes runs `tailscaled` and is only reachable
from devices on the tailnet.
