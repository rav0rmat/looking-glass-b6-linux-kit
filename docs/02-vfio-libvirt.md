# VFIO and libvirt

## BIOS and kernel

Enable IOMMU in BIOS/UEFI. On AMD systems, the usual kernel parameters are:

```text
amd_iommu=on iommu=pt
```

Add parameters through your bootloader configuration only if they are not already active, then regenerate the configuration and initramfs using your distribution's tools. Verify the IOMMU groups before configuring passthrough.

## Binding the devices

Both video and audio functions must be available to VFIO. If `amdgpu` or `snd_hda_intel` is using either function, do not start the VM until the binding is corrected.

The persistent method depends on the initramfs and host configuration. One option is `driverctl`:

```bash
sudo driverctl set-override 0000:03:00.0 vfio-pci
sudo driverctl set-override 0000:03:00.1 vfio-pci
```

Use your own addresses. Rebinding can immediately disable the console if the GPU is in use by the host. After reboot:

```bash
lspci -Dnnk -s 0000:03:00.0
lspci -Dnnk -s 0000:03:00.1
```

`Kernel driver in use` must be `vfio-pci` for both functions.

## libvirt XML

With the VM stopped, edit the domain:

```bash
sudo virsh edit VM_NAME
```

Adapt `config/host/libvirt/vfio.xml` inside `<devices>`. Do not duplicate devices or copy automatically generated guest PCI addresses. Libvirt assigns the guest address, which may differ from the host address.

Add the required snippets from:

- `spice.xml`: local SPICE, agent channel, SPICE audio, and ICH9;
- `ivshmem.xml`: 128 MiB shared memory;
- `qxl-fallback.xml`: retain the fallback console while validating AMD.

Do not expose SPICE on `0.0.0.0` or a LAN address. The client service also uses fixed port `5900` to wait for the VM.

## Startup and autostart

After saving the XML:

```bash
sudo virsh start VM_NAME
sudo virsh autostart VM_NAME
```

If a VFIO/IOMMU error appears, stop the VM and check the drivers, IOMMU group, and permissions. Do not force startup by disabling security checks.

## Bridge networking

For an existing, working bridge:

```bash
sudo virt-xml VM_NAME --edit --network bridge=br0,model=virtio
```

Perform a cold boot after PCI/audio changes. Preserve the existing interface MAC address if the router has a DHCP reservation; if libvirt generates another MAC address, update the reservation in the router, not in this repository.
