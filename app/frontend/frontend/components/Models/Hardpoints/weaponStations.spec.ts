import { describe, expect, it } from "vitest";
import type { Hardpoint } from "@/services/fyApi";
import { slotPosition, weaponStations } from "./weaponStations";

let nextId = 0;

const hardpoint = (
  category: string,
  name: string,
  typeData: Record<string, unknown> = {},
  hardpoints: Hardpoint[] = [],
  componentId = name,
) =>
  ({
    id: `hp-${(nextId += 1)}`,
    category,
    hardpoints,
    component: { id: componentId, name, size: "3", typeData },
  }) as unknown as Hardpoint;

const GUN = { fireRate: 600, damagePerShot: { physical: 10 } };
const MISSILE = {
  trackingSignal: "Infrared",
  damagePerShot: { physical: 1500 },
};

const gun = (name = "Repeater") => hardpoint("weapons", name, GUN);
const mount = (name = "Gimbal") =>
  hardpoint("weapon_mounts", name, {}, [gun()]);
const turret = (
  control: string,
  guns: Hardpoint[],
  name = `${control} turret`,
) => hardpoint("turret", name, { control }, guns);

describe("weaponStations", () => {
  it("collects the pilot's guns into one station, with their mounts", () => {
    const [pilot] = weaponStations([mount(), mount(), gun("Nose")]);

    expect(pilot.kind).toBe("pilot");
    expect(pilot.dps).toBe(300);
    expect(
      pilot.guns.map((entry) => [entry.name, entry.count, entry.mount]),
    ).toEqual([
      ["Repeater", 2, "Gimbal"],
      ["Nose", 1, undefined],
    ]);
  });

  it("flattens turret, mount and gun into one station per turret", () => {
    const [station] = weaponStations([turret("manned", [mount(), mount()])]);

    expect(station.kind).toBe("manned");
    expect(station.guns).toHaveLength(1);
    expect(station.guns[0].count).toBe(2);
    expect(station.dps).toBe(200);
  });

  it("files a remote turret in a weapon-mount slot as a turret, not the pilot's", () => {
    const remote = hardpoint(
      "weapon_mounts",
      "Remote Turret",
      {
        control: "remote",
      },
      [mount(), mount()],
    );

    const stations = weaponStations([mount(), remote]);

    expect(stations.map((station) => station.kind)).toEqual([
      "pilot",
      "remote",
    ]);
    expect(stations[1].guns[0].count).toBe(2);
  });

  it("collapses identical turrets into one station with a count", () => {
    const stations = weaponStations([
      turret("remote", [mount()]),
      turret("remote", [mount()]),
      turret("manned", [mount()]),
    ]);

    expect(stations.map((station) => [station.kind, station.count])).toEqual([
      ["manned", 1],
      ["remote", 2],
    ]);
  });

  it("reads racks as missiles with their payload", () => {
    const rack = hardpoint("missile_racks", "Rack", {}, [
      hardpoint("weapons", "Arrester", MISSILE),
      hardpoint("weapons", "Arrester", MISSILE),
    ]);
    const [station] = weaponStations([rack]);

    expect(station.kind).toBe("missiles");
    expect(station.missileDamage).toBe(3000);
    expect(station.dps).toBe(0);
  });

  it("files a turret without damage as a tool", () => {
    const tractor = turret("remote", [
      hardpoint("weapons", "Tractor Beam", {}),
    ]);

    expect(weaponStations([tractor])[0].kind).toBe("utility");
  });

  it("leaves a mining laser out", () => {
    const laser = hardpoint("weapons", "Laser", { ...GUN, mining: {} });

    expect(weaponStations([laser])).toEqual([]);
  });

  it("keeps a gun turret a weapon station with the weapons switched off", () => {
    const [station] = weaponStations([turret("manned", [mount()])], 0);

    expect(station.kind).toBe("manned");
    expect(station.dps).toBe(0);
    expect(station.guns[0].armed).toBe(true);
  });

  it("finds turrets inside other parts", () => {
    const module = hardpoint("module", "Nose Module", {}, [
      turret("remote", [mount()]),
    ]);

    expect(weaponStations([module]).map((station) => station.kind)).toEqual([
      "remote",
    ]);
  });
});

describe("slotPosition", () => {
  it("reads where a slot sits from its name", () => {
    expect(slotPosition("hardpoint_turret_manned_front")).toBe("front");
    expect(slotPosition("hardpoint_remote_turret_left")).toBe("left");
    expect(slotPosition("hardpoint_weapon_gun_nose")).toBe("nose");
  });

  it("finds nothing in a name that does not say", () => {
    expect(slotPosition("hardpoint_turret_01")).toBeUndefined();
    expect(slotPosition(undefined)).toBeUndefined();
  });
});
