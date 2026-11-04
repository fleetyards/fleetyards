import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { HangarPlanModel } from "@/services/fyApi";
import Component from "./index.vue";

const picker = vi.hoisted(() => ({ query: undefined as unknown }));

// The picker itself queries the catalogue; only what it is asked for matters
// here.
vi.mock("@/frontend/components/Models/PickerModal/index.vue", async () => {
  const { h } = await import("vue");

  return {
    default: {
      name: "ModelPickerModal",
      props: ["query"],
      setup: (props: { query: unknown }) => {
        picker.query = props.query;

        return () => h("div");
      },
    },
  };
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: ref(undefined) }),
}));

vi.mock("@/frontend/composables/useHangarPlanPairing", () => ({
  useHangarPlanPairing: () => ({ pairing: ref(false), pairEnd: vi.fn() }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

const scorpius: HangarPlanModel = {
  id: "scorpius",
  name: "Scorpius",
  slug: "scorpius",
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice: 240,
};

describe("Hangar/Planner/UpgradeTargetModal", () => {
  it("asks only for dearer ships RSI sells upgrades into", async () => {
    await mountWithDefaults(Component, {
      props: {
        planId: "plan",
        startName: "Scorpius",
        startModel: scorpius,
        vehicleId: "vehicle",
      },
    });

    expect(picker.query).toEqual({ ccuTarget: true, pledgePriceGt: 240 });
  });
});
