import { describe, expect, it, vi } from "vitest";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, params?: Record<string, string>) =>
      `${key}(${Object.values(params ?? {}).join(",")})`,
  }),
}));

import { useContractRoute } from "./useContractRoute";

const { destinationName, routeLabel } = useContractRoute();

const end = (name: string, holder: "fleet" | "user") => ({
  id: name,
  name,
  slug: name,
  holder,
});

describe("useContractRoute", () => {
  it("names a fleet destination as it is", () => {
    expect(
      destinationName({ destination: end("Depot", "fleet") } as never),
    ).toBe("Depot");
  });

  it("names a hangar destination as the author's", () => {
    const contract = {
      destination: end("Locker", "user"),
      createdBy: { id: "ada", username: "Ada" },
    };

    expect(destinationName(contract as never)).toBe(
      "labels.fleets.contracts.authorHangarInventory(Locker,Ada)",
    );
  });

  it("joins a haul's two ends into one leg", () => {
    const contract = {
      source: end("Port", "fleet"),
      destination: end("Locker", "user"),
      createdBy: { id: "ada", username: "Ada" },
    };

    expect(routeLabel(contract as never)).toBe(
      "Port → labels.fleets.contracts.authorHangarInventory(Locker,Ada)",
    );
  });

  it("has no route without a destination", () => {
    expect(routeLabel({ destination: null } as never)).toBeUndefined();
  });
});
