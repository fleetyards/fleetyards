import { describe, expect, it } from "vitest";
import { NEUTRAL_COLOR, colorToSubmit } from "./useSquadronForm";

describe("colorToSubmit", () => {
  it("keeps a squadron without a colour uncoloured when nobody picked one", () => {
    expect(colorToSubmit(NEUTRAL_COLOR, null)).toBeNull();
  });

  it("writes a colour somebody picked for a squadron without one", () => {
    expect(colorToSubmit("#dc3545", null)).toBe("#dc3545");
  });

  it("writes a colour picked while creating a squadron", () => {
    expect(colorToSubmit("#dc3545", undefined)).toBe("#dc3545");
  });

  it("writes the neutral over a colour the squadron had", () => {
    expect(colorToSubmit(NEUTRAL_COLOR, "#dc3545")).toBe(NEUTRAL_COLOR);
  });

  it("keeps the colour a squadron already has", () => {
    expect(colorToSubmit("#dc3545", "#dc3545")).toBe("#dc3545");
  });

  it("writes a new colour over an old one", () => {
    expect(colorToSubmit("#28a745", "#dc3545")).toBe("#28a745");
  });
});
