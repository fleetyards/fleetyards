# Star Citizen game logs: received blueprints

The game writes a HUD notification to `Game.log` for every blueprint a player
receives. `logbackups/` holds earlier sessions' logs in the same format.

```
<2026-11-02T18:04:11.512Z> [Notice] <SHUDEvent_OnNotification> Added notification "Received Blueprint: <Display Name>: " [12] to queue. ...
```

- The name ends at `: " [n] to queue`; it can contain quotes (`5CA 'Akura'`,
  `Custodian "Desert Shadow" SMG`) and colons.
- The display name is the crafted item's name, which is what `Blueprint#name`
  is copied from. A handful of names are shared by two recipes (armour
  colourways), so a name alone cannot always pick one blueprint.
- The environment is in the header: `Executable: ...\StarCitizen\<LIVE|PTU|EPTU|HOTFIX|4.0_PREVIEW>\Bin64\StarCitizen.exe`.
  Only LIVE and HOTFIX blueprints persist.
- Only receipts in logs the game still keeps can be found; a reinstall or a
  cleared `logbackups/` loses them. Starter blueprints are never "received".
- Other community tools parse the same line client-side, in the browser,
  because the rest of a log carries account ids, other players' handles and
  locations.
- The text is localised: it is `crafting_hud_notification_received_blueprint`
  from the active `global.ini`, so a translated game logs `Plano Recibido: ...`,
  and the item name in that language. Removing a translation does not change
  logs already written. The wording differs per translation, some add
  `<EM4>` markup, and some leave the key out.
- A translated name resolves through the translation's own `global.ini`, from
  name to localisation key to `Blueprint#name_key`. The key cannot be derived
  from the record key: some items borrow another item's entry.
