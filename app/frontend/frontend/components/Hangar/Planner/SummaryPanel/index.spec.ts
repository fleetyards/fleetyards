import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { HangarPlanSummary, HangarPlanTotals } from "@/services/fyApi";
import Component from "./index.vue";

const summary = (totals: Partial<HangarPlanTotals>) =>
  ({
    issues: [],
    slots: [],
    totals: {
      spendMin: 0,
      spendMax: 0,
      routedSpend: 0,
      maxSpend: 0,
      meltCredit: 0,
      startingCredit: 0,
      buybackCash: 0,
      buybackTokensUsed: 0,
      buybackTokensAvailable: 0,
      netMin: 0,
      netMax: 0,
      cashNeededMin: 0,
      cashNeededMax: 0,
      remainingCreditMin: 0,
      remainingCreditMax: 0,
      openSlotsCount: 0,
      undecidedSlotsCount: 0,
      unresolvedCount: 0,
      complete: false,
      ...totals,
    },
  }) as unknown as HangarPlanSummary;

const gaps = async (totals: Partial<HangarPlanTotals>) =>
  (
    await mountWithDefaults(Component, {
      props: { summary: summary(totals) },
    })
  )
    .findAll(".plan-summary__gaps li")
    .map((gap) => gap.attributes("data-test"));

describe("Hangar/Planner/SummaryPanel", () => {
  it("names every kind of slot still in the way, not only routeless ships", async () => {
    expect(
      await gaps({
        unresolvedCount: 1,
        undecidedSlotsCount: 4,
        openSlotsCount: 2,
      }),
    ).toEqual([
      "hangar-plan-summary-gap-unresolved",
      "hangar-plan-summary-gap-undecidedSlots",
      "hangar-plan-summary-gap-openSlots",
    ]);
  });

  it("leaves out what the plan has none of", async () => {
    expect(await gaps({ undecidedSlotsCount: 4 })).toEqual([
      "hangar-plan-summary-gap-undecidedSlots",
    ]);
    expect(await gaps({})).toEqual([]);
  });
});
