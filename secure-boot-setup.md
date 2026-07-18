# Omarchy Secure Boot Setup

## Environment

- **Distro:** Omarchy (Arch Linux + Hyprland)
- **Bootloader:** Limine 12.4.2
- **Boot mode:** UEFI
- **Filesystem:** Btrfs with Snapper snapshots
- **UKI path:** `/boot/EFI/Linux/omarchy_linux.efi`
- **Snapshot UKI:** `/boot/<machine-id>/limine_history/omarchy_linux.efi_sha256_<hash>`
- **Firmware:** UEFI with Secure Boot support, currently disabled
- **Dual-boot:** Windows Boot Manager present

Initial state (`sudo sbctl status --json` before setup):

```json
{
  "installed": false,
  "setup_mode": false,
  "secure_boot": false,
  "vendors": ["microsoft", "builtin-db", "builtin-KEK", "builtin-PK"]
}
```

`bootctl` reported `Secure Boot: disabled (unknown)`.

## Findings

1. **No Secure Boot keys existed.** `sbctl` was not installed and no custom signing keys were present.
2. **Limine is the active bootloader.** The firmware booted `\EFI\limine\limine_x64.efi`.
3. **UKIs were used but not signed.** Limine loaded `/boot/EFI/Linux/omarchy_linux.efi` via `protocol: efi`, which means the firmware (when Secure Boot is enabled) verifies the UKI signature. The existing UKIs were unsigned.
4. **Snapper snapshot UKIs also needed signing.** `limine-snapper-sync` generates snapshot UKIs with hash suffixes; these also have to be signed.
5. **Limine config integrity needs enrollment.** Limine supports embedding a BLAKE2B checksum of `limine.conf` into the Limine EFI binary. Without this, Secure Boot only verifies Limine itself, not the config/kernels it loads.
6. **Windows dual-boot needs the `efi_boot_entry` protocol.** Using Limine’s plain `protocol: efi` for Windows makes Limine part of the Windows TPM measurement chain and can cause BitLocker/PCR issues. The `efi_boot_entry` protocol sets firmware `BootNext` and reboots directly into `bootmgfw.efi`.
7. **Generic sbctl tooling does not cover the Omarchy/Limine/Snapper stack.** It does not auto-enroll Limine config, discover snapshot UKIs, or maintain the Windows entry through `limine-update`/`limine-snapper-sync`.

## Solution

