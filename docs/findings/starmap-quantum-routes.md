# Starmap Quantum Routes

**Date:** 2026-11-19
**Status:** Reference; the starmap route planner (`frontend/utils/quantumRoute.ts`) is built on it

What the game files say about quantum travel, measured against the 4.10.3 live and 5.0 PTU exports and the live API. Read this before changing how the planner weighs a jump, decides what blocks one, or where a ship can refuel.

## Drives

| Stat | What the export holds | How the planner uses it |
|---|---|---|
| `jumpRange` | 3.4e38, the float maximum, on every drive | Not a limit |
| `driveSpeed`, `stageOneAccelRate`, `stageTwoAccelRate` | m/s and m/s² | `calculateTravelTime` in `travelTimes.ts`, in km |
| `spoolUpTime`, `cooldownTime` | seconds | Every jump pays the spool; the cooldown is paid between jumps |
| `calibrationRate`, `min/maxCalibrationRequirement`, `calibrationDelayInSeconds` | 1000/s against 5000–10000, 1.5 s delay, on every drive | Left out: a few seconds, the same for every drive |
| `quantumFuelConsumption` | mSCU per Gm | Fuel per jump, as `/tools/travel-times` reads it |
| `quantumFuelRequirement` | No declared unit | Not used |

## Positions and obstruction

Starmap positions are metres in system space with the star at the origin; each system has its own origin, so places in different systems only connect through jump tunnels.

Measured against each body's `radius` in Stanton:

- Outposts and cities stand at 0.99–1.05 radii (terrain included). The planner treats anything within 1.08 radii as standing on the body.
- The closest orbital stations are at 1.1 radii (Seraphim), the rest up to 2.4. A jump is refused when its line passes within 1.05 radii of a star, planet or moon.
- A body as an endpoint stands for its orbital markers and is reached and left from any side. A surface place only jumps to what is above its horizon and otherwise goes through its body first, as a pilot climbs to orbit.
- In Stanton every outpost, station and body is flagged `quantumTravelDestination`; jump points are not, and the planner adds them as tunnel ends.

## Refuelling

Each `StarMapObject` record lists its amenities as references into `starmapamenitytypes/starmapamenitytypes.records.xml`; the plain `name` attribute ("Vehicle Services") is the key, `displayName` the loc key. 4.10.3 has 25 types, 5.0 PTU 31. "Vehicle Services" (refuel, repair, restock) is on every rest stop (`pu/station/reststop/rr_*`), gateway (`rr_jp_*`) and orbital station; in 4.10.3 that is 235 places, 49 of them stations. `derived/landingzones.json` holds hangars, pads and docking tubes only, no services.

The parser imports the list as `locations.amenities`; the planner refills the tank at places with vehicle services.

## Search cost

A* with the straight-line jump time as the estimate plans a Stanton trip in about 10 ms, against about 300 ms for plain Dijkstra over the same ~500 places. With a tank too small for the trip, the refuel search keeps fuel burnt since the last refill per label and takes 100–250 ms in Stanton; a check of whether the destination is reachable at all, refuelling, runs first so an impossible trip does not search every way through the refuels.
