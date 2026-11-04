import { describe, expect, it } from "vitest";
import {
  catalogueEntriesFrom,
  cataloguePlacementsIn,
  isCatalogueEntry,
} from "./catalogueShips";
import type { Model } from "@/services/fyApi";

const model = (id: string) => ({ id, slug: id, name: id }) as unknown as Model;

describe("catalogueShips", () => {
  it("gives each placement of one model its own ship", () => {
    const entries = catalogueEntriesFrom(
      [
        { id: "first", modelId: "hornet" },
        { id: "second", modelId: "hornet" },
      ],
      [model("hornet")],
    );

    expect(entries.map(({ id, slug }) => [id, slug])).toEqual([
      ["first", "hornet"],
      ["second", "hornet"],
    ]);
    expect(entries.every(isCatalogueEntry)).toBe(true);
  });

  it("leaves out a placement whose model is no longer there", () => {
    expect(
      catalogueEntriesFrom(
        [{ id: "first", modelId: "gone" }],
        [model("hornet")],
      ),
    ).toEqual([]);
  });

  it("does not take a ship from a list of models or a hangar for one", () => {
    expect(isCatalogueEntry(model("hornet"))).toBe(false);
  });

  it("finds only the catalogue ships among the placements", () => {
    expect(
      cataloguePlacementsIn({
        owned: { x: 0, y: 0 },
        tried: { x: 1, y: 1, modelId: "hornet" },
      }),
    ).toEqual([{ id: "tried", modelId: "hornet" }]);
  });
});
