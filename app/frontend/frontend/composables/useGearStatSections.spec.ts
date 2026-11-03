import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import {
  EquipmentConsumableEffectKindEnum,
  EquipmentFireModeKindEnum,
  EquipmentToolActionKindEnum,
  type EquipmentStats,
} from "@/services/fyApi";
import { useGearStatSections } from "./useGearStatSections";

const rowsOf = (stats: EquipmentStats, key: string) =>
  Object.fromEntries(
    (
      useGearStatSections(stats).value.find((section) => section.key === key)
        ?.rows || []
    ).map((row) => [row.label, row.value]),
  );

describe("useGearStatSections", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("gives each fire mode a card, titled by its label or its kind", () => {
    const sections = useGearStatSections({
      fireModes: [
        {
          kind: EquipmentFireModeKindEnum.RAPID,
          label: "Auto",
          fireRate: 810,
          alpha: 12,
          dps: 162,
          spread: { min: 0.18, max: 5 },
        },
        {
          kind: EquipmentFireModeKindEnum.BEAM,
          condition: { heatLevel: 0.4 },
          damagePerSecond: { energy: 210, distortion: 50 },
          dps: 260,
        },
      ],
    });

    expect(sections.value.map((section) => section.title)).toEqual([
      "Auto",
      "Beam from 40% heat",
    ]);
    expect(
      Object.fromEntries(sections.value[0].rows.map((r) => [r.label, r.value])),
    ).toMatchObject({
      "Damage per Shot": "12 DMG",
      "Damage per Second": "162 DPS",
      Spread: "0,18° – 5°",
    });
    expect(sections.value[1].rows).toContainEqual({
      label: "Beam Damage per Second",
      value: "210 Energy · 50 Distortion",
      stack: true,
    });
  });

  it("tells apart modes the game gives the same label", () => {
    const sections = useGearStatSections({
      fireModes: [
        {
          kind: EquipmentFireModeKindEnum.SINGLE,
          name: "Slug",
          label: "Semi",
          alpha: 80,
        },
        {
          kind: EquipmentFireModeKindEnum.SINGLE,
          name: "Single",
          label: "Semi",
          alpha: 100,
        },
      ],
      toolActions: [
        {
          kind: EquipmentToolActionKindEnum.HEAL,
          name: "Heal",
          label: "Healing",
          range: 2,
        },
        {
          kind: EquipmentToolActionKindEnum.TRACTOR,
          name: "Detach",
          label: "Tractor",
          maxDistance: 25,
        },
        {
          kind: EquipmentToolActionKindEnum.TRACTOR,
          name: "TractorBeam",
          label: "Tractor",
          maxDistance: 150,
        },
      ],
    });

    expect(sections.value.map((section) => section.title)).toEqual([
      "Semi · Slug",
      "Semi · Single",
      "Healing",
      "Tractor · Detach",
      "Tractor · Tractor Beam",
    ]);
  });

  it("numbers modes that share both label and name", () => {
    const sections = useGearStatSections({
      fireModes: [
        {
          kind: EquipmentFireModeKindEnum.SINGLE,
          name: "Single",
          label: "Semi",
          alpha: 36,
        },
        {
          kind: EquipmentFireModeKindEnum.SINGLE,
          name: "Single",
          label: "Semi",
          alpha: 36,
          spread: { min: 2.7, max: 6 },
        },
      ],
    });

    expect(sections.value.map((section) => section.title)).toEqual([
      "Semi · 1",
      "Semi · 2",
    ]);
  });

  it("shows what an attachment changes as a percent change", () => {
    expect(
      rowsOf(
        {
          modifier: {
            soundRadius: 1.2,
            recoil: { yaw: 0.8 },
            spread: { firstAttack: 0.65 },
            zoom: 4,
            zoomTime: 1.2,
          },
        },
        "modifier",
      ),
    ).toEqual({
      "Initial Spread": "-35%",
      "Horizontal Recoil": "-20%",
      "Sound Radius": "+20%",
      Zoom: "4×",
      "Time to Aim": "+20%",
    });
  });

  it("reads a tool action's force in kilonewtons", () => {
    const rows = rowsOf(
      {
        toolActions: [
          {
            kind: EquipmentToolActionKindEnum.TRACTOR,
            maxForce: 257500,
            maxDistance: 150,
          },
        ],
      },
      "tool-action-0",
    );

    expect(rows).toEqual({
      "Maximum Force": "258 KN",
      "Maximum Distance": "150 m",
    });
  });

  it("lists a dose's effects, with a buff's duration", () => {
    const rows = rowsOf(
      {
        consumable: {
          volume: 30,
          effects: [
            { kind: EquipmentConsumableEffectKindEnum.HEALTH, amount: 112.5 },
            {
              kind: EquipmentConsumableEffectKindEnum.STATUS,
              stat: "blood_drug_level",
              amount: 30,
            },
            {
              kind: EquipmentConsumableEffectKindEnum.BUFF,
              buff: "radiation_antidote",
              duration: 10,
            },
          ],
        },
      },
      "consumable",
    );

    expect(rows).toEqual({
      "Health Restored": "112,5",
      "Blood Drug Level": "30",
      Effects: "Radiation Treatment (10 s)",
    });
  });

  it("calls a tool's container its capacity, not a magazine", () => {
    const sections = useGearStatSections({
      toolActions: [{ kind: EquipmentToolActionKindEnum.HEAL, range: 2 }],
      magazine: { size: 200, reserve: 3 },
    });

    expect(sections.value[1]).toMatchObject({
      title: "Capacity",
      rows: [{ label: "Capacity", value: "200" }],
    });
  });

  it("stacks damage of several types under its label", () => {
    const rows = useGearStatSections({
      ammo: { damage: { energy: 13, distortion: 5 } },
    }).value[0].rows;

    expect(rows[0]).toMatchObject({ stack: true });
  });

  it("reads a name a new build brings as words until it has a label", () => {
    expect(
      rowsOf(
        {
          melee: {
            attacks: [{ category: "blunt_strike", damage: { physical: 40 } }],
          },
        },
        "melee",
      ),
    ).toEqual({ "Blunt strike": "40 Physical" });
  });

  it("leaves out a card with nothing in it", () => {
    expect(useGearStatSections({ magazine: {} }).value).toEqual([]);
    expect(useGearStatSections(null).value).toEqual([]);
  });
});
