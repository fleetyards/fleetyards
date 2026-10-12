import { QueryClient } from "@tanstack/vue-query";
import { describe, expect, it, vi } from "vitest";
import { getShowVehicleQueryKey, type Vehicle } from "@/services/fyApi";
import { useVehicleMutations } from "./useVehicleMutations";

const queryClient = new QueryClient();

vi.mock("@tanstack/vue-query", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useQueryClient: () => queryClient,
}));

const id = "3f2a9c1e-1111-2222-3333-444455556666";

describe("invalidateVehiclePage", () => {
  it("hands a new serial to every page the vehicle is open under", async () => {
    const before = { id, serial: "L8-4261-HA", name: "Titan" } as Vehicle;
    const after = { ...before, serial: "QX-0001-AB" } as Vehicle;

    queryClient.setQueryData(getShowVehicleQueryKey(before.serial!), before);

    await useVehicleMutations().invalidateVehiclePage(after);

    // The page still open under the old serial gets the answer rather than a
    // refetch that would 404, and the address it moves to is already filled.
    expect(
      queryClient.getQueryData(getShowVehicleQueryKey("L8-4261-HA")),
    ).toMatchObject({ serial: "QX-0001-AB" });
    expect(
      queryClient.getQueryData(getShowVehicleQueryKey("QX-0001-AB")),
    ).toMatchObject({ id, serial: "QX-0001-AB" });
  });
});
