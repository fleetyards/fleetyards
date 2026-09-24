# Loadout Interchange Formats

**Date:** 2026-09-24 (research 2026-04-26)
**Status:** Reference; no community standard exists

Which formats other Star Citizen tools use to share ship loadouts, and why Fleetyards can only store erkul and spviewer links, not build them. Read this before trying to export, import or deep-link vehicle loadouts.

## erkul.games

- Loadout URLs look like `erkul.games/loadout/<code>` (for example `3UDSChtK`). The code is **the ID of a loadout saved on erkul's server**. It does not encode the configuration, so no URL can be built from component choices without erkul's backend.
- There is no public API and no documented import/export format. The source is closed: `github.com/DavidErkul` holds only a HangarXPLOR fork.
- The Hangar Transfer Format lists erkul as "reserved for future use".

## SPViewer

- Its HangarSync browser extension (MIT) saves and restores loadouts **locally only**, with no server. It is about 16 KB and has no documented data format.
- There is no public API and no way to build an spviewer URL from outside data.

## HubCitizen

The closest match to our loadout feature (`hubcitizen.com/ships`): share codes and save slots. The share codes are proprietary, and there is no API or standard export.

## Hangar Transfer Format (SC-Open)

This is an OpenAPI 3.0.1 spec at `docs.starcitizen.fans/hangar-transfer-format.yaml`, used by StarShip42, HangarXPLOR and starcitizen.fans. **It covers ownership only**: ship codes and names, manufacturer codes, pledge IDs, dates, costs, LTI, warbond, and package vs standalone. It has no hardpoints, no equipped components and no weapon data. Its schemas (`core.entity`, `rsi.ship`, `hangarxplor.ship`, `starship42.ship`, `erkul.ship`) are small ship-identity records. The SC-Open GitHub org has 22 repos and none of them are about loadouts.

## Consequences

- Storing erkul and spviewer URLs that users paste in (`VehicleLoadout#erkul_url`, `#spviewer_url`) is as far as integration can go.
- Do not reverse-engineer erkul or spviewer URLs. The codes are proprietary server-side IDs and would break without notice.
- Do not wait for a community standard, because none exists.

## Proposed loadout shape (not adopted)

If someone proposes a loadout section for the Hangar Transfer Format, it could identify ships by `ship_code` and components by their game-data key (`sc_key`), both of which Fleetyards already stores:

```json
{
  "ship_code": "AEGS_Gladius",
  "loadout_name": "PvE Setup",
  "hardpoints": [
    {
      "hardpoint_key": "hardpoint_weapon_gun_left",
      "component_key": "behr_laser_repeater_s3"
    },
    {
      "hardpoint_key": "hardpoint_shield",
      "component_key": "shield_generator_s1_gurdian"
    }
  ]
}
```

It would only be useful if erkul, SPViewer and HubCitizen adopted it too.
