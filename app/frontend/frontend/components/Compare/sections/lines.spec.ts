import { describe, expect, it, vi } from "vitest";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import type { CompareTableRow } from "@/frontend/components/Compare/types";
import { useLoadoutLines } from "./lines";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

const part = (
  name: string,
  category: HardpointCategoryEnum,
  component: Record<string, unknown>,
  hardpoints: Hardpoint[] = [],
) =>
  ({
    id: Math.random().toString(),
    name,
    category,
    component: { id: String(component.name), typeData: {}, ...component },
    hardpoints,
  }) as unknown as Hardpoint;

const scraper = (name: string) =>
  part("hardpoint_salvage_subitem", HardpointCategoryEnum.SALVAGE_MODULES, {
    name,
    size: "1",
  });

const turret = () =>
  part(
    "hardpoint_mining_cab",
    HardpointCategoryEnum.TURRET,
    { name: "Manned Turret", size: "4" },
    [
      part(
        "hardpoint_weapon_salvage",
        HardpointCategoryEnum.SALVAGE_HEADS,
        { name: "Baler Salvage Head", size: "2" },
        [scraper("Cinch Scraper Module"), scraper("Abrade Scraper Module")],
      ),
    ],
  );

const linesOf = (rows: CompareTableRow[]) => {
  const row = rows[0];
  return row?.kind === "lines" ? row.cells[0].lines : [];
};

describe("useLoadoutLines", () => {
  it("folds a part nested in a turret into one counted line with what it carries", () => {
    const moth = { slug: "argo-moth" } as Model;
    const { lineRows } = useLoadoutLines([moth], () => [
      turret(),
      turret(),
      turret(),
    ]);

    const lines = linesOf(
      lineRows([
        {
          key: "heads",
          label: "Heads",
          categories: [HardpointCategoryEnum.SALVAGE_HEADS],
        },
      ]),
    );

    expect(lines).toHaveLength(1);
    expect(lines[0]).toMatchObject({
      quantity: 3,
      size: "S2",
      name: "Baler Salvage Head",
      context: "Manned Turret",
    });
    expect(lines[0].parts.map((part) => [part.size, part.name])).toEqual([
      ["S1", "Cinch Scraper Module"],
      ["S1", "Abrade Scraper Module"],
    ]);
  });

  it("folds identical heads on a left and a right arm into one line", () => {
    const arm = (side: string) =>
      part(
        `hardpoint_salvage_arm_${side}`,
        HardpointCategoryEnum.WEAPON_MOUNTS,
        {
          name: undefined,
          type: "ToolArm",
          size: "1",
        },
        [
          part(
            "hardpoint_salvage_arm_head",
            HardpointCategoryEnum.SALVAGE_HEADS,
            {
              name: "Salvation Salvage Head",
              size: "1",
            },
          ),
        ],
      );
    const { lineRows } = useLoadoutLines(
      [{ slug: "rsi-salvation" } as Model],
      () => [arm("left"), arm("right")],
    );

    const lines = linesOf(
      lineRows([
        {
          key: "heads",
          label: "Heads",
          categories: [HardpointCategoryEnum.SALVAGE_HEADS],
        },
      ]),
    );

    expect(lines.map((line) => [line.quantity, line.context])).toEqual([
      [2, "Salvage Arm"],
    ]);
  });

  it("drops a row no compared ship fits anything in", () => {
    const { lineRows } = useLoadoutLines([{ slug: "a" } as Model], () => []);

    expect(
      lineRows([
        {
          key: "heads",
          label: "Heads",
          categories: [HardpointCategoryEnum.SALVAGE_HEADS],
        },
      ]),
    ).toEqual([]);
  });
});
