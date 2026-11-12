# Autostart and verification

## Boot order

1. Libvirt starts the VM if autostart is enabled.
2. In the guest, `kvmfr` loads through `modules-load`.
3. LightDM starts Xorg on AMD.
4. At XFCE login, `spice-vdagent` and Looking Glass Host with XCB start.
5. On the host, the systemd user unit waits for the local SPICE port and starts the X11 client.

The client service waits approximately three minutes for `127.0.0.1:5900`. Do not expose the port to work around a connection error.

## Useful host commands

```bash
virsh domstate VM_NAME
systemctl --user status looking-glass-client.service
journalctl --user -u looking-glass-client.service -b
ss -ltn | grep 5900
```

Manual start or restart, only when desired:

```bash
systemctl --user start looking-glass-client.service
systemctl --user restart looking-glass-client.service
```

## Guest

```bash
DISPLAY=:0 xrandr --current
pgrep -a looking-glass-host
pgrep -a spice-vdagent
systemctl status spice-vdagentd
```

If Looking Glass Host does not start at login, run the command from the XCB documentation manually and inspect the error. Two capture instances on the same KVMFR device are not a valid configuration; stop the old instance before testing.

## Reboot test

After every reboot, verify in order:

- VFIO binding on the host;
- VM state and IVSHMEM;
- `/dev/kvmfr0` and guest permissions;
- active 3840×2160 mode;
- both SPICE processes;
- bidirectional clipboard with new text;
- audio through the ICH9 sink;
- frame rate and absence of JIT calibration.

The `verify-host.sh` and `verify-guest.sh` scripts read state and do not modify the configuration.

## Host relogin test

After logout and login, verify that IVSHMEM still exists and is accessible:

    stat -c '%U:%G %a %s %n' /dev/shm/looking-glass
    systemctl --user status looking-glass-client.service --no-pager

The owner should remain the QEMU system user, not the desktop login user. The
client unit is limited to three starts per minute and waits 15 seconds between
restarts, preventing a persistent failure from becoming a restart loop.
