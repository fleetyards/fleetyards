import { describe, it, expect, vi, beforeEach } from "vitest";
import { reactive } from "vue";

const route = reactive<{ query: Record<string, unknown> }>({ query: {} });

vi.mock("vue-router", () => ({ useRoute: () => route }));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: unknown) => String(value),
    toDollar: (value: number) => `$${value}`,
  }),
}));

import {
  ModelListFigureEnum,
  useModelFigureRows,
  useModelListFigures,
} from "./useModelListFigures";

const model = (overrides: Record<string, unknown> = {}) =>
  ({
    weaponSizes: [{ size: 3, count: 2 }],
    alpha: 1234.4,
    burstDps: null,
    sustainedDpsMin: 300,
    sustainedDpsMax: 450,
    pledgePrice: 90,
    ...overrides,
  }) as never;

describe("useModelListFigures", () => {
  beforeEach(() => {
    route.query = {};
  });

  it("names nothing for a sort the details already show", () => {
    route.query = { lengthGteq: "20" };

    expect(useModelListFigures(() => "length asc").value).toEqual([]);
  });

  it("leads with the sorted figure, then the filtered one", () => {
    route.query = { pledgePriceIn: ["0-50"] };

    expect(useModelListFigures(() => "alpha desc").value).toEqual([
      ModelListFigureEnum.ALPHA,
      ModelListFigureEnum.PLEDGE_PRICE,
    ]);
  });
});

describe("useModelFigureRows", () => {
  it("formats each figure under its column's label", () => {
    const rows = useModelFigureRows()(model(), [
      ModelListFigureEnum.WEAPONS,
      ModelListFigureEnum.ALPHA,
      ModelListFigureEnum.SUSTAINED_DPS,
      ModelListFigureEnum.PLEDGE_PRICE,
    ]);

    expect(rows).toEqual([
      { label: "labels.models.table.columns.maxWeaponSize", value: "2×S3" },
      { label: "labels.models.table.columns.alpha", value: "1234" },
      {
        label: "labels.models.table.columns.sustainedDpsMax",
        value: "300–450",
      },
      { label: "labels.models.table.columns.pledgePrice", value: "$90" },
    ]);
  });

  it("says a ship without the figure has none", () => {
    const rows = useModelFigureRows()(model(), [ModelListFigureEnum.BURST_DPS]);

    expect(rows[0].value).toBe("labels.not-available");
  });
});
