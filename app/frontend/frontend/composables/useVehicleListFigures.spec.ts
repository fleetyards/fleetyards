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
  useVehicleListFigures,
  useVehicleFigureRows,
  VehicleListFigureEnum,
} from "./useVehicleListFigures";

const vehicle = (overrides: Record<string, unknown> = {}) =>
  ({
    weaponSizes: [
      { size: 2, count: 4 },
      { size: 3, count: 2 },
    ],
    alpha: 1234.4,
    burstDps: 0,
    sustainedDpsMin: 300,
    sustainedDpsMax: 450,
    model: { pledgePrice: 90 },
    ...overrides,
  }) as never;

describe("useVehicleListFigures", () => {
  beforeEach(() => {
    route.query = {};
  });

  it("names nothing for a sort and filters the details already show", () => {
    route.query = { lengthGteq: "20" };

    const figures = useVehicleListFigures(() => "modelLength asc");

    expect(figures.value).toEqual([]);
  });

  it("leads with the sorted figure, then the filtered ones, once each", () => {
    route.query = {
      alphaGteq: "500",
      pledgePriceIn: ["0-50"],
      burstDpsLteq: "",
    };

    const figures = useVehicleListFigures(() => "alpha desc");

    expect(figures.value).toEqual([
      VehicleListFigureEnum.ALPHA,
      VehicleListFigureEnum.PLEDGE_PRICE,
    ]);
  });

  it("follows the sort as it changes", () => {
    let sort = "maxWeaponSize desc";
    const figures = useVehicleListFigures(() => sort);

    expect(figures.value).toEqual([VehicleListFigureEnum.WEAPONS]);

    sort = "sustainedDpsMax desc";
    route.query = { s: sort };

    expect(figures.value).toEqual([VehicleListFigureEnum.SUSTAINED_DPS]);
  });
});

describe("useVehicleFigureRows", () => {
  it("formats each figure as the list view's column does", () => {
    const rows = useVehicleFigureRows()(vehicle(), [
      VehicleListFigureEnum.WEAPONS,
      VehicleListFigureEnum.ALPHA,
      VehicleListFigureEnum.BURST_DPS,
      VehicleListFigureEnum.SUSTAINED_DPS,
      VehicleListFigureEnum.PLEDGE_PRICE,
    ]);

    expect(rows).toEqual([
      {
        label: "labels.hangarTable.columns.maxWeaponSize",
        value: "2×S3 · 4×S2",
      },
      { label: "labels.hangarTable.columns.alpha", value: "1234" },
      { label: "labels.hangarTable.columns.burstDps", value: "0" },
      { label: "labels.hangarTable.columns.sustainedDpsMax", value: "300–450" },
      { label: "labels.hangarTable.columns.modelPledgePrice", value: "$90" },
    ]);
  });

  it("reads N/A where a ship has no figure", () => {
    const rows = useVehicleFigureRows()(
      vehicle({ weaponSizes: [], alpha: null }),
      [VehicleListFigureEnum.WEAPONS, VehicleListFigureEnum.ALPHA],
    );

    expect(rows.map((row) => row.value)).toEqual([
      "labels.not-available",
      "labels.not-available",
    ]);
  });
});
