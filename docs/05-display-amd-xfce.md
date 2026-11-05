# AMD, Xorg, XFCE, and 4K HiDPI

## Guest BusID

In the guest:

```bash
lspci -Dnn | grep -Ei 'VGA|Display|3D'
```

The guest PCI address is not necessarily the host address. For `0000:06:00.0`, the Xorg syntax is `PCI:6:0:0`. Verify and adapt `config/guest/10-amd-primary.conf` before copying it:

```bash
sudo install -m 0644 config/guest/10-amd-primary.conf \
  /etc/X11/xorg.conf.d/10-amd-primary.conf
```

The reference configuration:

- forces `amdgpu` and DRI3;
- disables EDID for the headless monitor;
- defines reduced-blanking mode `3840x2160R` at approximately 60 Hz;
- prevents automatic addition of other GPUs to the layout.

Missing or invalid EDID can prevent Xorg from starting. Do not remove QXL until the new layout has started successfully several times.

## XFCE and 2× HiDPI

In the XFCE session:

```bash
xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s 2
xfconf-query -c xsettings -p /Xft/DPI -s 192
```

Some XFWM4 themes retain small title bars. Choose a HiDPI-friendly window theme and reconfigure the panel through XFCE preferences. Do not apply large global scaling variables to every application without testing.

## XCB capture

Looking Glass Host must start in the same Xorg session with access to the Xauthority cookie:

```bash
env DISPLAY=:0 XAUTHORITY="$HOME/.Xauthority" \
  /usr/local/bin/looking-glass-host \
  app:shmFile=/dev/kvmfr0 app:capture=xcb
```

If the log says `Unable to open the X display`, check the display and Xauthority rather than reinstalling PipeWire. A secondary PipeWire crash does not by itself explain missing XCB capture.

## EGL/X11 client

The supplied service removes `WAYLAND_DISPLAY`, so the client uses X11/XWayland. This is part of the solution for direct paste into guest applications and usable window decorations.

`jitRender=no` is intentional. On the reference configuration, JIT calibration could severely reduce the frame rate after a restart. Re-enable JIT only for a separate test with a rollback option.

HDR and 120 Hz are not configured by this kit.
