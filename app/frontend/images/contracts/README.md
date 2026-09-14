# Contract Cover Images

Default cover images for fleet contracts, keyed by `FleetContract.kind`.

Drop in WebP files (recommended ~1600×500 for the banner; smaller is fine):

| Kind          | File               |
| ------------- | ------------------ |
| `transport`   | `transport.webp`   |
| `procurement` | `procurement.webp` |
| `crafting`    | `crafting.webp`    |

Alternates are picked up automatically: `transport_alt1.webp`, `transport_alt2.webp`
and so on join the rotation for that kind, the way the mission covers work.

Until a kind has art of its own, `useContractCover` falls back to the mission
cover that comes closest — `cargo_hauling` for a haul, `mining` for crafting —
and then to the generic placeholder. Dropping a file in here takes precedence
over both without a code change.
