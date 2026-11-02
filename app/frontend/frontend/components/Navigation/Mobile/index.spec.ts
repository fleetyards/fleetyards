import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import type { VueWrapper } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const kraken = {
  slug: "kraken",
  name: "Kraken Haulers",
  logo: null,
  myFleet: true,
  publicFleet: false,
};

vi.mock("@/services/fyApi", async () => ({
  ...(await vi.importActual<Record<string, unknown>>("@/services/fyApi")),
  useFleet: (slug: { value: string }) => ({
    data: computed(() => (slug.value === "kraken" ? kraken : undefined)),
  }),
  usePublicFleet: () => ({ data: computed(() => undefined) }),
  useMyFleets: () => ({
    data: computed(() => [kraken]),
    isPending: computed(() => false),
  }),
  useNotificationsUnreadCount: () => ({ data: computed(() => ({ count: 0 })) }),
  useFleetInvites: () => ({ data: computed(() => [{ id: "invite-1" }]) }),
}));

vi.mock("@/frontend/composables/useFleetNavAccess", () => ({
  useFleetNavAccess: () => ({
    showMembersNav: computed(() => true),
    showSettingsNav: computed(() => true),
    showStatsNav: computed(() => true),
    showShipsNav: computed(() => true),
    shipsNavActive: computed(() => false),
    showSquadronsNav: computed(() => false),
    squadronsNavActive: computed(() => false),
    showBlueprintsNav: computed(() => false),
    blueprintsNavActive: computed(() => false),
    showLogisticsNav: computed(() => false),
    logisticsNavActive: computed(() => false),
    showShoppingListsNav: computed(() => false),
    shoppingListsNavActive: computed(() => false),
    showContractsNav: computed(() => true),
    contractsNavActive: computed(() => false),
    showEventsNav: computed(() => false),
    eventsNavRoute: computed(() => "fleet-events"),
    eventsNavActive: computed(() => false),
  }),
}));

import MobileNavigation from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const Stub = { render: () => null };

const mountTabs = async (
  path: string,
  fleetSlug: string | null,
  authenticated = true,
) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/ships", name: "ships", component: Stub },
      { path: "/hangar", name: "hangar", component: Stub },
      { path: "/hangar/preview", name: "hangar-preview", component: Stub },
      { path: "/notifications", name: "notifications", component: Stub },
      { path: "/settings/profile", name: "settings-profile", component: Stub },
      { path: "/fleets/:slug", name: "fleet", component: Stub },
      { path: "/fleets/:slug/ships", name: "fleet-ships", component: Stub },
      {
        path: "/fleets/:slug/members",
        name: "fleet-members",
        component: Stub,
      },
      {
        path: "/fleets/:slug/contracts",
        name: "fleet-contracts",
        component: Stub,
      },
      { path: "/fleets/:slug/stats", name: "fleet-stats", component: Stub },
      {
        path: "/fleets/:slug/settings",
        name: "fleet-settings",
        component: Stub,
      },
      { path: "/fleets/directory", name: "fleet-directory", component: Stub },
      { path: "/fleets/invites", name: "fleet-invites", component: Stub },
      { path: "/fleets/add", name: "fleet-add", component: Stub },
    ],
  });

  await router.push(path);

  wrapper = await mountWithDefaults(MobileNavigation, {
    plugins: [router],
    initialState: {
      session: authenticated
        ? {
            authenticated: true,
            currentUser: { id: "user-1", username: "torlek" },
          }
        : { authenticated: false },
      navContext: { fleetSlug },
    },
  });

  return wrapper;
};

const hubTrigger = (tabs: VueWrapper) =>
  tabs.find('[data-test="fleet-hub-trigger"]');

const hub = (tabs: VueWrapper) => tabs.find('[data-test="fleet-hub"]');

