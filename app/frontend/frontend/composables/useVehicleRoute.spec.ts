import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it } from "vitest";
import { useSessionStore } from "@/frontend/stores/session";
import type { User } from "@/services/fyApi";
import { useVehicleRoute } from "./useVehicleRoute";

const vehicle = { id: "v-1", serial: "L8-4261-HA", name: "Titan" };

describe("useVehicleRoute", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("addresses the vehicle in the reader's hangar", () => {
    useSessionStore().currentUser = { username: "me" } as User;

    expect(useVehicleRoute()("hangar-vehicle-log", vehicle)).toEqual({
      name: "hangar-vehicle-log",
      params: { username: "me", segment: "l8-4261-ha-titan" },
    });
  });

  // Never the bare `/hangar/v-1/`: that is a public hangar's address.
  it("falls back to an old address that still redirects", () => {
    const route = useVehicleRoute();

    expect(route("hangar-vehicle", vehicle)).toBe("/hangar/v-1/loadouts/");
    expect(route("hangar-vehicle-cargo-item", vehicle, { item: "ore" })).toBe(
      "/hangar/v-1/cargo/ore/",
    );
  });
});
