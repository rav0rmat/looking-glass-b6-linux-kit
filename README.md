# Looking Glass B6 Linux Kit

A reproducible kit for an Ubuntu 26.04 virtual machine with an XFCE/Xorg desktop, an AMD GPU in VFIO PCI passthrough, and a Looking Glass client on a host using a second GPU. It includes bidirectional SPICE clipboard, ICH9 audio, LAN bridging, IVSHMEM/KVMFR, autostart, and a 4K SDR configuration.

The reference VM is running **Ubuntu 26.04**, while its existing libvirt name remains **`ubuntu-24-04-client`**. The name is intentionally unchanged.

This repository contains no usernames, hostnames, IP/MAC addresses, tokens, or personal paths. PCI values and interface names are examples and must be adapted to your system.

## Pinned and validated components

- Looking Glass `B6`, commit `188f25c6bf6e4525652222be7408f628d7fec1fc`.
- PureSpice at the commit required by B6, not `master`.
- A PureSpice patch for Linux clipboard with `VD_AGENT_CAP_CLIPBOARD_SELECTION`.
- A patch that ignores the X11 `PRIMARY` selection; only `CLIPBOARD` is synchronized.
- An X11/XWayland client with EGL; `jitRender=no` for the reference configuration.
- XCB capture in the guest, AMD 3840×2160 at approximately 60 Hz, SDR.
- KVMFR adapted to recent kernel APIs, including kernel 7.0.
- SPICE only on `127.0.0.1:5900`; QXL remains available as a fallback console.

Performance depends on hardware and workload. This kit does not enable HDR or 120 Hz and does not promise the same frame rate on another system.

## Warnings

- Passing through the GPU used by the host console can leave the host without a display. The reference configuration uses NVIDIA for the host and AMD only in the guest.
- The XML snippets are not a complete domain file. Do not create duplicate `graphics`, `sound`, `hostdev`, or `shmem` elements.
- B6 is a historical release pinned for compatibility. Upstream checks do not install updates or modify the VM.
- Do not automate clipboard republishing with `xclip`; it can create an ownership loop. Use the patched X11 client.

## Quick start

Read the [prerequisites](docs/01-prerequisites.md) first. The usual host build dependencies for Ubuntu are:

```bash
sudo apt update
sudo apt install -y build-essential cmake git pkg-config \
  libfontconfig1-dev libegl1-mesa-dev libgl1-mesa-dev \
  libx11-dev libxi-dev libxfixes-dev libxss-dev libxinerama-dev \
  libxcursor-dev libxpresent-dev libxkbcommon-dev libwayland-dev \
  wayland-protocols libpipewire-0.3-dev libpulse-dev \
  libsamplerate0-dev libspice-protocol-dev libgmp-dev nettle-dev \
  binutils-dev libiberty-dev libvirt-clients virt-manager virtinst \
  libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev
```

Build the client without installing it:

```bash
bash scripts/build-client.sh
```

Build and install explicitly, without restarting the client:

```bash
bash scripts/build-client.sh --install
bash scripts/install-host-session.sh --enable
```

In the guest, install the packages and kernel headers:

```bash
sudo apt update
sudo apt install -y build-essential cmake git pkg-config \
  linux-headers-$(uname -r) libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev libpipewire-0.3-dev libglib2.0-dev \
  spice-vdagent pulseaudio-utils xclip
```

Then, only after configuring IVSHMEM and permissions:

```bash
bash scripts/build-kvmfr.sh --install
bash scripts/build-host.sh --install
bash scripts/install-guest-session.sh
```

The complete order and explanations are in the documentation:

1. [Prerequisites and inventory](docs/01-prerequisites.md)
2. [VFIO and libvirt](docs/02-vfio-libvirt.md)
3. [IVSHMEM and KVMFR](docs/03-kvmfr-ivshmem.md)
4. [Build and installation](docs/04-build-install.md)
5. [AMD, Xorg, XFCE, and 4K HiDPI](docs/05-display-amd-xfce.md)
6. [Clipboard, input, audio, and bridge networking](docs/06-clipboard-input-audio-network.md)
7. [Autostart and verification](docs/07-autostart-verification.md)
8. [Maintenance, updates, and rollback](docs/08-maintenance-rollback.md)

## Verification

On the host, adjust the VM name if yours differs and set your PCI addresses:

```bash
VM_NAME=ubuntu-24-04-client \
AMD_VIDEO_PCI=0000:03:00.0 \
AMD_AUDIO_PCI=0000:03:00.1 \
bash scripts/verify-host.sh
```

In the guest graphical session:

```bash
DISPLAY=:0 bash scripts/verify-guest.sh
```

Before publishing:

```bash
bash scripts/check-public.sh
bash scripts/check-upstream.sh
```

The last command compares revisions, but does not pull, apply patches, or restart services.

## GitHub Actions

- `build.yml` validates the scripts, scans the repository, and builds the patched B6 client, Looking Glass Host XCB, and KVMFR against generic kernel headers from a clean checkout.
- `upstream-check.yml`, run manually or weekly, reports upstream differences in the job summary. It does not open pull requests or update an installation automatically.

The CI runner version is independent of the Ubuntu 26.04 guest version.

## Publishing

After verification, initialize Git and create an empty public repository through the GitHub interface. Then run:

```bash
git init
git add .
git commit -m "Initial Looking Glass B6 Linux kit"
git branch -M main
git remote add origin YOUR_REPOSITORY_URL.git
git push -u origin main
```

Do not publish files from `.upstream/`, backups, the real VM XML, logs, or generated configurations containing local data.

## Licenses

The kit's original scripts, configurations, and documentation are under MIT. Patches and upstream sources remain under their respective project licenses. See `LICENSE`, `NOTICE.md`, and `patches/README.md`.
