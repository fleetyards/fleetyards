# Phase 3b Research: Erkul/SPViewer/SC-Open Integration

## Date: 2026-04-26

## Summary

No standard loadout interchange format exists in the SC community. Integration with erkul and spviewer is limited to link storage (already implemented). Deep-link generation from our data is not feasible without reverse-engineering proprietary formats.

## Erkul.games

### URL Format
- Loadout URLs use the pattern: `erkul.games/loadout/<code>` (e.g., `3UDSChtK`, `djhXZ5Hc`)
- These are **server-side saved loadout IDs**, not client-side encoded configurations
- When users customize a loadout, erkul saves it server-side and generates a short code
- There is no way to construct an erkul URL from component selections without using their backend

### API / Integration
- **No public API** — erkul.games is closed-source
- **No documented import/export format**
- GitHub (`github.com/DavidErkul`): only a HangarXPLOR fork, no erkul source code
- The Hangar Transfer Format spec lists erkul as **"Reserved for future use"** — meaning even the SC-Open community hasn't established integration yet

### Conclusion
**Cannot generate erkul URLs from our data.** Users must create loadouts on erkul manually and paste the URL into FleetYards (already supported via `erkul_url` field on VehicleLoadout).

## SPViewer.eu

### HangarSync Extension
- Firefox/Chrome extension for saving/restoring SC vehicle loadouts
- **Local-only storage** — all data stays on the user's device, no server connection
- MIT licensed, source on GitHub, but no documented data format
- Only 16.4 KB — very lightweight, likely just localStorage backup/restore

### Integration
- No public API
- No documented data exchange format
- No way to generate spviewer URLs from external data

### Conclusion
**Cannot generate spviewer URLs from our data.** Same as erkul — users paste their URL manually (already supported via `spviewer_url` field).

## SC-Open.dev / Hangar Transfer Format

### What It Is
- OpenAPI 3.0.1 spec at `docs.starcitizen.fans/hangar-transfer-format.yaml`
- Defines a standard for transferring **hangar ownership data** (pledges, ships) between community tools
- Supported tools: StarShip42, HangarXPLOR, starcitizen.fans

### What It Covers
- **Ship ownership**: ship codes, names, manufacturer codes, pledge IDs, dates, costs
- **Pledge data**: LTI status, warbond, package vs standalone
- **NOT loadout/component configurations** — no concept of hardpoint selections, equipped components, or weapon stats

### Schemas Defined
- `core.entity.json` — `{ name, entity_type: "ship"|"component"|"decoration" }`
- `rsi.ship.json` — `{ ship_code, ship_name, manufacturer_code }`
- `hangarxplor.ship.json` — extends with `lti`, `warbond` booleans
- `starship42.ship.json` — minimal, just `name`
- `erkul.ship.json` — extends core entity with `localName` (future use)

### SC-Open GitHub Org
- `github.com/SC-Open` — 22 repos
- Includes `fleetyards.net` (our project!) and `fleetyards-sync`
- `hangarlink-hangarexport` — Chrome extension for RSI pledge/buyback scraping (ownership only)
- No loadout-specific repos or format definitions

### Conclusion
**The Hangar Transfer Format is for ship ownership, not loadouts.** There is no community standard for loadout data interchange. We could propose one, but adoption would require buy-in from erkul, spviewer, and HubCitizen.

## HubCitizen

### What It Offers
- Ship loadout manager at `hubcitizen.com/ships`
- Share codes: generates links/codes that others can use to view builds
- Save slots for storing loadout configurations
- **Most similar to our loadout feature** in terms of UX

### Integration
- No documented API or data format
- Share codes are proprietary
- No import/export in a standard format

## Recommendations

### What We Should Do Now
1. **Keep the current approach** — erkul_url and spviewer_url fields for manual link pasting (already done)
2. **Consider adding HubCitizen URL field** to VehicleLoadout as a third external link option
3. **Display external links prominently** on loadout views to make it easy for users to jump between tools

### What We Could Propose (Future)
1. **Extend the Hangar Transfer Format** to include a loadout section — propose an RFC to the SC-Open community
2. A loadout section could reference ships by `ship_code` and components by their SC game-data `sc_key` (which we already store)
3. Example format:
   ```json
   {
     "ship_code": "AEGS_Gladius",
     "loadout_name": "PvE Setup",
     "hardpoints": [
       { "hardpoint_key": "hardpoint_weapon_gun_left", "component_key": "behr_laser_repeater_s3" },
       { "hardpoint_key": "hardpoint_shield", "component_key": "shield_generator_s1_gurdian" }
     ]
   }
   ```
4. This would require coordination with erkul (DavidErkul), SPViewer maintainer, and HubCitizen — none of whom currently have open interchange formats

### What We Should NOT Do
- **Don't reverse-engineer erkul/spviewer URL formats** — they're proprietary, server-side, and would break on updates
- **Don't build a "generate erkul link" feature** — not possible without their API
- **Don't block on a community standard** — it doesn't exist yet and may not materialize

## Sources
- [Erkul.games](https://www.erkul.games/loadout)
- [DavidErkul GitHub](https://github.com/DavidErkul)
- [SC-Open GitHub](https://github.com/SC-Open)
- [Hangar Transfer Format](https://docs.starcitizen.fans/)
- [SPViewer HangarSync (Firefox)](https://addons.mozilla.org/en-US/firefox/addon/spviewer-hangarsync/)
- [SC-Open hangarlink-hangarexport](https://github.com/SC-Open/hangarlink-hangarexport)
- [HubCitizen Ship Loadout Manager](https://hubcitizen.com/ships)
- [FleetYards Issue #461](https://github.com/fleetyards/app/issues/461)
