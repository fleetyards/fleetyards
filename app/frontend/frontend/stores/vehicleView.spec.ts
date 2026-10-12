import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useVehicleViewStore } from "./vehicleView";

describe("vehicleView store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("switches the 3D view for one vehicle only", () => {
    const store = useVehicleViewStore();

    store.toggleHolo("vehicle-1");

    expect(store.holoVisible("vehicle-1")).toBe(true);
    expect(store.holoVisible("vehicle-2")).toBe(false);
  });

  it("switches it back", () => {
    const store = useVehicleViewStore();

    store.toggleHolo("vehicle-1");
    store.toggleHolo("vehicle-1");

    expect(store.holoVisible("vehicle-1")).toBe(false);
  });
});
