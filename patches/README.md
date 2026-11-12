# Patches

Patches `01` and `02` apply inside `repos/PureSpice`, in that order. They enable Linux clipboard through SPICE messages with an explicit selection and ignore `PRIMARY`, retaining only `CLIPBOARD`.

Patch `03` applies at the Looking Glass root and adapts the KVMFR module to recent kernel APIs. Conditional code retains compatibility with older kernels supported by the B6 source.

These patches modify upstream code and are provided under the license of the project they modify. The kit's original scripts and documentation are covered by the license in the repository root.

Patch `04` applies at the Looking Glass root when building the Linux host. It adds an `XQueryPointer` position fallback for intermittent XFixes cursor-image failures while retaining the last valid cursor shape. It does not fix the underlying Xorg `BadAccess` condition.

Patch `05` applies at the Looking Glass root when building the client. It makes the Wayland clipboard prefer plain-text representations over browser-specific URL representations.

### 06-wayland-shutdown-safety.patch

Prevents late Wayland input events from accessing application state during
client shutdown. It guards the pointer and keyboard leave handlers and avoids
locking the overlay list after that list has been freed.

### 07-xcb-frame-retry.patch

Resets the pending-frame state when XCB fails to return an image reply.
This allows the capture loop to issue a new request instead of waiting
indefinitely after a transient X server error.
