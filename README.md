# linux-machine.com

One-page status site for **piapps3** (DigitalOcean SGP1). New-version clone of `hexawulf/linuxsvr`.
Shows live host uptime + hardware snapshot. Served by nginx on piapps3 with auto-renewing Let's Encrypt SSL.
`status.json` is generated on-host by a systemd timer and is gitignored.
