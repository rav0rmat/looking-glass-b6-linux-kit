# Build and installation

## Pinned source

`scripts/fetch-source.sh` clones the B6 branch and verifies the hash in `versions.env`. Submodules are initialized recursively at the commits required by the checkout. The script retries Git connections and tries HTTP/1.1 after a transport error.

Do not switch PureSpice to `master`: B6 requires the exact revision in `versions.env`.

## Client on the host

```bash
bash scripts/build-client.sh
bash scripts/build-client.sh --install
```

The first command produces the binary in `build/client/`. The second installs it as `/usr/local/bin/looking-glass-client`. Neither command restarts the active client.

Patch application is idempotent: the script skips an already applied patch but rejects an incompatible source or other modifications in the patched area.

## Looking Glass Host in the guest

```bash
bash scripts/build-host.sh
bash scripts/build-host.sh --install
```

The binary is installed as `/usr/local/bin/looking-glass-host`. The script does not start XCB capture.

## Configuration and autostart

On the host:

```bash
bash scripts/install-host-session.sh --enable
```

Existing files are preserved. To replace them deliberately, use `--force` after making a backup. `--enable` enables the systemd user unit but does not start or restart the client.

In the guest:

```bash
bash scripts/install-guest-session.sh
```

The script generates the desktop file with the current account's home path. The generated file remains local and must not be published.

## Clean build

Use new directories to validate a change:

```bash
bash scripts/build-client.sh \
  --source-dir /tmp/looking-glass-b6-clean \
  --build-dir /tmp/looking-glass-b6-build
```

Do not copy a local binary hash into the documentation: the hash changes with the compiler, dependencies, and build options.
