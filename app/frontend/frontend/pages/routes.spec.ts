import { createRouter, createMemoryHistory } from "vue-router";
import { describe, expect, it } from "vitest";
import { routes } from "./routes";
import { CATALOGUE_TENANTS, isTenantActive } from "./catalogue/tenants";

/*
 * The friends list moved under settings. Notifications written before it did
 * carry /friends as their link and those rows outlive the move, as do the tab
 * links somebody was sent -- a redirect that dropped the tab would answer all
 * four of them with the accepted list.
 */
describe("frontend routes", () => {
  const router = createRouter({ history: createMemoryHistory(), routes });

  // `resolve` stops at the record that matched; only a navigation follows the
  // redirect it holds, which is the thing under test.
  it.each([
    ["/friends/", "settings-friends"],
    ["/friends/incoming/", "settings-friends-incoming"],
    ["/friends/outgoing/", "settings-friends-outgoing"],
    ["/friends/ignored/", "settings-friends-ignored"],
  ])("sends %s to %s", async (path, name) => {
    await router.push(path);

    expect(router.currentRoute.value.name).toBe(name);
  });

  // Every list is its own page: a tab is somewhere a reader can be sent and
  // somewhere a reload lands, which is also what lets a notification point at
  // the one list its request is in.
  it.each([
    ["/settings/friends/", "settings-friends"],
    ["/settings/friends/incoming/", "settings-friends-incoming"],
    ["/settings/friends/outgoing/", "settings-friends-outgoing"],
    ["/settings/friends/ignored/", "settings-friends-ignored"],
  ])("opens %s as %s", async (path, name) => {
    await router.push(path);

    expect(router.currentRoute.value.name).toBe(name);
  });

  it("keeps what the link carried", async () => {
    await router.push("/friends/incoming/?page=2");

    expect(router.currentRoute.value.query).toEqual({ page: "2" });
  });

  /*
   * The inventory ledger, the transfer direction and the invite list were paths
   * of their own and are query state now. The server answers the old paths with
   * a 301 -- see `ViewStateRedirectsTest` -- and the client router holds the
   * same mapping, so one of them reaching the app by any other road still opens
   * the view it names rather than the default one.
   */
  it.each([
    ["/hangar/transactions/", "hangar-inventories", { tab: "log" }],
    [
      "/hangar/transfers/outgoing/",
      "hangar-transfers",
      { direction: "outgoing" },
    ],
    [
      "/hangar/inventories/crates/transactions/",
      "hangar-inventory",
      { tab: "log" },
    ],
    [
      "/hangar/my-vehicle/cargo/transactions/",
      "hangar-vehicle-cargo",
      { tab: "log" },
    ],
    [
      "/fleets/black-sun/logistics/transactions/",
      "fleet-logistics",
      { tab: "log" },
    ],
    [
      "/fleets/black-sun/logistics/transfers/outgoing/",
      "fleet-logistics-transfers",
      { direction: "outgoing" },
    ],
    [
      "/fleets/black-sun/logistics/inventories/crates/transactions/",
      "fleet-logistics-inventory",
      { tab: "log" },
    ],
    [
      "/fleets/black-sun/members/invites/",
      "fleet-members-index",
      { view: "invites" },
    ],
  ])(
    "opens %s as %s, with the view in the query",
    async (path, name, query) => {
      await router.push(path);

      expect([
        router.currentRoute.value.name,
        router.currentRoute.value.query,
      ]).toEqual([name, query]);
    },
  );

  it("keeps what an old view link carried", async () => {
    await router.push("/hangar/transactions/?page=2");

    expect(router.currentRoute.value.query).toEqual({ page: "2", tab: "log" });
  });

  /*
   * `/catalogue/` used to name its tenant by hand, so it went on opening
   * components after blueprints had moved to the front of the nav. Both the
   * entry and the tenants' own paths are built from `CATALOGUE_TENANTS` now,
   * which is what these two assert together: the entry follows the list, and
   * the list is what the section is made of.
   */
  it("lands on the first tenant of the section", async () => {
    await router.push("/catalogue/");

    expect(router.currentRoute.value.name).toBe(CATALOGUE_TENANTS[0].listRoute);
  });

  it("puts blueprints first today", async () => {
    await router.push("/catalogue/");

    expect(router.currentRoute.value.path).toBe("/catalogue/blueprints/");
  });

  /*
   * The detail page became a shell with children so the history tab could be a
   * sibling of the overview rather than a second page fetching the same
   * component. The slug path has to go on opening the overview, because every
   * hardpoint on every ship links straight to it.
   */
  it.each([
    ["/catalogue/components/bulldog-repeater/", "component"],
    ["/catalogue/components/bulldog-repeater/history/", "component-history"],
  ])("opens %s as %s", async (path, name) => {
    await router.push(path);

    expect(router.currentRoute.value.name).toBe(name);
  });

  /*
   * The nav lights a tenant from the routes it claims, and a detail page is a
   * sibling of its list rather than a child -- so every page of a tenant has to
   * be named, or the catalogue menu goes dark on it. The history tab was the
   * one that got missed.
   */
  it.each(
    CATALOGUE_TENANTS.flatMap((tenant) =>
      [tenant.listRoute, ...tenant.detailRoutes].map((name) => [
        tenant.key,
        name,
      ]),
    ),
  )("counts %s route %s as its own", (key, name) => {
    const tenant = CATALOGUE_TENANTS.find((entry) => entry.key === key);

    expect(isTenantActive(tenant!, name)).toBe(true);
  });

  it("claims every route the router draws under a tenant", () => {
    const claimed = CATALOGUE_TENANTS.flatMap((tenant) => [
      tenant.listRoute,
      ...tenant.detailRoutes,
    ]);

    const drawn = CATALOGUE_TENANTS.flatMap((tenant) =>
      tenant.children.flatMap((child) =>
        [child.name, ...(child.children ?? []).map((nested) => nested.name)]
          .filter(Boolean)
          .map(String),
      ),
    );

    expect([...drawn].sort()).toEqual([...claimed].sort());
  });

  it.each(CATALOGUE_TENANTS.map((tenant) => [tenant.key, tenant.listRoute]))(
    "gives %s a list at its own path",
    async (key, listRoute) => {
      await router.push(`/catalogue/${key}/`);

      expect(router.currentRoute.value.name).toBe(listRoute);
    },
  );
});
