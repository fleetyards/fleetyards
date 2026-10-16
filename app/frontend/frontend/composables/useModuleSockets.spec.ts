import { describe, expect, it, vi } from "vitest";
import type { ModelModule } from "@/services/fyApi";
import { useModuleSockets } from "./useModuleSockets";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number, unit?: string) =>
      unit === "cargo" ? `${value} SCU` : String(value),
  }),
}));

const MODULES = [
  {
    id: "cargo",
    name: "Front Cargo Module",
    slot: "hardpoint_front_module",
    stock: true,
    manufacturer: { name: "Aegis Dynamics" },
    metrics: { cargo: 36 },
    media: { storeImage: { smallUrl: "cargo.jpg" } },
  },
  {
    id: "small-cargo",
    name: "Front Small Cargo",
    slot: "hardpoint_front_module",
    metrics: { cargo: 12 },
    media: {},
  },
  {
    id: "rear",
    name: "Rear Living Module",
    slot: "hardpoint_rear_module",
    media: {},
  },
  {
    id: "loose",
    name: "Mystery Module",
    media: {},
  },
] as unknown as ModelModule[];

describe("useModuleSockets", () => {
  it("makes one socket per slot, holding what is fitted", () => {
    const { groups } = useModuleSockets();

    const [group] = groups(MODULES, { hardpoint_front_module: "cargo" });

    expect(group.label).toBeUndefined();
    expect(group.slots.map((slot) => slot.id)).toEqual([
      "hardpoint_front_module",
      "hardpoint_rear_module",
    ]);
    expect(group.slots[0].label).toBe("labels.vehicleLoadout.slots.front");
    expect(group.slots[0].item).toEqual({
      id: "cargo",
      name: "Front Cargo Module",
      image: "cargo.jpg",
      figure: "36 SCU",
    });
    expect(group.slots[1].item).toBeUndefined();
  });

  it("leaves out the empty sockets when asked for what is fitted only", () => {
    const { groups } = useModuleSockets();

    const [group] = groups(
      MODULES,
      { hardpoint_rear_module: "rear" },
      { fittedOnly: true },
    );

    expect(group.slots.map((slot) => slot.id)).toEqual([
      "hardpoint_rear_module",
    ]);
    expect(groups(MODULES, {}, { fittedOnly: true })).toEqual([]);
  });

  it("offers a slot's modules with ownership, maker and figure", () => {
    const { options } = useModuleSockets();

    const offered = options(MODULES, "hardpoint_front_module", undefined, [
      "small-cargo",
    ]);

    expect(offered.map((option) => option.id)).toEqual([
      "cargo",
      "small-cargo",
    ]);
    expect(offered[0]).toMatchObject({
      manufacturer: "Aegis Dynamics",
      stock: true,
      owned: false,
      figure: "36 SCU",
      sortValues: { cargo: 36 },
    });
    expect(offered[1]).toMatchObject({ owned: true, stock: false });
  });

  it("says what each module changes against the one fitted", () => {
    const { options } = useModuleSockets();

    const offered = options(MODULES, "hardpoint_front_module", "cargo", []);

    expect(offered[0].delta).toBeUndefined();
    expect(offered[1].delta).toEqual({ label: "−24 SCU", tone: "worse" });
  });

  it("offers a cargo sort only where a candidate carries cargo", () => {
    const { options, sorts } = useModuleSockets();

    expect(
      sorts(options(MODULES, "hardpoint_front_module", undefined, [])),
    ).toEqual([{ key: "cargo", label: "labels.model.cargo" }]);
    expect(
      sorts(options(MODULES, "hardpoint_rear_module", undefined, [])),
    ).toEqual([]);
  });
});
