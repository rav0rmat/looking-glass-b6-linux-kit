# IVSHMEM and KVMFR

## Host: IVSHMEM

The libvirt element must be inside `<devices>`:

```xml
<shmem name='looking-glass'>
  <model type='ivshmem-plain'/>
  <size unit='M'>128</size>
</shmem>
```

After the VM starts, the host must have `/dev/shm/looking-glass`. The client needs access to this file. Do not manually replace a file managed by libvirt, and use `0666` permissions only temporarily for diagnosis.

If permissions do not allow access, correct the local libvirt/QEMU policy or configure a tmpfiles rule with your user and group. Do not publish the generated rule because it contains the account name.

## Guest: build KVMFR

Build KVMFR in the guest for its running kernel:

```bash
sudo apt install -y build-essential linux-headers-$(uname -r)
bash scripts/build-kvmfr.sh
bash scripts/build-kvmfr.sh --install
sudo modprobe kvmfr
sudo usermod -aG kvm "$USER"
```

Log out and back in after changing the group. Verify:

```bash
ls -l /dev/kvmfr0
stat -c '%s bytes' /dev/shm/looking-glass  # host only
```

In the guest, the KVMFR device corresponds to the PCI IVSHMEM device. The mapped size may be reported differently from the total host file size; do not change the XML based only on this difference.

## Patch for recent kernels

`03-kvmfr-modern-kernels.patch`:

- includes `linux/vmalloc.h` explicitly;
- uses the `class_create()` signature for kernel 6.4+;
- uses the `DMA_BUF` namespace as a string on kernel 6.13+;
- retains compatibility branches for older kernels.

After a kernel update, rebuild the module for the new `uname -r`. The kit does not use DKMS and does not rebuild the module automatically during boot.

## Secure Boot

An unsigned module may be rejected when Secure Boot is enabled. Sign the module using the system's MOK infrastructure or follow the documented local policy. Disabling Secure Boot is not the kit's default solution.
