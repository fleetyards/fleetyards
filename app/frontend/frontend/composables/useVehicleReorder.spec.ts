import { beforeEach, describe, expect, it, vi } from "vitest";
import type { Vehicle, VehicleMoveInput } from "@/services/fyApi";

type MoveCall = { id: string; data: VehicleMoveInput };

const move = vi.fn((_variables: MoveCall) => Promise.resolve());
const displayAlert = vi.fn();

vi.mock("@/services/fyApi", () => ({
  useMoveVehicle: () => ({ mutateAsync: move }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const { useVehicleReorder } = await import("./useVehicleReorder");

const vehicle = (id: string) => ({ id }) as Vehicle;

const setup = () => {
  const items = ref<Vehicle[] | undefined>(
    ["alpha", "bravo", "charlie"].map(vehicle),
  );

  return { items, ...useVehicleReorder(items) };
};

const ids = (vehicles: Vehicle[]) => vehicles.map((item) => item.id);

describe("useVehicleReorder", () => {
  beforeEach(() => {
    move.mockReset();
    move.mockImplementation(() => Promise.resolve());
    displayAlert.mockClear();
  });

  it("starts in the order the server sent", () => {
    const { orderedVehicles } = setup();

    expect(ids(orderedVehicles.value)).toEqual(["alpha", "bravo", "charlie"]);
  });

  it("places a dragged ship after the one now ahead of it", async () => {
    const { onSort } = setup();

    await onSort(["bravo", "charlie", "alpha"], "alpha");

    expect(move).toHaveBeenCalledTimes(1);
    expect(move).toHaveBeenCalledWith({
      id: "alpha",
      data: { afterId: "charlie" },
    });
  });

  // Nothing is ahead of a ship dropped at the top of a page, and the ship that
  // is ahead of it in the whole order sits on the page before.
  it("places a ship dragged to the top before the one now behind it", async () => {
    const { onSort } = setup();

    await onSort(["charlie", "alpha", "bravo"], "charlie");

    expect(move).toHaveBeenCalledWith({
      id: "charlie",
      data: { beforeId: "alpha" },
    });
  });

  it("redraws the order without waiting for the server", () => {
    move.mockImplementation(() => new Promise(() => undefined));
    const { onSort, orderedVehicles } = setup();

    void onSort(["bravo", "alpha", "charlie"], "alpha");

    expect(ids(orderedVehicles.value)).toEqual(["bravo", "alpha", "charlie"]);
  });

  it("puts the ship back and says so when the move fails", async () => {
    move.mockImplementation(() => Promise.reject(new Error("nope")));
    const { onSort, orderedVehicles } = setup();

    await onSort(["bravo", "alpha", "charlie"], "alpha");

    expect(ids(orderedVehicles.value)).toEqual(["alpha", "bravo", "charlie"]);
    expect(displayAlert).toHaveBeenCalledWith({
      text: "messages.vehicle.move.failure",
    });
  });

  it("follows the server when it sends a new page", async () => {
    const { items, orderedVehicles } = setup();

    items.value = ["delta", "echo"].map(vehicle);
    await nextTick();

    expect(ids(orderedVehicles.value)).toEqual(["delta", "echo"]);
  });

  it("ignores a drop for a ship it does not hold", async () => {
    const { onSort } = setup();

    await onSort(["alpha", "bravo"], "zulu");

    expect(move).not.toHaveBeenCalled();
  });
});
