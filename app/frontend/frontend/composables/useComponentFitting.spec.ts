import { describe, expect, it, vi } from "vitest";
import {
  type BlueprintCostSlot,
  BlueprintRampEnum,
  type Hardpoint,
  type LoadoutSlot,
  type ModelModule,
  VehicleLoadoutItemTypeEnum,
} from "@/services/fyApi";
import {
  COMPONENT_TABS,
  type CraftedPart,
  loadoutValues,
  lowerIsBetter,
  useComponentFitting,
} from "./useComponentFitting";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

describe("lowerIsBetter", () => {
  it("reads signatures, times, cooldowns, draws and fuel burn as better smaller", () => {
    [
      "signatureEm",
      "signatureIr",
      "powerConsumption",
      "quantumDrives.spoolUpTime",
      "quantumDrives.fuelConsumption",
      "controllers.reconfigurationCooldown",
      "thrusters.fuelBurn",
      "missiles.lockTime",
      "weapons.heatPerShot",
    ].forEach((key) => expect(lowerIsBetter(key), key).toBe(true));
  });

  it("reads output, damage and speed as better larger", () => {
    [
      "shields.hp",
      "powerPlants.output",
      "weapons.burstDps",
      "quantumDrives.speed",
      "missiles.lockRange",
    ].forEach((key) => expect(lowerIsBetter(key), key).toBe(false));
  });
});

describe("graft", () => {
  const port = (
    name: string,
    attributes: Partial<LoadoutSlot> = {},
  ): LoadoutSlot =>
    ({
      name,
      hardpointId: `port-${name}`,
      category: "unknown",
      types: [],
      editable: true,
      slots: [],
      ...attributes,
    }) as LoadoutSlot;

  it("leaves out a part's empty ports nothing is fitted to, as the editor does", () => {
    const fitting = useComponentFitting();
    const hull = port("hardpoint_gun_nose", {
      category: "weapon_mounts",
      types: ["Turret"],
      stock: { id: "gimbal", name: "Gimbal" },
      slots: [
        port("hardpoint_class_2", {
          category: "weapons",
          types: ["WeaponGun"],
          stock: { id: "gun", name: "Gun" },
          slots: [port("bar1", { types: ["WeaponAttachment"] })],
        }),
      ],
    } as Partial<LoadoutSlot>);
    fitting.learn([hull]);

    const [nose] = fitting.graft(
      [{ id: "hp-nose", name: "hardpoint_gun_nose" } as Hardpoint],
      fitting.resolve([hull], {}),
    );

    expect(nose.hardpoints?.map((hp) => hp.name)).toEqual([
      "hardpoint_class_2",
    ]);
    expect(nose.hardpoints?.[0].hardpoints).toEqual([]);
  });

  it("fills a module slot with the module the loadout fits", () => {
    const fitting = useComponentFitting();
    const hull = port("hardpoint_rear_module", { category: "module" });
    fitting.learn([hull]);
    fitting.learnModules([
      {
        id: "cargo-module",
        name: "Cargo Module",
        slot: "hardpoint_rear_module",
      } as ModelModule,
    ]);

    const [slot] = fitting.graft(
      [{ id: "hp-rear", name: "hardpoint_rear_module" } as Hardpoint],
      fitting.resolve([hull], { hardpoint_rear_module: "cargo-module" }),
    );

    expect(slot.component?.name).toBe("Cargo Module");
  });
});

describe("crafting", () => {
  const recipe: BlueprintCostSlot[] = [
    {
      position: 0,
      options: [],
      modifiers: [
        {
          propertyKey: "gpp_shield_maxhealth",
          ramp: BlueprintRampEnum.LINEAR,
          startQuality: 0,
          endQuality: 1000,
          modifierAtStart: 0.8,
          modifierAtEnd: 1.2,
        },
      ],
    },
  ];

  const shieldSlot = (name: string) =>
    ({
      name,
      hardpointId: `port-${name}`,
      category: "shieldgenerator",
      types: ["Shield"],
      editable: true,
      stock: { id: "shield", name: "Shield", typeData: { maxHealth: 1000 } },
      slots: [],
    }) as LoadoutSlot;

  const crafted = (quality: number): CraftedPart => ({
    blueprintId: "bp",
    blueprintSlug: "bp-shield",
    qualities: { 0: quality },
  });

  const shieldsTab = COMPONENT_TABS.find((tab) => tab.id === "shields")!;

  it("reads a crafted part's figures off its recipe once the recipe is in", () => {
    const fitting = useComponentFitting();
    const slots = [shieldSlot("hardpoint_shield")];
    fitting.learn(slots);

    const before = fitting.resolve(slots, {}, { hardpoint_shield: crafted(0) });
    expect(before[0].content?.typeData).toEqual({ maxHealth: 1000 });

    fitting.learnRecipe("bp", recipe);
    const [entry] = fitting.resolve(
      slots,
      {},
      { hardpoint_shield: crafted(0) },
    );

    expect(entry.crafted).toEqual(crafted(0));
    expect(entry.content?.typeData).toEqual({ maxHealth: 800 });
  });

  it("marks a socket crafted, and changed when only its crafting moved", () => {
    const fitting = useComponentFitting();
    const slots = [shieldSlot("hardpoint_shield")];
    fitting.learn(slots);
    fitting.learnRecipe("bp", recipe);

    const saved = fitting.resolve(slots, {}, { hardpoint_shield: crafted(0) });
    const now = fitting.resolve(slots, {}, { hardpoint_shield: crafted(900) });

    const [socket] = fitting.groups(now, shieldsTab, { saved })[0].slots;
    expect(socket.item?.crafted).toBe(true);
    expect(socket.changed).toBe(true);

    const [unchanged] = fitting.groups(saved, shieldsTab, { saved })[0].slots;
    expect(unchanged.changed).toBe(false);
  });

  it("stacks two slots only when they are crafted alike", () => {
    const fitting = useComponentFitting();
    const slots = [shieldSlot("shield_left"), shieldSlot("shield_right")];
    fitting.learn(slots);

    const alike = fitting.resolve(
      slots,
      {},
      { shield_left: crafted(700), shield_right: crafted(700) },
    );
    const apart = fitting.resolve(slots, {}, { shield_left: crafted(700) });

    const count = (tree: ReturnType<typeof fitting.resolve>) =>
      fitting.groups(tree, shieldsTab).flatMap((group) => group.slots).length;

    expect(count(alike)).toBe(1);
    expect(count(apart)).toBe(2);
  });
});

describe("loadoutValues", () => {
  it("reads a crafted item's recipe and qualities by slot path", () => {
    const { crafted } = loadoutValues([
      {
        slotPath: "hardpoint_shield",
        itemType: VehicleLoadoutItemTypeEnum.COMPONENT,
        itemId: "shield",
        crafted: {
          blueprintId: "bp",
          blueprintSlug: "bp-shield",
          qualities: [{ position: 1, quality: 250 }],
        },
      },
      {
        slotPath: "hardpoint_cooler",
        itemType: VehicleLoadoutItemTypeEnum.COMPONENT,
        itemId: "cooler",
      },
    ]);

    expect(crafted).toEqual({
      hardpoint_shield: {
        blueprintId: "bp",
        blueprintSlug: "bp-shield",
        qualities: { 1: 250 },
      },
    });
  });
});
