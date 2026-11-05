# Prerequisites and inventory

## Topology

The reference configuration has two GPUs:

- the host GPU renders the desktop and Looking Glass client;
- the AMD GPU and its audio function are passed through entirely to the guest;
- the guest desktop is rendered by AMD and captured through XCB/KVMFR;
- SPICE/QXL provides input, clipboard, audio, and a fallback console.

Do not use this guide to detach the host's only GPU without an alternative console and a recovery plan.

## Host inventory

```bash
lspci -Dnnk
find /sys/kernel/iommu_groups -type l
virsh list --all
ip -brief link
```

Record locally:

- the AMD video and audio PCI addresses, in the form `0000:bb:dd.f`;
- the IOMMU groups and every device in each group;
- the VM name;
- the LAN bridge, if one exists;
- the GPU that remains on the host.

The examples use `0000:03:00.0` and `0000:03:00.1`. Do not copy these values without verifying them.

## Guest

- Ubuntu 26.04, XFCE, and LightDM on Xorg.
- A working `amdgpu` driver.
- A local graphical session on `:0` for the autostart example.
- Headers for the running kernel.

The existing libvirt VM name remains `ubuntu-24-04-client`; this is only a name and does not indicate the installed Ubuntu version.

If the session uses GDM/Wayland or another display manager, the XCB/Xorg example does not apply directly. Do not switch the desktop environment of a production system without a backup.

## Minimum backups

```bash
sudo virsh dumpxml VM_NAME > vm-before-looking-glass.xml
cp -a ~/.config/looking-glass ~/.config/looking-glass.backup 2>/dev/null || true
```

The XML file and backups may contain local data; do not add them to the public repository.
