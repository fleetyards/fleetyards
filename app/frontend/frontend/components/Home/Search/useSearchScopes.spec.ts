import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";
import { useSearchStore } from "@/frontend/stores/search";
import { fleetSearch, hangarSearch, search } from "@/services/fyApi";
import { useSearchScopes } from "./useSearchScopes";

const authenticated = { value: true };
const route = ref<{ path: string; params: Record<string, string> }>({
  path: "/ships/",
  params: {},
});

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () =>
    new Proxy({}, { get: (_, key: "path" | "params") => route.value[key] }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  search: vi.fn(async () => ({ groups: [] })),
  hangarSearch: vi.fn(async () => ({ groups: [] })),
  fleetSearch: vi.fn(async () => ({ groups: [] })),
}));

const keys = (scopes: { value: { key: string }[] }) =>
  scopes.value.map((scope) => scope.key);

describe("useSearchScopes", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    authenticated.value = true;
    route.value = { path: "/ships/", params: {} };
    vi.mocked(fleetSearch).mockClear();
    vi.mocked(fleetSearch).mockResolvedValue({ groups: [] });
  });

  it("offers a guest the catalogue alone, whatever was saved", () => {
    authenticated.value = false;
    useSearchStore().scope = "mine";

    const { scopes, current } = useSearchScopes();

    expect(keys(scopes)).toEqual(["catalogue"]);
    expect(current.value.key).toBe("catalogue");
  });

  it("offers the fleet only once there is one", () => {
    const { scopes } = useSearchScopes();

    expect(keys(scopes)).toEqual(["catalogue", "mine"]);
  });

  it("searches the fleet being viewed, and remembers it", async () => {
    route.value = {
      path: "/fleets/diggers/members/",
      params: { slug: "diggers" },
    };

    const { scopes } = useSearchScopes();
    await scopes.value[2].search("omni");

    expect(fleetSearch).toHaveBeenCalledWith("diggers", { q: "omni" });
    expect(useSearchStore().fleetSlug).toBe("diggers");
  });

  it("ignores a slug that is not a fleet's", () => {
    route.value = { path: "/ships/orig-100i/", params: { slug: "orig-100i" } };

    expect(keys(useSearchScopes().scopes)).toEqual(["catalogue", "mine"]);
  });

  it("falls back on the last fleet elsewhere", () => {
    useSearchStore().fleetSlug = "diggers";

    const { scopes } = useSearchScopes();

    expect(scopes.value[2].fleetSlug).toBe("diggers");
  });

  it("drops a fleet that refuses, and falls back to the catalogue", async () => {
    const store = useSearchStore();
    store.fleetSlug = "left";
    store.scope = "fleet";
    vi.mocked(fleetSearch).mockRejectedValue({ response: { status: 404 } });

    const { scopes, current } = useSearchScopes();
    await expect(current.value.search("omni")).rejects.toBeDefined();
    await flushPromises();

    expect(store.fleetSlug).toBeUndefined();
    expect(keys(scopes)).toEqual(["catalogue", "mine"]);
    expect(current.value.key).toBe("catalogue");
  });

  it("keeps the fleet through a failure that says nothing about access", async () => {
    const store = useSearchStore();
    store.fleetSlug = "diggers";
    vi.mocked(fleetSearch).mockRejectedValue({ response: { status: 500 } });

    const { scopes } = useSearchScopes();
    await expect(scopes.value[2].search("omni")).rejects.toBeDefined();

    expect(store.fleetSlug).toBe("diggers");
  });

  it("steps through the scopes both ways and saves the choice", () => {
    const { step } = useSearchScopes();
    const store = useSearchStore();

    step(1);
    expect(store.scope).toBe("mine");
    step(1);
    expect(store.scope).toBe("catalogue");
    step(-1);
    expect(store.scope).toBe("mine");
  });

  it("asks each scope's own endpoint", async () => {
    const { scopes } = useSearchScopes();

    await scopes.value[0].search("omni");
    await scopes.value[1].search("omni");

    expect(search).toHaveBeenCalledWith({ q: "omni" });
    expect(hangarSearch).toHaveBeenCalledWith({ q: "omni" });
  });
});
