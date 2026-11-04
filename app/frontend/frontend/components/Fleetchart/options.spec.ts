import { describe, expect, it } from "vitest";
import type { FleetchartEntry } from "./geometry";
import { groupTitleOf, sortEntries } from "./options";
import { FleetchartGroups, FleetchartSorts } from "@/shared/stores/fleetchart";

const ship = (
  name: string,
  length: number,
  manufacturer = "RSI",
  productionStatus = "flight-ready",
) =>
  ({
    id: name,
    name,
    productionStatus,
    manufacturer: { code: "X", name: manufacturer },
    metrics: { fleetchartOffsetLength: length },
  }) as unknown as FleetchartEntry;

const names = (entries: FleetchartEntry[]) =>
  entries.map((entry) => (entry as unknown as { name: string }).name);

describe("sortEntries", () => {
  const ships = [ship("b", 30), ship("c", 10), ship("a", 20)];

  it("sorts by length either way", () => {
    expect(names(sortEntries(ships, FleetchartSorts.LENGTH_ASC))).toEqual([
      "c",
      "a",
      "b",
    ]);
    expect(names(sortEntries(ships, FleetchartSorts.LENGTH_DESC))).toEqual([
      "b",
      "a",
      "c",
    ]);
  });

  it("sorts by name", () => {
    expect(names(sortEntries(ships, FleetchartSorts.NAME))).toEqual([
      "a",
      "b",
      "c",
    ]);
  });

  it("sorts by the extended length in the extended state", () => {
    const folding = {
      id: "folding",
      name: "folding",
      metrics: { fleetchartOffsetLength: 5, extendedLength: 100 },
    } as unknown as FleetchartEntry;

    expect(
      names(
        sortEntries(
          [folding, ship("fixed", 50)],
          FleetchartSorts.LENGTH_DESC,
          FleetchartGroups.NONE,
          true,
        ),
      ),
    ).toEqual(["folding", "fixed"]);
  });

  it("keeps the list's order", () => {
    expect(names(sortEntries(ships, FleetchartSorts.LIST))).toEqual([
      "b",
      "c",
      "a",
    ]);
  });

  it("does not reorder what it was given", () => {
    sortEntries(ships, FleetchartSorts.NAME);

    expect(names(ships)).toEqual(["b", "c", "a"]);
  });

  it("keeps a group's ships together, sorted within it", () => {
    const mixed = [
      ship("a", 30, "RSI"),
      ship("b", 20, "Anvil"),
      ship("c", 10, "RSI"),
      ship("d", 40, "Anvil"),
    ];

    expect(
      names(
        sortEntries(
          mixed,
          FleetchartSorts.LENGTH_ASC,
          FleetchartGroups.MANUFACTURER,
        ),
      ),
    ).toEqual(["b", "d", "c", "a"]);
  });
});

describe("groupTitleOf", () => {
  const t = (key: string) => `translated:${key}`;

  it("uses the manufacturer's name", () => {
    expect(
      groupTitleOf(ship("a", 1, "Anvil"), FleetchartGroups.MANUFACTURER, t),
    ).toBe("Anvil");
  });

  it("translates a production status", () => {
    expect(groupTitleOf(ship("a", 1), FleetchartGroups.STATUS, t)).toBe(
      "translated:labels.model.productionStatus.flight-ready",
    );
  });

  it("is empty when the ship has no value to group by", () => {
    expect(groupTitleOf(ship("a", 1), FleetchartGroups.CLASSIFICATION, t)).toBe(
      "",
    );
  });
});
