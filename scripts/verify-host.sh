#!/usr/bin/env bash
set -euo pipefail
VM_NAME=${VM_NAME:-ubuntu-24-04-client}
AMD_VIDEO_PCI=${AMD_VIDEO_PCI:-0000:03:00.0}
AMD_AUDIO_PCI=${AMD_AUDIO_PCI:-0000:03:00.1}
FAILED=0

check() {
  if "$@"; then printf 'OK: %s\n' "$*"; else printf 'MISSING/ERROR: %s\n' "$*"; FAILED=1; fi
}

for cmd in virsh python3 ss; do
  command -v "$cmd" >/dev/null 2>&1 || { printf 'Missing: %s\n' "$cmd"; FAILED=1; }
done
((FAILED == 0)) || exit 1

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
virsh dumpxml "$VM_NAME" > "$TMP" || exit 1

python3 - "$TMP" "$AMD_VIDEO_PCI" "$AMD_AUDIO_PCI" <<'PY'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
failed = False

def check(ok, message):
    global failed
    print(("OK: " if ok else "ERROR: ") + message)
    failed = failed or not ok

graphics = root.findall("./devices/graphics[@type='spice']")
check(bool(graphics), "SPICE graphics present")
if graphics:
    g = graphics[0]
    check(g.get("listen") == "127.0.0.1", "SPICE listens only on 127.0.0.1")
    check(g.get("port") == "5900", "fixed SPICE port 5900")

channels = root.findall("./devices/channel[@type='spicevmc']")
check(any(c.find("target") is not None and c.find("target").get("name") == "com.redhat.spice.0" for c in channels), "virtio channel com.redhat.spice.0")
shmem = root.findall("./devices/shmem")
check(any(s.get("name") == "looking-glass" and s.find("model") is not None and s.find("model").get("type") == "ivshmem-plain" for s in shmem), "IVSHMEM ivshmem-plain looking-glass")
check(any(s.get("name") == "looking-glass" and s.find("size") is not None and s.find("size").text == "128" for s in shmem), "IVSHMEM 128 MiB")
check(any(a.get("type") == "spice" for a in root.findall("./devices/audio")), "SPICE audio")
check(any(s.get("model") == "ich9" for s in root.findall("./devices/sound")), "ICH9 sound device")

def pci_text(domain, bus, slot, function):
    return "%04x:%02x:%02x.%x" % tuple(
        int(value, 16) for value in (domain, bus, slot, function))

def pci_arg(value):
    match = __import__("re").fullmatch(
        r"(?:0x)?([0-9a-fA-F]+):(?:0x)?([0-9a-fA-F]+):(?:0x)?([0-9a-fA-F]+)\.(?:0x)?([0-9a-fA-F]+)", value)
    if not match:
        raise ValueError("Invalid PCI address: " + value)
    return pci_text(*match.groups())

wanted = {pci_arg(value) for value in sys.argv[2:]}
found = set()
for hostdev in root.findall("./devices/hostdev[@type='pci']"):
    address = hostdev.find("./source/address")
    if address is None:
        continue
    found.add(pci_text(
        address.get("domain"), address.get("bus"),
        address.get("slot"), address.get("function")))
for pci in sorted(wanted):
    check(pci in found, "VFIO hostdev " + pci)

sys.exit(1 if failed else 0)
PY

if ss -ltn | awk '$4 == "127.0.0.1:5900" {found=1} END {exit !found}'; then
  echo "OK: port 5900 is local"
else
  echo "Note: port 5900 is not currently listening; the VM may be stopped"
fi
printf 'Read-only verification; no configuration was modified.\n'
