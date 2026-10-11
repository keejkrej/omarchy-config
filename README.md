# Omarchy user config

Omarchy user config for this desk. The monitor layout is specific to the
MateView and ASUS XG27UCS. The other notes apply on any Omarchy machine.

Hardware overlays stay in their own repos:

- [omarchy-zenbookduo](https://github.com/keejkrej/omarchy-zenbookduo) — ASUS Zenbook Duo UX8406
- [omarchy-razerblade](https://github.com/keejkrej/omarchy-razerblade) — Razer Blade 14 (2023)

## What it does

- **Monitors** — scale `2`. MateView on the left, ASUS XG27UCS on the right,
  bottoms aligned. If the Duo overlay is installed, the built-in panels are
  centered under that bar.
- **Secure Boot** — Limine + sbctl notes in [secure-boot-setup.md](secure-boot-setup.md).
- **fx skills** — diagnosis and workaround for Omarchy's externally symlinked
  skills in [fx-skill-discovery.md](fx-skill-discovery.md).

## Install

On Omarchy:

```bash
git clone https://github.com/keejkrej/omarchy-config.git ~/workspace/omarchy-config
~/workspace/omarchy-config/install.sh
```

Install hardware overlays after this so they can hook `hypr.duo` (Duo) or add
device services (Blade) without replacing these files.

Remove with `./uninstall.sh`.
