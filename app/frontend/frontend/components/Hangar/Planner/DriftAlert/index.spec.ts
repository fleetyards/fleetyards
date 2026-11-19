import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { HangarPlanDrift, HangarPlanModel } from "@/services/fyApi";
import Component from "./index.vue";

const model = (name: string): HangarPlanModel => ({
  id: name,
  name,
  slug: name.toLowerCase(),
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice: 100,
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useRebaseHangarPlan: () => ({
    mutateAsync: vi.fn(),
    isPending: ref(false),
  }),
}));

vi.mock("@/frontend/composables/useHangarPlanCache", () => ({
  useHangarPlanCache: () => ({ updatePlan: vi.fn() }),
}));

const drift: HangarPlanDrift = {
  basedOnAt: "2026-11-18T00:00:00Z",
  missingSources: [],
  changedSources: [],
  newVehicles: [],
  arrivals: [
    { acquisitionId: "route", vehicleId: "ship", model: model("Carrack") },
  ],
  heldUpgrades: [
    { stepId: "step", fromModel: model("Cutlass"), toModel: model("Carrack") },
  ],
  previousTotal: 0,
  currentTotal: 0,
  drifted: true,
};

describe("HangarPlannerDriftAlert", () => {
  it("names the ships and upgrades an update carries the plan on to", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { planId: "plan", drift },
    });

    const text = wrapper.find('[data-test="hangar-plan-drift"]').text();
    expect(text).toContain("Now in your hangar as planned: Carrack");
    expect(text).toContain(
      "Upgrades now in your hangar, no longer to buy: Cutlass → Carrack",
    );
  });
});
