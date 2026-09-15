import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { RouteRecordRaw } from "vue-router";

const currentRoute = {
  name: "" as string,
  meta: {} as Record<string, unknown>,
  matched: [] as unknown[],
};

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () => currentRoute,
}));

const { useActiveTab, routeName, isTabRoute } = await import("./useActiveTab");

const tab = (name: string): RouteRecordRaw =>
  ({ path: name, name, component: {} }) as RouteRecordRaw;

const tabs = ref<RouteRecordRaw[]>([
  tab("admin-fleet-edit"),
  tab("admin-fleet-members"),
  tab("admin-fleet-inventories"),
]);

const at = (name: string, meta: Record<string, unknown> = {}) => {
  currentRoute.name = name;
  currentRoute.meta = meta;
  currentRoute.matched = [];

  return useActiveTab(tabs);
};

describe("useActiveTab", () => {
  it("lights the tab you are standing on", () => {
    const { isActive } = at("admin-fleet-members");

    expect(isActive("admin-fleet-members")).toBe(true);
    expect(isActive("admin-fleet-inventories")).toBe(false);
  });

  // Without this the strip goes blank the moment you open a record.
  it("lights the tab a detail page names", () => {
    const { isActive, activeRoute } = at("admin-fleet-inventory", {
      activeTab: "admin-fleet-inventories",
    });

    expect(isActive("admin-fleet-inventories")).toBe(true);
    expect(isActive("admin-fleet-members")).toBe(false);
    expect(routeName(activeRoute.value!)).toBe("admin-fleet-inventories");
  });

  it("lights it from a detail page nested deeper still", () => {
    const { isActive } = at("admin-fleet-inventory-item", {
      activeTab: "admin-fleet-inventories",
    });

    expect(isActive("admin-fleet-inventories")).toBe(true);
  });

  it("lights nothing when the page claims no tab", () => {
    const { isActive, activeRoute } = at("admin-fleet-inventory");

    expect(tabs.value.every((t) => !isActive(routeName(t)))).toBe(true);
    expect(activeRoute.value).toBeUndefined();
  });

  /*
   * A grouped tab carries no name of its own: it redirects to its first child,
   * and `routeName` reports that. Standing on any child has to keep the group
   * lit, which is the case the `activeTab` shortcut must not have broken.
   */
  it("still lights a grouped tab from one of its children", () => {
    const group = {
      path: ":id/",
      component: {},
      children: [
        { path: "", name: "admin-commodity-edit", component: {} },
        { path: "prices", name: "admin-commodity-edit-prices", component: {} },
      ],
      redirect: { name: "admin-commodity-edit" },
    } as unknown as RouteRecordRaw;

    const grouped = ref<RouteRecordRaw[]>([group]);

    expect(routeName(group)).toBe("admin-commodity-edit");

    currentRoute.name = "admin-commodity-edit-prices";
    currentRoute.meta = {};
    currentRoute.matched = [{ redirect: { name: "admin-commodity-edit" } }];

    const { isActive } = useActiveTab(grouped);

    expect(isActive("admin-commodity-edit")).toBe(true);
  });

  /*
   * An old path kept alive as a redirect carries a function, and a function
   * written inline is named after the property it sits on -- so an unguarded
   * read reported every one of them as a tab called "redirect", which is a
   * route nobody registered.
   */
  it("reads no name off a redirect written as a function", () => {
    const legacy = {
      path: "cargo/transactions/",
      redirect: (to: { params: unknown }) => ({
        name: "hangar-vehicle-cargo",
        params: to.params,
      }),
    } as unknown as RouteRecordRaw;

    expect(routeName(legacy)).toBeUndefined();
    expect(isTabRoute(legacy)).toBe(false);
  });

  it("keeps a route that redirects by name as a tab", () => {
    const group = {
      path: ":id/",
      redirect: { name: "admin-commodity-edit" },
    } as unknown as RouteRecordRaw;

    expect(isTabRoute(group)).toBe(true);
    expect(isTabRoute(tab("admin-fleet-members"))).toBe(true);
  });
});
