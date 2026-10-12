import { describe, expect, it, vi } from "vitest";
import { usePositionTypeLabel } from "./usePositionTypeLabel";

const translations: Record<string, string> = {
  "labels.modelPosition.types.turret_gunner": "Turret gunner",
};

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => translations[key] ?? key,
    tExists: (key: string) => key in translations,
  }),
}));

describe("usePositionTypeLabel", () => {
  const positionTypeLabel = usePositionTypeLabel();

  it("translates a known position type", () => {
    expect(positionTypeLabel("turret_gunner")).toBe("Turret gunner");
  });

  it("reads an unmapped value as words rather than as an identifier", () => {
    expect(positionTypeLabel("cargo_handler")).toBe("cargo handler");
  });

  it("names nothing for a slot without a type", () => {
    expect(positionTypeLabel(null)).toBeNull();
    expect(positionTypeLabel(undefined)).toBeNull();
  });
});
