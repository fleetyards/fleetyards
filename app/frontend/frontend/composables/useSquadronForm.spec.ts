import { describe, expect, it } from "vitest";
import { NEUTRAL_COLOR, colorToSubmit } from "./useSquadronForm";

describe("colorToSubmit", () => {
  it("keeps a squadron without a colour uncoloured when nobody picked one", () => {
    expect(
      colorToSubmit(NEUTRAL_COLOR, { previous: null, changed: false }),
    ).toBeNull();
  });

  it("writes a colour somebody picked", () => {
    expect(colorToSubmit("#dc3545", { previous: null, changed: true })).toBe(
      "#dc3545",
    );
  });

  it("writes the neutral when it was picked on purpose", () => {
    expect(
      colorToSubmit(NEUTRAL_COLOR, { previous: "#dc3545", changed: true }),
    ).toBe(NEUTRAL_COLOR);
  });

  it("keeps the colour a squadron already has", () => {
    expect(
      colorToSubmit("#dc3545", { previous: "#dc3545", changed: false }),
    ).toBe("#dc3545");
  });
});
