# Dressing Room: the Rig, Mounts and Fit Rules

**Date:** 2026-11-02 (measured against the `characters/` and `item-views/` exports and the 4.10.2-live Foundry records; tracked in #6106, export asks in sc-tools#14)

How worn equipment is put together on a body, which parts of it the exports carry, and where the game's rules for what fits on what live. Read it before changing the rig mode of the holo viewer, the dressing room's mounts, or the parser's reading of worn items.

## The rig

- `characters/index.json` lists each body (`bodies.<key>`) with its `body.glb`, `animations.glb`, file md5s and clip list. There is no per-folder `files.json`, so the import digests the inline file list.
- Every worn item's `item-views/<sc_key>/rigged_<body>.glb` is skinned to the same skeleton in the same bind pose as the body, with the same bone names. Each piece carries **its own partial copy** of the bones it uses, plus helper bones the body does not have (`magazine_attach_*_override`, `wep_stocked_attach_*_override`, `wep_sidearm_attach_override`, `backpack_attach_1_override`, `helm_flashlight_*_override`, …). Pieces are rebound to the body's bones by name, and the helper bones are grafted onto the body under their parent.
- `Object3D.clone()` keeps a cloned skinned mesh pointing at the source's bones. Grafting those moves the cached bones for good, so rig pieces are cloned with `SkeletonUtils.clone`.
- Geometry is stored Z up under a `CryEngine_Z_up` root with no rotation, yet it renders upright: the bone matrices carry the conversion. Static holos (`holo.glb`, `holo_textured.glb`) and the rig share the export's frame, so a rigid item pinned to a bone needs **no axis correction**.
- Bounds of a skinned figure have to be measured after `skeleton.update()`. The renderer only refreshes it when it draws, so a figure measured before the first frame reads as its bind pose.
- The bind pose spreads the arms (body x ±0.72 m), while static armour holos hang them down (±0.39 m). Static holos cannot be put on the body.
- The rigged files are untextured, so pieces on the body are drawn in clay.

## The body's regions

`m_body` is 30 submeshes sharing one vertex buffer, cut by region: neck and chest bands, each arm from the upper arm down to the hand, each leg from the thigh down to the foot, and the pelvis. The head, eyes and teeth are separate meshes. The viewer classifies them by their position against the body's height, which lets the regions under armour be drawn as a dark undersuit stand-in and hidden under a rigged undersuit. Armour shells have openings (at the toes, the joints, the waist) where the game shows the undersuit underneath. A bare body there reads as a missing sole.

## Mounts

The port on the worn piece picks the bone, and a helper **in the item's own model** (`ItemOffsetHelperName`) is the point that meets it. Every port's own `Offset` is zero.

| Port | Bone | Item helper |
| --- | --- | --- |
| `wep_stocked_3` (undersuit, every core) — Medium/Large, size 2–5 | `wep_stocked_attach_3_override` | `attach_offset_left_01` |
| `wep_stocked_2` (medium/heavy cores, backpacks) — Medium, size 2–4 | `wep_stocked_attach_2_override` | `attach_offset_right_01` |
| `wep_sidearm` (legs, undersuit) — Small | `wep_sidearm_attach_override` | `attach_offset_left_01` |
| `utility_attach_1/2` (legs) | `utility_attach_*_override` | `attach_offset_right_01` / `_left_01` |
| `backpack` (cores) | `backpack_attach_1_override` | `backpack_attach_1_loc` |

The item helpers live in `.cdf`/`.cga` geometry, which is not in the Foundry export. They reach Fleetyards as `item-views/<sc_key>/attach_points.json` (`{"helpers": {"<name>": {"position", "rotation"}}}`, holo frame), imported into `attach_points`. A weapon in hand sits on `RightWeaponBone` by its origin, its grip. None of the 19 clips holds a weapon.

## Fit rules

What fits on what is decided by item ports, sizes and tags in the Foundry records (`Components/SItemPortContainerComponentParams/Ports/SItemPortDef`), not by the description text:

- The chain is body → undersuit → armour → weapons and backpack. The body has only an `Armor_Undersuit` port, so armour needs an undersuit.
- The undersuit holds `Armor_Torso`, `Armor_Arms`, `Armor_Legs` and `Armor_Helmet`. 16 of 186 undersuits (the `vgl_`, `mrai_` and `orig_` flight suits, the prison suit) have no arms or legs ports. Some have a torso port only, and `nvy_flightsuit_01_01_01` locks its torso to a matching core through `RequiredPortTags`.
- A port's `RequiredPortTags` must appear in the item's AttachDef `Tags`, an item's `RequiredTags` must appear in the port's `PortTags`, the type and subtype must match one `SItemPortDefTypes`, and the item `Size` must lie within `MinSize`..`MaxSize`. The `$` prefix on port-side tags is unexplained, since items carry the tag without it.
- Backpack against core is a size check: the core's `backpack` port has `MaxSize` 1 (light), 2 (medium) or 3 (heavy), and backpacks are `Size` 1, 2 or 3. It matches the "Core Compatibility" and "Backpacks" description fields the parser already reads.
- The superheavy set and bespoke suits lock their arms, legs, helmet and backpack together through tags.
- `SM_*` tags (`SM_RestrictedArm`, `SM_RestrictedWep`, `SM_Marine`) only apply in Star Marine's loadout editor. Ignore them for the PU.
