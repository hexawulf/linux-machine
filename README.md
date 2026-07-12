# linux-machine.com

A single-page, **neofetch-style live status site** for **piapps3** — a headless DigitalOcean VPS. It renders as a cream-on-dark terminal card showing the host's live uptime and a hardware snapshot, refreshed on-host and ticked client-side. A new-version clone of [`hexawulf/linuxsvr`](https://github.com/hexawulf/linuxsvr), restyled to the Ubuntu terminal look.

**Live:** https://www.linux-machine.com

<!-- Drop a screenshot at docs/preview.png and uncomment: -->
<!-- ![preview](docs/preview.png) -->

---

## Overview

The page mimics a terminal running `neofetch`: an Ubuntu logo beside a key/value system readout, a title bar with traffic-light dots (`zk@piapps3`), and the 16-block ANSI color strip. The **Uptime** line is genuinely live — it counts up in the browser and reflects host reachability with a status dot.

Everything is static (HTML/CSS/vanilla JS). There is no backend and no framework; the only dynamic input is a small JSON file the host regenerates on a timer.

## How it works

Two decoupled parts:

1. **On-host generator** — `bin/gen-status.sh` runs under a systemd timer (every ~5 min and on boot) and writes `status.json` into the site root. It captures OS, kernel, CPU, memory, disk, load, locale, the boot time (as a Unix epoch), and a generation timestamp.
2. **Client page** — `index.html` fetches `status.json` on load and every 60s, populates the live fields, and computes uptime as `now − boot_epoch`, re-rendering every 30s. A freshness check on `generated_epoch` drives the status dot: **green** when data is current, **red** when the fetch fails or the data is stale (host treated as unreachable).

```
systemd timer ──runs──▶ bin/gen-status.sh ──writes──▶ status.json
                                                          │
                                                fetched by │ index.html
                                                          ▼
                                       live uptime + hardware readout
```

`status.json` is **host-generated and gitignored** — it never lives in the repo.

## `status.json` schema (data contract)

`index.html` binds to these exact field names. **Changing the schema in `gen-status.sh` requires updating `index.html` in lockstep.**

| Field | Type | Example |
|---|---|---|
| `hostname` | string | `"piapps3"` |
| `os` | string | `"Ubuntu 24.04.4 LTS"` |
| `kernel` | string | `"6.8.0-134-generic"` |
| `cpu` | string | `"DO-Regular"` |
| `mem` | string | `"739 / 1967 MiB"` |
| `disk_root` | string | `"9.3G / 48G (20%)"` |
| `locale` | string | `"en_US.UTF-8"` |
| `loadavg` | string | `"0.02 0.02 0.00"` |
| `uptime_pretty` | string | `"up 6 days, 17 hours, 14 minutes"` |
| `boot_epoch` | integer (unix seconds) | `1783240918` |
| `generated_epoch` | integer (unix seconds) | `1783821363` |

Uptime is derived from `boot_epoch`; freshness/liveness is derived from `generated_epoch`.

## Repository layout

```
linux-machine/
├── index.html        # the site (neofetch UI + live-status JS)
├── bin/
│   └── gen-status.sh # on-host generator → writes status.json
├── ubuntu-logo.png   # brand mark shown beside the readout
├── .gitignore        # ignores status.json (host-generated)
└── README.md
```

## Stack & infrastructure

- **Frontend:** plain HTML/CSS/JS, Ubuntu Mono (Google Fonts), no build step.
- **Host:** piapps3 — DigitalOcean SGP1, x86_64, Ubuntu 24.04 LTS. Site root is the repo working tree, served by nginx.
- **TLS:** Let's Encrypt via certbot (HTTP-01), auto-renewed by `certbot.timer`; a post-renewal hook fixes key permissions and reloads nginx.
- **Edge:** fronted by Cloudflare (proxied). The origin is nginx on piapps3; the page intentionally exposes **no IP address**.

## Local development

`status.json` isn't in the repo, so create a mock beside `index.html` to preview live behavior (do **not** commit it):

```bash
cat > status.json <<'JSON'
{
  "hostname": "piapps3",
  "os": "Ubuntu 24.04.4 LTS",
  "kernel": "6.8.0-134-generic",
  "cpu": "DO-Regular",
  "mem": "739 / 1967 MiB",
  "disk_root": "9.3G / 48G (20%)",
  "locale": "en_US.UTF-8",
  "loadavg": "0.02 0.02 0.00",
  "uptime_pretty": "up 6 days, 17 hours, 14 minutes",
  "boot_epoch": 1783240918,
  "generated_epoch": 1783821363
}
JSON
python3 -m http.server 8080   # then open http://localhost:8080
```

To exercise the "unreachable" state, delete the mock (or set `generated_epoch` far in the past) and reload — the status dot should turn red and the ticker stop.

## Deployment

The site root on piapps3 is a checkout of this repo. Deploy = pull, then refresh the generated status:

```bash
git -C /home/zk/projects/linux-machine pull --ff-only
/home/zk/projects/linux-machine/bin/gen-status.sh
```

Static files only — **no nginx reload needed**. The systemd timer keeps `status.json` current thereafter.

## Security notes

- **No IP on the page.** Neither the public nor any local IP appears in the rendered site (origin sits behind Cloudflare).
- **`status.json` is gitignored** and generated on-host, so no runtime host data is committed.
- Pushes from piapps3 authenticate over SSH as a repo-scoped identity — no tokens on the VPS.

## Credits

New-version clone of [`hexawulf/linuxsvr`](https://github.com/hexawulf/linuxsvr). Ubuntu terminal makeover implemented via [Jules](https://jules.google.com). Ubuntu logo © Canonical, used descriptively to indicate the OS.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
