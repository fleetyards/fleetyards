import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it } from "vitest";
import type { FleetContract } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useContractEditAccess } from "./useContractEditAccess";

const contract = (overrides: Partial<FleetContract> = {}) =>
  ({
    personal: false,
    createdBy: { id: "author", username: "Ada" },
    ...overrides,
  }) as FleetContract;

describe("useContractEditAccess", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    useSessionStore().login({ id: "author", username: "Ada" } as never);
  });

  it("lets the contract privilege edit any contract", () => {
    expect(
      useContractEditAccess(contract(), ["fleet:contracts:update"]).value,
    ).toBe(true);
  });

  it("lets the author edit their own personal contract", () => {
    expect(
      useContractEditAccess(contract({ personal: true }), [
        "fleet:contracts:read",
      ]).value,
    ).toBe(true);
  });

  it("keeps a reader out of a fleet contract they wrote", () => {
    expect(
      useContractEditAccess(contract(), ["fleet:contracts:read"]).value,
    ).toBe(false);
  });

  it("keeps a reader out of somebody else's personal contract", () => {
    expect(
      useContractEditAccess(
        contract({
          personal: true,
          createdBy: { id: "other", username: "Bo" },
        }),
        ["fleet:contracts:read"],
      ).value,
    ).toBe(false);
  });
});
