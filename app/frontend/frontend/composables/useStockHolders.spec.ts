import { describe, expect, it, vi } from "vitest";
import {
  UNASSIGNED,
  holderIdFor,
  shareOf,
  useStockHolders,
} from "./useStockHolders";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toQuantity: (value: number) => String(value),
  }),
}));

const alice = { id: "alice", username: "alice" };
const bob = { id: "bob", username: "bob" };

const rows = [
  {
    holders: [
      { holder: alice, netQuantity: 10 },
      { holder: null, netQuantity: 5 },
    ],
  },
  {
    holders: [
      { holder: bob, netQuantity: 12 },
      { holder: alice, netQuantity: 4 },
    ],
  },
];

describe("useStockHolders", () => {
  it("adds up one holder's share across rows", () => {
    expect(shareOf(rows, "alice")).toBe(14);
    expect(shareOf(rows, UNASSIGNED)).toBe(5);
  });

  it("sends the unassigned share as null", () => {
    expect(holderIdFor(UNASSIGNED)).toBeNull();
    expect(holderIdFor(undefined)).toBeNull();
    expect(holderIdFor("alice")).toBe("alice");
  });

  it("lists each holder once, largest first, the unassigned share last", () => {
    const { holderOptions } = useStockHolders();

    expect(holderOptions(rows, "units").map((option) => option.value)).toEqual([
      "alice",
      "bob",
      UNASSIGNED,
    ]);
    expect(holderOptions(rows, "units")[0].label).toBe(
      "alice · 14 labels.logistics.units.units",
    );
  });

  it("names the holder alone when the rows do not share a unit", () => {
    const { holderOptions } = useStockHolders();

    expect(holderOptions(rows).map((option) => option.label)).toEqual([
      "alice",
      "bob",
      "labels.logistics.unassigned",
    ]);
  });
});
