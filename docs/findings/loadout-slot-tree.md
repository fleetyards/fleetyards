# Loadout slot tree

How a fleetyards loadout finds a slot by path, and what the game data does and
does not say about it. `LoadoutSlots` (`app/lib/loadout_slots.rb`) is the code;
this is the data behind it.

## Two trees answer a slot path

A slot path is hardpoint names from the hull down, `/`-joined. Below the hull
level, two hardpoint trees describe the same slot:

- **The part's own ports** (`parent_type: Component`): what fits them -- types,
  size range, flags -- but no stock part.
- **The ship's copy** (`parent_type: Hardpoint`): the parts the ship comes with,
  but no types, and sizes that are the installed part's rather than the port's.
  The Hornet Mk II's nose turret: its gun ports read 3-3 on the ship, 2-3 on the
  turret.

So a slot reads its rules from the part's port and its stock from the ship's
copy, and the ship's copy only applies while the part above it is still the
stock one. A rule that depends on the stock (a mount slot that came with a bare
gun keeps taking guns; a variant's port tags) has to be told the stock: the
port alone never knows it.

## Build rows for component ports

Until the items loader started writing them, a component's ports only had the
build row the 4.10.0 backfill gave them, so `in_build` hid every one on later
builds and a swapped-in mount showed no ports. A build loaded before that fix
needs an items re-load (not a re-parse) to get them.

## What the data does and does not decide

- **Hull port sizes are the installed part's size** (`slot_sizes` in the base
  loader), so a hull slot never takes a part bigger than the one it ships with.
  Conservative; left alone.
- **`uneditable` ports** take only their stock part; what sits inside them stays
  fittable. 238 of 518 hull weapon mounts carry the flag.
- **Port tags** follow the game's two rules: a port's `required_tags` must all
  be on the part, and a part's `required_tags` must all be on the port's
  `port_tags`, a port above it (a Vanguard's nose mount port provides the tag
  its guns demand), or the ship. A variant's hull port carries its base ship's tags
  while its parts carry the variant's, so a plain check refuses stock parts on
  45 hull slots; where the stock part misses the port's tags, its own tags
  (less `flightReady`) stand in. The game files hold no ship tags, so they are
  taken as everything the ship's stock parts require that no port at or above them provides. The stock part always
  fits. Measured on six ships, no stock part is refused, and other ships'
  bespoke guns, turrets, racks and Taurus tractor beams drop out.
- **The game files repeat parts** under one name with identical figures (a
  gas-cloud-resistant AllStop, a gimbal mount per ship that uses it); a picker
  offers each once.
- **The server's hardpoint group key** reads a slot by what sits inside it and
  leaves its own part out wherever it holds anything, so different turrets
  carrying the same tractor beam share a key.
