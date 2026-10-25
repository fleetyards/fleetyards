import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import type { BlueprintCostSlot, LoadoutComponentRef } from "@/services/fyApi";
import { craftedComponent } from "./craftedComponent";
import { NEUTRAL_QUALITY } from "./useQualityRamp";

// Crafting cases `test/lib/crafted_figures_test.rb` reads too, so the server's
// crafted figures and these cannot drift apart unnoticed. After a change to
// the arithmetic made on purpose, on both sides,
// `UPDATE_CRAFTED_FIGURES_FIXTURES=1` writes the new figures in.
const path = resolve(
  __dirname,
  "../../../../test/fixtures/crafted_figures/cases.json",
);

type Case = {
  case: string;
  slots: BlueprintCostSlot[];
  qualities: Record<string, number>;
  typeData: Record<string, unknown>;
  expected?: Record<string, unknown>;
};

const cases = JSON.parse(readFileSync(path, "utf8")) as Case[];

const craft = (fixture: Case) =>
  craftedComponent(
    {
      id: fixture.case,
      name: fixture.case,
      typeData: fixture.typeData,
    } as LoadoutComponentRef,
    fixture.slots,
    (position) => fixture.qualities[position] ?? NEUTRAL_QUALITY,
  ).typeData;

describe("craftedComponent against the shared fixtures", () => {
  if (process.env.UPDATE_CRAFTED_FIGURES_FIXTURES) {
    it("writes the figures", () => {
      const updated = cases.map((fixture) => ({
        ...fixture,
        expected: craft(fixture),
      }));
      writeFileSync(path, `${JSON.stringify(updated, null, 2)}\n`);
    });
    return;
  }

  it.each(cases.map((fixture) => [fixture.case, fixture] as const))(
    "%s",
    (_, fixture) => {
      expect(fixture.expected).toBeDefined();
      expect(craft(fixture)).toEqual(fixture.expected);
    },
  );
});
