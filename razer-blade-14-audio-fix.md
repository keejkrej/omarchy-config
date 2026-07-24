# Razer Blade 14 (2023) Built-in Speaker Fix

## Environment

- **Distro:** Omarchy (Arch Linux + Hyprland)
- **Hardware:** Razer Blade 14 - RZ09-0482 / 9.04
- **Audio codec:** Realtek ALC298 (`HDA:10ec0298,1a582020,00100103`)
- **Audio controllers:**
  - NVIDIA AD107 HDMI audio
  - AMD Radeon HDMI audio
  - AMD Ryzen HD Audio Controller (`snd_hda_intel`) — analog speakers/headphones
  - AMD Audio Coprocessor (`acp63`) — digital microphones
- **Initial PipeWire version:** 1.6.8, WirePlumber 0.5.15

## Findings

1. **`pipewire-audio` was not installed.** WirePlumber logged:

   ```
   PipeWire's ALSA SPA plugin is missing or broken. Sound cards will not be supported
   ```

   `wpctl status` showed no audio devices and `pactl` could not connect.

2. **`pipewire-pulse` was not running.** After installing the PipeWire packages, PulseAudio-compatible clients (`pamixer`, `pactl`) still failed until the service was started and enabled.

3. **ALC298 analog output was detected but produced no sound.** Kernel autoconfig found the codec:

   ```
   snd_hda_codec_alc269 hdaudioC2D0: autoconfig for ALC298: line_outs=1 (0x17/0x0/0x0/0x0/0x0) type:speaker
   ```

   `wpctl status` showed the speaker sink as active, `pactl list sinks` reported `State: RUNNING`, `Mute: no`, and the mixer was unmuted — but no audible output from the built-in speakers. The ALC298 on this laptop requires a specific `hda-verb` initialization sequence to enable the speaker path.

4. **The `acp_ps_mach` driver reported `ASoC: no DMI vendor name!`** for the AMD ACP platform. This affects the digital microphone path; the analog speaker fix below is separate. A newer kernel may add a DMI quirk for this model.

5. **`linux 7.1.4.arch1-1` is installed but `7.1.3-arch1-2` is currently running.** A reboot is needed to load the newer kernel, which may improve ACP/microphone support.

## Solution

Install the missing PipeWire packages, install `alsa-tools` for `hda-verb`, download the known-good ALC298 init sequence, run it, and install a systemd service to run it on every boot.

### 1. Install PipeWire audio packages

```bash
sudo pacman -S --needed --noconfirm pipewire-audio pipewire-alsa pipewire-pulse
systemctl --user enable --now pipewire-pulse
systemctl --user restart pipewire wireplumber
```

### 2. Set the default sink and a safe volume

```bash
wpctl set-volume @DEFAULT_SINK@ 0.30
```

If the wrong profile is selected (e.g. `Headphones` instead of `Speaker`), switch back:

```bash
pactl set-card-profile alsa_card.pci-0000_65_00.6 'HiFi (Mic1, Mic2, Speaker)'
```

### 3. Apply the Razer Blade 14 2023 speaker init script

The workaround comes from [`yadu-tv/rb14-2023-audio-fix`](https://github.com/yadu-tv/rb14-2023-audio-fix).

```bash
sudo pacman -S --needed --noconfirm alsa-tools

# Download the script
sudo curl -fsSL https://raw.githubusercontent.com/yadu-tv/rb14-2023-audio-fix/main/rb_audio.sh \
  -o /usr/local/bin/rb_audio.sh
sudo chmod 755 /usr/local/bin/rb_audio.sh

# Run it once immediately
sudo /usr/local/bin/rb_audio.sh
```

### 4. Persist the fix across reboots

```bash
sudo tee /etc/systemd/system/rb_audio.service <<'EOF'
[Unit]
Description=Razer Blade 14 audio fix
After=sound.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/rb_audio.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now rb_audio.service
```

### 5. Test and reboot

```bash
speaker-test -D default -c 2 -t sine -f 1000
```

If you hear sound, reboot to load the newer kernel:

```bash
sudo reboot
```

After reboot, verify:

```bash
uname -r
wpctl status
pactl list sinks | grep -E 'Name:|State:|Mute:|Volume:|Active Port'
```

## Verification Commands

Check the active sink:

```bash
wpctl status
pactl list sinks | grep -E 'Name:|Description:|State:|Mute:|Volume:|Active Port'
```

Check ALSA mixer state:

```bash
amixer -c 2 get Master
amixer -c 2 get Speaker
amixer -c 2 get Headphone
```

Check codec autoconfig:

```bash
dmesg | grep -i 'ALC298\|snd_hda_codec_alc269'
```

## References

- [`yadu-tv/rb14-2023-audio-fix`](https://github.com/yadu-tv/rb14-2023-audio-fix)
- [Arch Wiki: PipeWire](https://wiki.archlinux.org/title/PipeWire)
- [Arch Wiki: ALSA](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture)
- [Arch Wiki: HDA verbs](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture/Troubleshooting#HDA_verbs)
