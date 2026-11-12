import { describe, expect, it } from "vitest";
import { sortByFilled } from "./useSlotTitle";

describe("sortByFilled", () => {
  it("puts the lead first, then filled seats, then open ones, keeping each group's order", () => {
    const seats = [
      { id: "open-a", candidates: [] },
      { id: "filled-a", candidates: [{}] },
      { id: "lead", lead: true, candidates: [] },
      { id: "open-b" },
      { id: "filled-b", candidates: [{}] },
    ];

    expect(sortByFilled(seats).map((seat) => seat.id)).toEqual([
      "lead",
      "filled-a",
      "filled-b",
      "open-a",
      "open-b",
    ]);
  });
});