describe("Mobile navigation", () => {
  // The sidebar keeps the fleet on an account page, and the tabs have to agree.
  it("keeps the fleet's tabs on an account page opened from it", async () => {
    const tabs = await mountTabs("/settings/profile", "kraken");

    expect(hubTrigger(tabs).exists()).toBe(true);
  });

  it("shows the personal tabs anywhere else", async () => {
    const tabs = await mountTabs("/ships", "kraken");

    expect(hubTrigger(tabs).exists()).toBe(false);
  });

  // A fleet is reached through the switcher in the drawer, not a tab that
  // picks one of the reader's fleets for them.
  it("does not put a fleet on the personal tabs", async () => {
    const tabs = await mountTabs("/ships", null);

    const fleetLinks = tabs
      .findAllComponents({ name: "NavItem" })
      .filter(
        (item) => (item.props("to") as { name?: string })?.name === "fleet",
      );

    expect(fleetLinks).toHaveLength(0);
  });

  describe("the fleet hub", () => {
    it("lists every section the reader may open, the open page marked", async () => {
      const tabs = await mountTabs("/fleets/kraken", "kraken");

      await hubTrigger(tabs).trigger("click");

      for (const key of ["overview", "ships", "members", "contracts"]) {
        expect(tabs.find(`[data-test="fleet-hub-${key}"]`).exists()).toBe(true);
      }
      expect(tabs.find('[data-test="fleet-hub-events"]').exists()).toBe(false);
      expect(
        tabs.get('[data-test="fleet-hub-overview"]').attributes("aria-current"),
      ).toBe("page");
    });

    it("swaps the sections for the switcher and back", async () => {
      const tabs = await mountTabs("/fleets/kraken", "kraken");

      await hubTrigger(tabs).trigger("click");
      await tabs.get('[data-test="fleet-hub-switch"]').trigger("click");

      expect(tabs.find('[data-test="fleet-hub-switcher"]').exists()).toBe(true);
      expect(tabs.find('[data-test="fleet-hub-overview"]').exists()).toBe(
        false,
      );

      await tabs.get('[data-test="fleet-hub-switch"]').trigger("click");

      expect(tabs.find('[data-test="fleet-hub-overview"]').exists()).toBe(true);
    });

    it("closes once the reader goes somewhere", async () => {
      const tabs = await mountTabs("/fleets/kraken", "kraken");

      await hubTrigger(tabs).trigger("click");
      expect(hub(tabs).exists()).toBe(true);

      await tabs.get('[data-test="fleet-hub-members"]').trigger("click");
      await flushPromises();

      expect(hub(tabs).exists()).toBe(false);
    });

    it("closes on a tap at the page that is already open", async () => {
      const tabs = await mountTabs("/fleets/kraken", "kraken");

      await hubTrigger(tabs).trigger("click");
      await tabs.get('[data-test="fleet-hub-overview"]').trigger("click");
      await flushPromises();

      expect(hub(tabs).exists()).toBe(false);
    });

    it("lists the reader's invitations in the switcher", async () => {
      const tabs = await mountTabs("/fleets/kraken", "kraken");

      await hubTrigger(tabs).trigger("click");
      await tabs.get('[data-test="fleet-hub-switch"]').trigger("click");

      expect(tabs.get('[data-test="fleet-hub-invites"]').text()).toContain("1");
    });

    // A guest has no hangar or fleets of their own to switch to.
    it("offers a guest no switcher", async () => {
      const tabs = await mountTabs("/fleets/kraken", "kraken", false);

      await hubTrigger(tabs).trigger("click");

      expect(hub(tabs).exists()).toBe(true);
      expect(tabs.find('[data-test="fleet-hub-switch"]').exists()).toBe(false);
    });

    // The fleet tour skips a step whose target is missing.
    it("keeps the tour's target for a section that is switched on", async () => {
      const tabs = await mountTabs("/fleets/kraken", "kraken");

      expect(tabs.find('[data-tour="fleet-contracts"]').exists()).toBe(true);
      expect(tabs.find('[data-tour="fleet-events"]').exists()).toBe(false);
    });
  });
});
