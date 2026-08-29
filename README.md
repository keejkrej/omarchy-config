# Omarchy user config

Machine-independent Omarchy customizations: Hyprland user files and notes that
apply on any Omarchy machine.

Hardware overlays stay in their own repos:

- [omarchy-zenbookduo](https://github.com/keejkrej/omarchy-zenbookduo) — ASUS Zenbook Duo UX8406
- [omarchy-razerblade](https://github.com/keejkrej/omarchy-razerblade) — Razer Blade 14 (2023)

## What it does

- **Monitors** — scale `1.6` for internal and hot-plugged displays. If the Duo
  overlay is installed, `hypr.duo.apply_monitors` runs first.
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
