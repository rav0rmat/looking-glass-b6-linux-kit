# Maintenance, updates, and rollback

## Upstream updates

```bash
bash scripts/check-upstream.sh
```

The command compares the pinned hashes with the B6 branch and PureSpice HEAD. A different PureSpice `master` does not automatically mean B6 must be updated: check the submodule commits in the parent checkout.

The GitHub Actions workflow runs the same check periodically and writes the result to the summary. There is no auto-merge, auto-install, or service restart.

## Guest kernel update

After booting the new kernel:

```bash
bash scripts/build-kvmfr.sh --install
sudo modprobe -r kvmfr  # only if the module is not in use
sudo modprobe kvmfr
```

If KVMFR is being used for capture, stop Looking Glass Host first. Do not unload the module during an active transfer. Repeat the `/dev/kvmfr0` and permission checks.

## Client rebuild

Back up the configuration, then run:

```bash
bash scripts/build-client.sh --install
systemctl --user restart looking-glass-client.service
```

Restarting is separate from building. If the new version fails, restore the saved binary or rebuild the exact commit and patches from the kit.

## Graphical rollback

If Xorg on AMD does not start:

1. open the SPICE/QXL console in virt-manager;
2. move `/etc/X11/xorg.conf.d/10-amd-primary.conf` to a backup outside the directory read by Xorg;
3. restart the display manager or guest;
4. inspect the Xorg logs before trying again.

Do not remove QXL until AMD and autostart have passed several reboot tests.

## Network and audio rollback

To return temporarily to NAT, select the `default` network for the VM interface in virt-manager. For audio, keep ICH9 and SPICE together; removing only the `audio` element or only the sound device creates an incomplete configuration.

## What not to publish

Do not add to Git:

- the real domain XML and system logs;
- IP/MAC addresses, hostnames, and account names;
- `.Xauthority` files, keys, tokens, or router configurations;
- the `.upstream/` and `build/` directories.

Run `bash scripts/check-public.sh` before every push.
