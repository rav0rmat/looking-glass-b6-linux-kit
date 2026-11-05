# Clipboard, input, audio, and bridge networking

## SPICE clipboard

Two components are required in the guest:

- `spice-vdagentd`, the system service;
- `spice-vdagent`, the process in the graphical session.

```bash
sudo systemctl enable --now spice-vdagentd
pgrep -a spice-vdagent
pgrep -a spice-vdagentd
```

For foreground diagnostics, the correct command is:

```bash
spice-vdagent -d -x
```

`-x` keeps the process in the foreground; `-s` configures the serial socket and is not the foreground option.

The PureSpice patches correct the size of messages with a selector, request clipboard data, and accept only `VD_AGENT_CLIPBOARD_SELECTION_CLIPBOARD`. `PRIMARY` events are ignored so they do not clear the opposite clipboard.

Test with plain text and the Looking Glass window focused:

```bash
# On the host or guest, as appropriate
xclip -selection clipboard -o
```

Do not use an `xclip -o | xclip` loop as a permanent mechanism. If `xclip` sees the text but a guest application receives only one character, first verify that the client service removes `WAYLAND_DISPLAY`.

## Input

`client.ini` retains SPICE input, raw mouse, and capture on startup. The release key or shortcut depends on the Looking Glass configuration and host environment. QXL/SPICE remains available for console access and recovery.

## Audio

Both libvirt elements are required:

```xml
<audio id='1' type='spice'/>
<sound model='ich9'/>
```

The `audio` element alone does not create an audio device in the guest. Perform a cold boot after adding ICH9. In the guest:

```bash
pactl info
pactl list short sinks
aplay -l
```

The expected sink is the Intel HDA/ICH9 device, not only the AMD HDMI outputs. The host client plays audio through PipeWire or PulseAudio compatibility.

## LAN bridge

With `br0` already working on the host:

```bash
sudo virt-xml VM_NAME --edit --network bridge=br0,model=virtio
```

In the guest, check the global address and default route:

```bash
ip -brief address
ip route
```

A new MAC address may receive a different DHCP address. Update the router reservation if needed. The kit does not automatically change the MAC address or router configuration.