Use the purpose-built helper [`omarchy-secureboot`](https://github.com/peregrinus879/omarchy-secureboot), which wraps `sbctl` and integrates with Limine’s hooks and `limine-snapper-sync` to:

- Create and enroll Secure Boot keys.
- Configure Limine for Secure Boot (`ENABLE_ENROLL_LIMINE_CONFIG=yes`, `ENABLE_VERIFICATION=no` for Omarchy’s EFI UKI flow).
- Sign all EFI files under `/boot` (Limine binaries, UKIs, snapshot UKIs, `systemd-bootx64.efi`, fallback `BOOTX64.EFI`).
- Add a persistent Windows entry using `efi_boot_entry`.
- Install pacman/Limine hooks so signatures and the Windows entry stay in sync after future kernel, bootloader, and snapshot updates.

## Commands Executed

A setup script was written to `/tmp/setup-secure-boot.sh` and run with `sudo bash /tmp/setup-secure-boot.sh`.

The script performed:

```bash
# 1. Install sbctl
pacman -S --needed --noconfirm sbctl

# 2. Install the helper
cd /tmp
rm -rf omarchy-secureboot
git clone https://github.com/peregrinus879/omarchy-secureboot.git
cd omarchy-secureboot
make install

# 3. Create signing keys
sbctl create-keys

# 4. Opt in to the persistent Windows Limine entry
mkdir -p /var/lib/omarchy-secureboot
touch /var/lib/omarchy-secureboot/windows-enabled

# 5. Run setup (configures Limine, rebuilds UKI, signs everything, installs hooks)
omarchy-secureboot setup

# 6. Verify
omarchy-secureboot status
```

After the initial run, one extra repair was run because `limine-snapper-sync` left a newly-discovered file outside the sbctl database:

```bash
sudo omarchy-secureboot sign
```

## Final OS-Side State

`sudo sbctl status --json`:

```json
{
  "installed": true,
  "guid": "a65d84c8-41f1-41b0-8e30-a5e561149418",
  "setup_mode": false,
  "secure_boot": false,
  "vendors": ["microsoft", "builtin-db", "builtin-KEK", "builtin-PK"]
}
```

`sudo sbctl verify` (Linux EFI files):

```
✓ /boot/EFI/Linux/omarchy_linux.efi is signed
✓ /boot/EFI/limine/limine_x64.efi is signed
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
✓ /boot/8292a8c8.../limine_history/omarchy_linux.efi_sha256_... is signed
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/Linux/arch-linux.efi is signed
```

`sudo omarchy-secureboot status` shows:

- `sbctl keys installed`
- `Secure Boot disabled` (expected — not enabled in firmware yet)
- `Setup Mode disabled` (expected — not in Setup Mode yet)
- All hooks present (`zz-omarchy-secureboot-cleanup`, `zz-sbctl`, `zzz-omarchy-secureboot`, `zzz-omarchy-secureboot-sign`)
- `ENABLE_VERIFICATION=no` and `ENABLE_ENROLL_LIMINE_CONFIG=yes` in `/etc/default/limine`
- Windows Boot Manager found in firmware and Windows entry in `limine.conf` using `efi_boot_entry`

The `limine.conf` Windows block:

```
# omarchy-secureboot:windows
/Windows
    comment: Windows Boot Manager
    protocol: efi_boot_entry
    entry: Windows Boot Manager
```

## Remaining Manual Steps

You must complete these in UEFI/BIOS; they cannot be done from Linux:

1. Reboot into UEFI/BIOS settings.
2. Clear/reset the Secure Boot keys. This puts the firmware into **Setup Mode**.
3. Save and exit.
4. Back in Linux, enroll the keys:

   ```bash
   sudo omarchy-secureboot enroll
   ```

5. Reboot into UEFI/BIOS again.
6. Enable **Secure Boot**.
7. Save and exit.
8. Boot into Linux and verify:

   ```bash
   sudo omarchy-secureboot status
   ```

## Appendix: Entering Setup Mode when the BIOS hides the option

Some laptops (e.g. Razer Blade) ship with an AMI/Insyde UEFI firmware that hides the Secure Boot key-management menu. The usual **Reset to Setup Mode** or **Delete all Secure Boot variables** options are not exposed in the BIOS UI, and the relevant NVRAM bits are write-protected at runtime. In that case you cannot enter Setup Mode directly from Linux.

The following **efitools + UEFI Shell** route works on firmwares where `CustomMode` can be enabled from a UEFI Shell. It is **not guaranteed** on every locked-down firmware.

### Prerequisites

- `efitools` and `edk2-shell` installed
- `sbctl` keys already created (`omarchy-secureboot setup` does this)
- `KeyTool.efi` and `UpdateVars.efi` from `efitools`

### Step 1: Create a `noPK.auth` delete bundle

Run as root:

```bash
GUID=$(cat /var/lib/sbctl/GUID)
: > /tmp/noPK.esl
sign-efi-sig-list -g "$GUID" \
  -c /var/lib/sbctl/keys/PK/PK.pem \
  -k /var/lib/sbctl/keys/PK/PK.key \
  PK /tmp/noPK.esl /tmp/noPK.auth
```

### Step 2: Copy UEFI Shell and tools to the ESP

Run as root:

```bash
pacman -S --needed edk2-shell
mkdir -p /boot/EFI/tools
cp /usr/share/edk2-shell/x64/Shell.efi /boot/shellx64.efi
cp /tmp/noPK.auth /boot/EFI/tools/
cp /path/to/KeyTool.efi /boot/EFI/tools/
cp /path/to/UpdateVars.efi /boot/EFI/tools/
```

If you use Limine, add a temporary entry to `/boot/limine.conf`:

```text
/UEFI Shell
    comment: UEFI Shell
    protocol: efi
    path: boot():/shellx64.efi
```

### Step 3: Boot into UEFI Shell

Reboot and select the **UEFI Shell** entry.

### Step 4: Enable UEFI Custom Mode

At the UEFI Shell prompt:

```text
Shell> setvar CustomMode -guid c076ec0c-7028-4399-a072-71ee5c448b9f =H01
```

`CustomMode` is a BootService-only variable, so it must be written from a UEFI Shell, not from Linux. If this returns a write-protected/security error, the firmware locks it and this route is blocked.

### Step 5: Delete the Platform Key

```text
Shell> fs0:
FS0:\> cd EFI\tools
FS0:\EFI\tools> UpdateVars PK noPK.auth
```

If `UpdateVars` is unavailable, use `KeyTool.efi` interactively:

```text
FS0:\EFI\tools> KeyTool.efi
Edit Keys → PK → Replace → select noPK.auth → Save to NVRAM
```

Deleting the PK puts the firmware into **Setup Mode**.

### Step 6: Back in Linux, enroll keys

```bash
sudo omarchy-secureboot enroll
```

### Step 7: Enable Secure Boot in BIOS

Reboot, enter the firmware setup, and enable **Secure Boot**. Verify with:

```bash
sudo omarchy-secureboot status
```

### If this route fails

If `setvar CustomMode` is write-protected, the firmware is intentionally blocking programmatic key management. Options then include:

- **Razer `securebootrecovery.efi`**: Razer provides a recovery tool for some models. If you have Windows, copy `C:\Windows\Boot\EFI\securebootrecovery.efi` to a USB as `EFI/BOOT/BOOTX64.EFI`, boot it, and follow the prompts.
- **BIOS mod**: Dump the firmware, use UEFITool and an IFR extractor to find the `RDMODE`/`SuppressIf` guarding the Secure Boot menu, patch it, and flash it back. This is risky and may require a hardware SPI programmer if the flash is locked.

## Windows / BitLocker Warning

If Windows uses **BitLocker**, have the recovery key ready before running `sudo omarchy-secureboot enroll`. Enrolling custom Secure Boot keys usually triggers a one-time BitLocker recovery prompt on the next Windows boot.

The Windows Limine entry uses `efi_boot_entry`, which sets the firmware `BootNext` variable and reboots straight into `bootmgfw.efi`. This keeps Limine out of the Windows TPM measurement chain and reduces BitLocker/PCR drift issues.

## Future Maintenance

Installed hooks will keep things consistent automatically:

- `zz-omarchy-secureboot-cleanup.hook` — removes stale sbctl database entries before re-signing.
- `zz-sbctl.hook` — re-signs tracked EFI files after package updates.
- `zzz-omarchy-secureboot.hook` — repairs Limine config, Windows entry, and snapshot UKIs after relevant transactions.
- `/etc/boot/hooks/post.d/zzz-omarchy-secureboot-sign` — runs after `limine-update` / `limine-snapper-sync`.

If you ever edit `limine.conf` manually, re-enroll the checksum and re-sign:

```bash
sudo omarchy-secureboot sign
```

## Optional: Snapshot Watcher

`limine-snapper-sync.service` is enabled but inactive because `inotify-tools` is not installed. It is not required for Secure Boot — the Limine post-hook handles signature repair after snapshot changes. If you want live snapshot menu updates, install and start it:

```bash
sudo pacman -S inotify-tools
sudo systemctl start limine-snapper-sync.service
```

## Recovery

If a boot fails after enabling Secure Boot, the usual recovery is:

1. Disable Secure Boot in UEFI.
2. Boot from a known-good medium (e.g., Arch live USB) if the Limine binary or config is corrupt.
3. From a chroot, run `sudo omarchy-secureboot sign` to repair signatures and config enrollment.

## References

- [omarchy-secureboot](https://github.com/peregrinus879/omarchy-secureboot)
- [Limine Secure Boot docs](https://github.com/limine-bootloader/limine/blob/master/USAGE.md#secure-boot)
- [Arch Wiki: UEFI/Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)
- [Arch Wiki: sbctl](https://wiki.archlinux.org/title/Sbctl)
