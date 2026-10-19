import { describe, expect, it } from "vitest";
import { markedAgainstStock } from "./stock";

describe("markedAgainstStock", () => {
  it("marks the figures that differ from the catalogue's", () => {
    const marked = markedAgainstStock(
      [
        { key: "shields.hp", label: "HP", value: "1,100" },
        { key: "shields.regen", label: "Regen", value: "50" },
      ],
      [
        { key: "shields.hp", label: "HP", value: "1,000" },
        { key: "shields.regen", label: "Regen", value: "50" },
      ],
    );

    expect(marked[0].stock).toBe("1,000");
    expect(marked[1].stock).toBeUndefined();
  });

  it("leaves the stats alone without a catalogue record", () => {
    const stats = [{ key: "shields.hp", label: "HP", value: "1,100" }];

    expect(markedAgainstStock(stats)).toBe(stats);
  });
});
