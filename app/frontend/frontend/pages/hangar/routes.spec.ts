import { createRouter, createMemoryHistory } from "vue-router";
import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { useSessionStore } from "@/frontend/stores/session";
import type { User, Vehicle } from "@/services/fyApi";
import { ensureQueryData } from "@/frontend/utils/RouteGuards/queryData";
import { routes } from "@/frontend/pages/routes";

vi.mock("@/frontend/utils/RouteGuards/queryData", () => ({
  ensureQueryData: vi.fn(),
}));

const id = "3f2a9c1e-1111-2222-3333-444455556666";

const lookup = vi.mocked(ensureQueryData);

describe("vehicle routes", () => {
  const router = createRouter({ history: createMemoryHistory(), routes });

  beforeEach(() => {
    setActivePinia(createPinia());
    useSessionStore().currentUser = { username: "me" } as User;
    lookup.mockReset();
  });

  // Each address arrives the way a typed or shared link does: from elsewhere.
  // `beforeEnter` does not run again for a change of params alone.
  const land = async (path: string) => {
    await router.push("/hangar/preview/");
    await router.push(path);

    const { name, params, query } = router.currentRoute.value;
    return { name, params, query };
  };

  it("opens the owner's vehicle", async () => {
    expect(await land(`/hangar/me/${id}-vulture/loadouts/`)).toMatchObject({
      name: "hangar-vehicle-loadouts",
      params: { username: "me", segment: `${id}-vulture` },
    });
  });

  it("sends a reader to the owner's public hangar instead", async () => {
    expect(await land(`/hangar/someone/${id}/loadouts/`)).toMatchObject({
      name: "hangar-public",
      params: { username: "someone" },
    });
  });

  // A static page under `/hangar/` and `/hangar/:username/` take the same
  // shape of address.
  it("opens the blueprints page rather than a hangar of that name", async () => {
    expect((await land("/hangar/blueprints/")).name).toBe("hangar-blueprints");
  });

  it("leaves the public hangar's own pages alone", async () => {
    expect((await land("/hangar/me/stats/")).name).toBe("hangar-public-stats");
    expect((await land("/hangar/me/wishlist/")).name).toBe("wishlist-public");
  });

  it("moves an address from before the owner was in it", async () => {
    lookup.mockResolvedValue({
      id,
      serial: "L8-4261-HA",
      name: "USCS Tanngnjostr",
    } as Vehicle);

    expect(await land("/hangar/L8-4261-HA/loadouts/?page=2")).toEqual({
      name: "hangar-vehicle-loadouts",
      params: { username: "me", segment: "l8-4261-ha-uscs-tanngnjostr" },
      query: { page: "2" },
    });
  });

  it("moves an old cargo ledger link, serial of any shape included", async () => {
    lookup.mockResolvedValue({ id, serial: "SUB FLAGSHIP" } as Vehicle);

    expect(await land("/hangar/SUB%20FLAGSHIP/cargo/transactions/")).toEqual({
      name: "hangar-vehicle-cargo",
      params: { username: "me", segment: id },
      query: { tab: "log" },
    });
  });

  it("moves an old cargo position link", async () => {
    lookup.mockResolvedValue({ id, name: "Titan" } as Vehicle);

    expect(await land(`/hangar/${id}/cargo/quantainium/`)).toMatchObject({
      name: "hangar-vehicle-cargo-item",
      params: { username: "me", segment: `${id}-titan`, item: "quantainium" },
    });
  });

  it("answers an old address that names no vehicle with a 404", async () => {
    lookup.mockRejectedValue(new Error("not found"));

    expect((await land("/hangar/NOPE/loadouts/")).name).toBe("404");
  });
});
