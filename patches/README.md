# Patches

Patches `01` and `02` apply inside `repos/PureSpice`, in that order. They enable Linux clipboard through SPICE messages with an explicit selection and ignore `PRIMARY`, retaining only `CLIPBOARD`.

Patch `03` applies at the Looking Glass root and adapts the KVMFR module to recent kernel APIs. Conditional code retains compatibility with older kernels supported by the B6 source.

These patches modify upstream code and are provided under the license of the project they modify. The kit's original scripts and documentation are covered by the license in the repository root.
