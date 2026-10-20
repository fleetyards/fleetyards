import { describe, expect, it } from "vitest";
import type { Hardpoint } from "@/services/fyApi";
import { poweredGuns } from "./guns";

let nextId = 0;

const slot = (
  category: string,
  name: string,
  typeData: Record<string, unknown> = {},
  hardpoints: Hardpoint[] = [],
) =>
  ({
    id: `hp-${(nextId += 1)}`,
    category,
    hardpoints,
    component: { id: name, name, size: "3", typeData },
  }) as unknown as Hardpoint;

const GUN = { fireRate: 600, damagePerShot: { energy: 10 } };

const gun = (name = "Repeater", typeData: Record<string, unknown> = GUN) =>
  slot("weapons", name, typeData);
const mount = (guns: Hardpoint[]) => slot("weapon_mounts", "Gimbal", {}, guns);
const turret = (guns: Hardpoint[]) =>
  slot("turret", "Turret", { control: "remote" }, guns);

describe("poweredGuns", () => {
  it("stacks every gun of a kind, the turrets' with the pilot's", () => {
    const guns = poweredGuns([
      mount([gun()]),
      mount([gun()]),
      turret([mount([gun()]), mount([gun("Cannon")])]),
    ]);

    expect(guns.map((entry) => [entry.name, entry.count])).toEqual([
      ["Repeater", 3],
      ["Cannon", 1],
    ]);
  });

  it("keeps a stack's part, for its catalogue card", () => {
    const [repeater] = poweredGuns([mount([gun()]), mount([gun()])]);

    expect(repeater.component?.name).toBe("Repeater");
  });

  it("leaves out missiles, mining lasers and parts that do no damage", () => {
    const guns = poweredGuns([
      gun("Missile", {
        trackingSignal: "Infrared",
        damagePerShot: { physical: 1500 },
      }),
      gun("Mining laser", { ...GUN, mining: true }),
      gun("Tractor beam", { fireRate: 0 }),
      gun(),
    ]);

    expect(guns.map((entry) => entry.name)).toEqual(["Repeater"]);
  });

  it("does no sustained damage without weapon power", () => {
    const [repeater] = poweredGuns([gun()], 0);

    expect(repeater.sustainedDps).toBe(0);
  });

  it("sustains its full damage when nothing holds it back", () => {
    const [repeater] = poweredGuns([gun()]);

    expect(repeater.sustainedDps).toBe(100);
  });
});
